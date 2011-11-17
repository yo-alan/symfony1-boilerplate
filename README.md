# symfony1-boilerplate #

*One-run script for symfony 1.x + sfPropelORMPlugin project generation!*

**As of now, you will need:**

- bash (for now, all I have is a Bash script)
- a working git installation (needed to create the project and submodules)
- for the -a option, an ubuntu/debian-like Apache installation (`/etc/apache2/conf.d`)...

## Instructions:

- Clone this repo or download this package
- make a copy of `bash/data.txt.dist` named `data.txt` on the same directory
- modify `data.txt` to fit your needs

then cd to the `bash/` folder, and run the script with:

```bash
./sf_git_project.sh
```

This will perform these tasks (at a glance):

- create a project folder
- init a git repo for the new project
- create a `lib/vendor` folder
- download [symfony](https://github.com/symfony/symfony1) as a submodule
- generate a project and a frontend app
- download, configure and enable [sfPropelORMPlugin](https://github.com/propelorm/sfPropelORMPlugin) as a submodule.
  It also downloads phing and propel. There's no need to follow the plugin's README, this script performs all the required steps.
- download and enable [mpProjectPlugin] (https://github.com/mppfiles/mpProjectPlugin) as a submodule
- perform a lot of little tweaks to the project (most of them from symfony-check.org) using the mpProjectPlugin file templates
- perform `plugin:publish-assets`

## But wait! there's more!

If you feel **really lazy**, and want a **fully automated installation** instead of the default one, just adjust the variables on your data.txt file, and run:

```bash
./sf_git_project.sh -ad
```

This will perform these extra steps:

(from -d switch):

- ask you (or read from `data.txt`) the database connection settings
- perform `propel:build-schema` and `propel:build --all-classes`

(from -a switch):

- generate a sample apache configuration file (included in **mpProjectPlugin**)
- symlink this file into `/etc/apache2/conf.d`
- restart apache, and you can browse **http://localhost/your_project** right away!

Conclusion: start with **nothing**, end with a **FULLY configured AND RUNNING project**!

## TODO

- Create a .bat file to be used in Windows
- Give more alternatives to apache deployments
- Move most of operations to a symfony Task on mpProjectPlugin

## Disclaimer/Caveats:

- This script (and mpProjectPlugin) assumes 'spanish' culture by default.
- This method fits perfectly for a rather specific workflow (mine) may not fit your needs.

Forks are welcome!