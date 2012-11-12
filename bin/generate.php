#!/usr/bin/env php
<?php

$config_file_path = "bin/config.ini";

if(!file_exists($config_file_path))
  copy($config_file_path.'.dist', $config_file_path) or die("Error creating config file.");

$config = array();
$config = parse_ini_file($config_file_path) or die("Error loading config file.");

if(console_has_option("-a"))
  $do_apache_config = true;

if(console_has_option("-d"))
  $do_database_config = true;

echoln("Starting script!!");

if(!config_get_option("project_name"))
  $config['misc']['project_name'] = read_from_keyboard("\nProject name: ");

if(!config_get_option("base_path"))
  $config['misc']['base_path'] = read_from_keyboard("\n\nBase path [\"..\"]: ");

$base_path = $config['misc']['base_path'];
mkdir("$base_path/$project_name") or die("Can't create project directory.");
chdir("$base_path/$project_name") or die("Can't change to new dir.");

$project_dir_unescaped = dirname("$base_path/$project_name");
$project_dir = str_replace("/", "\/", $project_dir_unescaped);
$res = null;

# init sf project as git project
system("git init", $res);
if($res)
  die("\nCannot 'git init' here for some reason.");

echoln("a\n\nAdding libraries");
mkdir("lib/vendor", null, true) or die("Cannot create project lib/vendor directory.");

system("git submodule add $symfony_url lib/vendor/symfony", $res);
if($res)
  die("Cannot add symfony as git submodule.");

cecho $ansi_blue "** creating project $project_name..."

php lib/vendor/symfony/data/bin/symfony generate:project --orm=propel $project_name
./symfony generate:app frontend --csrf-secret=whisky_tango_foxtrot
touch cache/.gitkeep
touch log/.gitkeep

# add latest Propel 1.x plugin as submodule
cecho $ansi_blue "Adding Propel"
git submodule add $sfPropelORMPlugin_url plugins/sfPropelORMPlugin

# set HTTPS as default protocol to avoid firewall issues
git config --global url."https://".insteadOf git://

# add mpProjectPlugin
cecho $ansi_blue "Adding mpProjectPlugin"
git submodule add ${mpProjectPlugin_url} plugins/mpProjectPlugin

cecho $ansi_blue "Updating all submodules..."
git submodule update --init --recursive

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

# add useful scripts to bin/ directory
cp -r plugins/mpProjectPlugin/bin .

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
  ./symfony cc

fi

git add .
git commit -m "Very first commit of this project"
./symfony cc

cecho $ansi_blue "All tasks completed!"

if [ -n "$apache_deploy" ]
then
  title "You can now test your project at http://localhost/$project_name/frontend_dev.php right away!"
fi





/* start of functions */
function console_has_option($opcion) {
  return array_search($opcion, $argv);
}

function config_get_option($option) {
  global $config;
  
  if(array_key_exists($option, $config))
    return $config[$option];
  else
    return null;
}

function read_from_keyboard($msg) {
  echo $msg;
  $var = fgets(STDIN);
  
  return $var;
}

function echoln($msg) {
  echo $msg."\n";
}