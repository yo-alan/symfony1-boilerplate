# symfony1-boilerplate #

*One-run script for symfony 1.x + sfPropelORMPlugin project generation!*

**As of now, you will need:**

- A bash shell, or PHP cli.
- a working git installation (needed to create the project and submodules)
- for the -a option, an ubuntu/debian-like Apache installation (`/etc/apache2/conf.d`)...

## Instructions:

- Clone this repo or download this package
- if you need to, make a copy of the config file (`bash/config.txt.dist => config.txt` or `php/config.ini.dist => config.ini`), and modify it to fit your needs.

then just run:

```bash
# for bash version (linux, recommended)
bash/generate
```

or
```bash
# for php version (windows)
php/generate
```

This will perform these tasks (at a glance):

- create a project folder
- init a git repo for the new project
- create a `lib/vendor` folder
- download [symfony](https://github.com/symfony/symfony1) as a submodule
- generate a project and a frontend app
- download, configure and enable [sfPropelORMPlugin](https://github.com/propelorm/sfPropelORMPlugin) as a submodule.
  It also downloads phing and propel. There's no need to follow the plugin's README, this script performs all the required steps.
- download and enable [mpProjectPlugin] (https://github.com/mppfiles/mpProjectPlugin) as a submodule.
- perform a lot of little tweaks to the project (most of them from symfony-check.org) using the mpProjectPlugin file templates.
- perform `plugin:publish-assets`

## But wait! there's more!

If you feel **really lazy**, and want a **fully automated installation** instead of the default one, just add the -a switch:

```bash
bash/generate -a
```

or
```bash
php/generate -a
```

This will perform these extra steps:

- generate a sample apache configuration file (included in **mpProjectPlugin**)
- symlink this file into `/etc/apache2/conf.d` (sorry, only Ubuntu/Debian support for now)
- restart apache, and you can browse **http://localhost/your_project** right away!

Conclusion: start with **nothing**, end with a **FULLY configured AND RUNNING project**!

## TODO

- Give more alternatives to apache deployments
- Move most of operations to a symfony Task on mpProjectPlugin

## Disclaimer/Caveats:

- This method fits perfectly for a rather specific workflow (mine) thus it may not fit your needs.

Forks and PRs are welcome!