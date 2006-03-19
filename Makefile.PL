use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Template::Plugin::Gravatar',
    AUTHOR              => 'Ashley Pond V <ashley@cpan.org>',
    VERSION_FROM        => 'lib/Template/Plugin/Gravatar.pm',
    ABSTRACT_FROM       => 'lib/Template/Plugin/Gravatar.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        "Test::More" => 0,
        "Carp" => 0,
        "Digest::MD5" => 0,
        "URI::Escape" => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Template-Plugin-Gravatar-*' },
);
