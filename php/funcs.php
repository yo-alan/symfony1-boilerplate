<?php

/* start of functions */

function console_has_option($opcion) {
  if (!isset($argv))
    return false;
  return array_search($opcion, $argv);
}

function config_get_option($option) {
  global $config;

  if (array_key_exists($option, $config))
    return $config[$option];
  else
    return null;
}

function read_from_keyboard($msg) {
  echo $msg;
  $var = fgets(STDIN);

  return trim($var);
}

function echoln($msg) {
  echo $msg . "\n";
}

function system_call($command) {
  system($command, $res);
  if ($res)
    die("\nCannot perform command '$command' for some reason. Aborting.\n\n");
}

function copy_or_die($from, $to) {
  copy($from, $to) or die(sprintf("Can't copy '%s' to '%s' for some reason. Aborting.\n\n", $from, $to));
}

function mkdir_or_die($dir) {
  mkdir($dir, 0775, true) or die(sprintf("Can't create directory '%s' for some reason. Aborting.\n\n", $dir));
}

function replace_in_file($search, $replace, $file) {
  $content = file_get_contents($file);

  if (!$content)
    die("Cannot read file '" . $file . "' for processing. Aborting.\n\n");

  $content = str_replace($search, $replace, $content);

  $bytes = file_put_contents($file, $content);

  if (false === $bytes)
    die("Cannot write to file '" . $file . "'. Aborting.\n\n");
}

/**
* Copy a file, or recursively copy a folder and its contents
*
* @author Aidan Lister <aidan@php.net>
* @version 1.0.1
* @link http://aidanlister.com/2004/04/recursively-copying-directories-in-php/
* @param string $source Source path
* @param string $dest Destination path
* @return bool Returns TRUE on success, FALSE on failure
*/
function copyr($source, $dest) {
  
  // Check for symlinks
  if (is_link($source)) {
    return symlink(readlink($source), $dest);
  }
  
  // Simple copy for a file
  if (is_file($source)) {
    return copy_or_die($source, $dest);
  }

  // Make destination directory
  if (!is_dir($dest)) {
    mkdir_or_die($dest);
  }

  // Loop through the folder
  $dir = dir($source);
  while (false !== $entry = $dir->read()) {
    // Skip pointers
    if ($entry == '.' || $entry == '..') {
      continue;
    }

    // Deep copy directories
    copyr("$source/$entry", "$dest/$entry");
  }

  // Clean up
  $dir->close();
  return true;
}