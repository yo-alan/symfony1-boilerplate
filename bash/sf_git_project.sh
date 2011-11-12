#!/bin/bash

. colors.txt
. data.txt

function title {
  cecho ${ansi_yellow} "============================================================"
  cecho ${ansi_yellow} $1
  cecho ${ansi_yellow} "============================================================"
}

getopts "h" show_help

if [ "$show_help" == "h" ]
then
  cat <<EOF
  
  Usage: ./sf_git_project.sh [-h] | [-p] [-a] [-d] [-m]

  -h  show this help screen
  -p  project name
  -a  perform an apache deployment of your app, doing a symlink on /etc/apache2/conf.d
  -d  configure database access (in order to build schema and model classes) (see data.txt)
  -m  download "extra" mpPlugins (see data.txt)
  
EOF
  exit
fi

project_dir_unescaped=`pwd`
project_dir=${project_dir_unescaped//'/'/"\/"}

# starting...
clear

# ...debug zone...beware! :P
#echo $project_name
#echo $project_dir
#exit

title "Starting script!!"

if [ -z "$project_name" ]
then
  echo -n "Project name: "
  read project_name
else
  echo "ehh '$project_name'"
fi

mkdir ../../${project_name}
cd ../../${project_name}

# init sf project as git project
git init

title "Adding libraries"
mkdir -p lib/vendor

cecho $ansi_blue "* symfony 1.4: "
git submodule add $symfony_url lib/vendor/symfony

cecho $ansi_blue "** creating project $project_name..."

php lib/vendor/symfony/data/bin/symfony generate:project --orm=propel $project_name
./symfony generate:app frontend --csrf-secret=whisky_tango_foxtrot
touch config/schema.custom.yml
touch cache/BUMP
touch log/BUMP

# add latest Propel 1.x plugin as submodule
cecho $ansi_blue "Adding Propel"
git submodule add $propel_plugin_url plugins/sfPropelORMPlugin
# oops... there is no git submodule init --recursive without update!
cd plugins/sfPropelORMPlugin
git submodule init
cd ../..

# add mpProjectPlugin
cecho $ansi_blue "Adding  mpProjectPlugin"
git submodule add ${mpPlugins_url_prefix}/mpProjectPlugin${mpPlugins_url_suffix} plugins/mpProjectPlugin

getopts "m" install_extra_plugins

if [ "$install_extra_plugins" == "m" ]
then
  # add my plugins on github
  cecho $ansi_blue "Adding mpPlugins..."
  
  for plugin in ${mpExtraPlugins[@]}
  do
    git submodule add ${mpPlugins_url_prefix}/${plugin}${mpPlugins_url_suffix} plugins/${plugin}
  done
fi

cecho $ansi_blue "Publishing plugin assets..."
./symfony plugin:publish-assets

cecho $ansi_blue "Updating git submodules..."
git submodule init

# Replace git:// with https:// to avoid firewall issues
sed -i "s/git\:\/\//https\:\/\//g" plugins/sfPropelORMPlugin/.git/config

# lastly, updates all 2nd-level submodules (4ex. Propel ones)
git submodule update --recursive

cecho $ansi_blue "More filesystem tweaks from mpProjectPlugin..."
cp plugins/mpProjectPlugin/config/gitignore_example.dist .gitignore
cp config/databases.yml config/databases.yml.dist
cp -r plugins/mpProjectPlugin/config/error config/
cp -r plugins/mpProjectPlugin/apps/foo/i18n apps/frontend/i18n
cp plugins/mpProjectPlugin/config/unavailable.php config/unavailable.php
sed -i "s/sfFormSymfony/mpForm/g" lib/form/BaseForm.class.php
sed -i "s/sfPropelPlugin/sfPropelORMPlugin/g" config/propel.ini
sed -i "s/propel.addTimeStamp        = true/propel.addTimeStamp        = false/g" config/propel.ini
sed -i "s/sfPropelPlugin/sfPropelORMPlugin/g" config/ProjectConfiguration.class.php

# project url: localhost/project_name => need to fix this file
sed -i "s/#RewriteBase \//RewriteBase \/$project_name/g" web/.htaccess

# apache config
cp plugins/mpProjectPlugin/config/apache_example.conf.dist plugins/mpProjectPlugin/config/apache_example.conf
sed -i "s/PROJECT_NAME/$project_name/g" plugins/mpProjectPlugin/config/apache_example.conf
sed -i "s/PROJECT_DIR/$project_dir/g" plugins/mpProjectPlugin/config/apache_example.conf

# publish this project in apache
getopts "a" apache_deploy

if [ "$apache_deploy" == "a" ]
then
  echo -e "\E[31m"
  cecho $ansi_blue "In order to publish your project in Apache, I may ask you for sudo password..."
  
  sudo ln -s ${project_dir_unescaped}/plugins/mpProjectPlugin/config/apache_example.conf /etc/apache2/conf.d/${project_name}
  sudo service apache2 graceful
fi

# configure database and build model classes
getopts "d" database_config

if [ "$database_config" == "d" ]
then
  cecho $ansi_blue "Configuring DB access"
  ./symfony configure:database "mysql:host=${db_host};dbname=${db_name}" ${db_user} ${db_pass}
  ./symfony propel:build-schema
  ./symfony propel:build --all-classes
  #sed -i "s/sfFormPropel/mpFormPropel/g" lib/form/BaseFormPropel.class.php
fi

git add .
git commit -m "Very first commit of this project"
./symfony cc

cecho $ansi_blue "All tasks completed!"

if [ "$apache_deploy" == "a" ]
then
  title "You can now test your project at http://localhost/$project_name/frontend_dev.php"
fi
