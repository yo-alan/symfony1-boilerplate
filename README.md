# symfony1-boilerplate #

*One-run script for symfony 1.x + sfPropelORMPlugin project generation!*

## Instructions:

- Clone this repo/download this package
- make a copy of `bash/data.txt.dist` named `data.txt`
- modify `data.txt` to fit your needs

then cd to the `bash/` folder, and run the script with:

```bash
./sf_git_project.sh
```

This will perform these tasks (at a glance):
* create a project folder
* init a git repo for the new project
* create a `lib/vendor` folder
* download **symfony** from **github**
* generate a project and a frontend app
* download, configure and enable **sfPropelORMPlugin** from **github** (no need to follow the plugin's README) including their submodules (phing and propel)
* download and enable [mpProjectPlugin] (https://github.com/mppfiles/mpProjectPlugin.git)
* perform a lot of little tweaks to the project (most of them from symfony-check.org)
* perform `plugin:publish-assets`

## But wait! there's more!

If you feel **really lazy**, and want a **fully automated installation** instead of the default one, just adjust the variables on your data.txt file, and run:

```bash
./sf_git_project.sh -ad
```

This will perform these extra steps:

(from -d switch):
* ask you (or read from `data.txt`) the database connection settings
* perform `propel:build-schema` and `propel:build --all-classes`

(from -a switch):
* generate a sample apache configuration file (included in **mpProjectPlugin**)
* symlink this file into `/etc/apache2/conf.d`
* restart apache, and you can browse **http://localhost/your_project** right away!

Conclusion: start with **nothing**, end with a **FULLY configured AND RUNNING project**!
