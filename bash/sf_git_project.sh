#!/bin/bash

. colors.txt
. data.txt

function title {
  cecho ${ansi_yellow} "============================================================"
  cecho ${ansi_yellow} $1
  cecho ${ansi_yellow} "============================================================"
}

while getopts "had" opt; do
  case $opt in
    h)
      show_help=1
      ;;
    a)
      apache_deploy=1
      ;;
    d)
      database_config=1
      ;;
  esac
done

if [ -n "$show_help" ]
then
  cat <<EOF
  
  Usage: ./sf_git_project.sh [-h] | [-a] [-d]

  -h  show this help screen
  -a  perform an apache deployment of your app, doing a symlink on /etc/apache2/conf.d
  -d  configure database access (in order to build schema and model classes) (see data.txt)
  
EOF
  exit
fi

# starting...
clear

title "Starting script!!"

if [ -z "$project_name" ]
then
  echo -n "Project name: "
  read project_name
fi

mkdir ../../${project_name}
cd ../../${project_name}
project_dir_unescaped=`pwd`
project_dir=${project_dir_unescaped//'/'/"\/"}

# init sf project as git project
git init

title "Adding libraries"
mkdir -p lib/vendor

cecho $ansi_blue "* symfony 1.4: "
git submodule add $symfony_url lib/vendor/symfony

cecho $ansi_blue "** creating project $project_name..."

php lib/vendor/symfony/data/bin/symfony generate:project --orm=propel $project_name
./symfony generate:app frontend --csrf-secret=whisky_tango_foxtrot
touch cache/BUMP
touch log/BUMP

# add latest Propel 1.x plugin as submodule
cecho $ansi_blue "Adding Propel"
git submodule add $sfPropelORMPlugin_url plugins/sfPropelORMPlugin
# oops... there is no git submodule init --recursive without update!

cd plugins/sfPropelORMPlugin

# Replace git:// with the right URL to enable local usage or to avoid firewall issues
git config submodule.lib/vendor/propel.url ${propel_url} lib/vendor/propel
git config submodule.lib/vendor/phing.url ${phing_url} lib/vendor/phing
cd ../..

# add mpProjectPlugin
cecho $ansi_blue "Adding  mpProjectPlugin"
git submodule add ${mpProjectPlugin_url} plugins/mpProjectPlugin

cecho $ansi_blue "Updating git submodules..."
git submodule init

#sed -i "s/git\:\/\//https\:\/\//g" plugins/sfPropelORMPlugin/.git/config

# lastly, updates all 2nd-level submodules (4ex. Propel ones)
git submodule update --recursive

cecho $ansi_blue "More filesystem tweaks from mpProjectPlugin..."
cp plugins/mpProjectPlugin/config/gitignore_example.dist .gitignore
cp plugins/mpProjectPlugin/config/databases.yml.dist config/databases.yml.dist
cp config/databases.yml.dist config/databases.yml
cp plugins/mpProjectPlugin/config/schema.custom.yml config/schema.custom.yml
cp plugins/mpProjectPlugin/apps/foo/config/settings.yml apps/frontend/config/settings.yml
cp plugins/mpProjectPlugin/apps/foo/config/factories.yml apps/frontend/config/factories.yml
cp -r plugins/mpProjectPlugin/config/error config/
cp -r plugins/mpProjectPlugin/apps/foo/i18n apps/frontend/
cp plugins/mpProjectPlugin/apps/foo/templates/* apps/frontend/templates/
cp plugins/mpProjectPlugin/config/unavailable.php config/unavailable.php
cp plugins/mpProjectPlugin/lib/form/BaseFormPropel.class.php lib/form/
mkdir -p lib/filter
cp plugins/mpProjectPlugin/lib/filter/BaseFormFilterPropel.class.php lib/filter/


sed -i "s/PROJECT_NAME/$project_name/g" apps/frontend/config/factories.yml
sed -i "s/sfFormSymfony/mpForm/g" lib/form/BaseForm.class.php
sed -i "s/sfPropelPlugin/sfPropelORMPlugin/g" config/propel.ini
sed -i "s/propel.addTimeStamp        = true/propel.addTimeStamp        = false/g" config/propel.ini
sed -i "s/'sfPropelPlugin'/'sfPropelORMPlugin', 'mpProjectPlugin'/g" config/ProjectConfiguration.class.php

# project url: localhost/project_name => need to fix this file
sed -i "s/#RewriteBase \//RewriteBase \/$project_name/g" web/.htaccess

# ProjectConfiguration.class.php is ready, time to publish assets
cecho $ansi_blue "Publishing plugin assets..."
./symfony plugin:publish-assets

# apache config
cp plugins/mpProjectPlugin/config/apache_example.conf.dist plugins/mpProjectPlugin/config/apache_example.conf
sed -i "s/PROJECT_NAME/$project_name/g" plugins/mpProjectPlugin/config/apache_example.conf
sed -i "s/PROJECT_DIR/$project_dir/g" plugins/mpProjectPlugin/config/apache_example.conf

# publish this project in apache

if [ -n "$apache_deploy" ]
then
  echo -e "\E[31m"
  cecho $ansi_blue "In order to publish your project in Apache, I may ask you for sudo password..."
  
  sudo ln -s ${project_dir_unescaped}/plugins/mpProjectPlugin/config/apache_example.conf /etc/apache2/conf.d/${project_name}
  sudo service apache2 graceful
fi

# configure database and build model classes

if [ -n "$database_config" ]
then
  cecho $ansi_blue "Configuring DB access"
  
  if [ -z "$db_host" ]
  then
    cecho $ansi_red "Database host [localhost]:"
    read db_host
    
    if [ -z "$db_host" ]
    then
      db_host="localhost"
    fi
  fi
  
  if [ -z "$db_name" ]
  then
    cecho $ansi_red "Database name [$project_name]:"
    read db_name
    
    if [ -z "$db_name" ]
    then
      db_name="$project_name"
    fi
  fi
  
  if [ -z "$db_user" ]
  then
    cecho $ansi_red "DB user [$project_name]:"
    read db_user
    
    if [ -z "$db_user" ]
    then
      db_user="$project_name"
    fi
  fi
  
  if [ -z "$db_pass" ]
  then
    cecho $ansi_red "DB pass:"
    read -s db_pass
    
    if [ -z "$db_pass" ]
    then
      db_pass=""
    fi
  fi
  
  ./symfony configure:database "mysql:host=${db_host};dbname=${db_name}" ${db_user} ${db_pass}
  ./symfony propel:build-schema
  ./symfony propel:build --all-classes
  sed -i "s/sfFormPropel/mpFormPropel/g" lib/form/BaseFormPropel.class.php
  sed -i "s/sfFormFilterPropel/mpFormFilterPropel/g" lib/filter/BaseFormFilterPropel.class.php
  sed -i "s/  {/  { parent::setup();/g" lib/form/BaseFormPropel.class.php
  sed -i "s/  {/  { parent::setup();/g" lib/filter/BaseFormFilterPropel.class.php
fi

git add .
git commit -m "Very first commit of this project"
./symfony cc

cecho $ansi_blue "All tasks completed!"

if [ -n "$apache_deploy" ]
then
  title "You can now test your project at http://localhost/$project_name/frontend_dev.php right away!"
fi
