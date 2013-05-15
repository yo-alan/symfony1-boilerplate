# symfony1-boilerplate #

*One-run script for symfony 1.x + sfPropelORMPlugin project generation!*

## Latest version: v4.0.1

## New in version 4.0:
* Using Composer to resolve and download dependencies,
* Generation via php script only (no bash), no more need of config files
* Windows compatibility improved! (see previous),
* There's no more apache setup: Just create/move your project to your Document Root and you're done!. (Note: may not be suitable for production environments).

**As of now, you will need:**

- An environment with a working PHP cli and git.
- [Composer](http://getcomposer.org/) for dependency management.

## Instructions:

* Prepare the boilerplate and download the dependencies:

```
composer create-project mppfiles/symfony1-boilerplate {install_path} dev-master
```

* Then, just get into the new directory and call the boilerplate generation script:

```
cd {install_path}
php bin/generate
```

* Give a project name, and if you wish answer 'Y' when promting for remove the existing VCS history.
* Finally, move the project to your Server Document Root (ex. /var/www/myproject) and point your browser to `http://localhost/myproject/web/frontend_dev.php`

Conclusion: start with **nothing**, end with a **FULLY configured AND RUNNING project**!

## Disclaimer/Caveats:

- This method fits perfectly for a rather specific workflow (mine) thus it may not fit your needs.

Forks and PRs are welcome!