use inc::Module::Install;

name     "Template-Plugin-Gravatar";
all_from "lib/Template/Plugin/Gravatar.pm";

requires "Test::More";
requires "Template" => 2;
requires "Carp";
requires "Digest::MD5" => 2.25;
requires "URI::Escape";

auto_install;

WriteAll;


