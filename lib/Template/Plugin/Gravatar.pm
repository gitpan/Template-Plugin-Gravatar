package Template::Plugin::Gravatar;

our $VERSION = '0.03';

use strict;
use Carp;
use Digest::MD5 ();
use URI::Escape ();

use base "Template::Plugin";

my $Gravatar_Base = "http://www.gravatar.com/avatar.php";


sub new {
    my ( $class, $context, $instance_args ) = @_;
    $instance_args ||= {}; # the USE'd object
    my $config = $context->{CONFIG}{GRAVATAR} || {}; # from tt config
    my %args;

    $args{default} = $instance_args->{default} || $config->{default};
    $args{size} = $instance_args->{size} || $config->{size};
    $args{rating} = $instance_args->{rating} || $config->{rating};
    $args{border} = $instance_args->{border} || $config->{border};

    # overriding the base might be nice for some developers
    $args{base} = $instance_args->{base} || $config->{base} ||
        $Gravatar_Base;

    return sub {
        my $args = shift || {};
        $args = {
            %args,
            %{$args}
        };
        $args->{email} || croak "Cannot generate a Gravatar URI without an email address";
        if ( $args->{size} ) {
            $args->{size} >= 1 and $args->{size} <= 80
                or croak "Gravatar size must be 1 .. 80";
        }
        if ( $args->{rating} ) {
            $args->{rating} =~ /\A(?:G|PG|R|X)\Z/
                or croak "Gravatar rating can only be G, PG, R, or X";
        }
        if ( $args->{border} ) {
            $args->{border} =~ /\A[0-9A-F]{3}(?:[0-9A-F]{3})?\Z/
                or croak "Border must be a 3 or 6 digit hex number in caps";
        }
        
        $args->{gravatar_id} = Digest::MD5::md5_hex( $args->{email} );

        $args->{default} = URI::Escape::uri_escape($args->{default})
            if $args->{default};

        my @pairs;
        for my $key ( qw( gravatar_id rating size default border ) ) {
            next unless $args->{$key};
            push @pairs, join("=", $key, $args->{$key});
        }

        my $uri = join("?",
                       $args->{base},
                       join("&",
                            @pairs
                            )
                       );

        return $uri;
    }
}

1;

__END__

=head1 NAME

Template::Plugin::Gravatar - configurable generation of Gravatar URLs from email addresses.

=head1 VERSION

0.03

=head1 SYNOPSIS

  [% USE Gravatar %]
  [% FOR user IN user_list %]
   <img src="[% Gravatar( email => user.email ) | html %]"
     alt="[% user.name | html %]" />
  [% END %]

  # OR a mini CGI example
  use strict;
  use CGI qw( header start_html end_html );
  use Template;

  my %config = ( # ... your other config stuff
                GRAVATAR => { default => "/local/image.png",
                              size => 80,
                              rating => "R" },
                );

  my $tt2 = Template->new(\%config);

  my $user = { email => 'whatever@wherever.whichever',
               rating => "PG",
               name => "Manamana",
               size => 75 };

  print header(), start_html();

  $tt2->process(\*DATA, { user => $user })
      or warn $Template::ERROR;

  print end_html();

  __DATA__
  [% USE Gravatar %] 
  [% FILTER html %]
   <img src="[% Gravatar( user ) | html %]"
     alt="[% user.name | html %]" />
  [% END %]

=head1 DESCRIPTION

Please see http://www.gravatar.com/implement.php for more on the
service interface and http://www.gravatar.com/ for information about
Gravatars (globally recognized avatars) in general.

All of the options supported in Gravatars--default, rating, size, and
border--can be used here. The gravatar_id is generated from a given
email.

=head1 INTERFACE/SETTINGS

=head2 new

Not called directly. Called when you C<USE> the plugin. Takes defaults
from the template config hash and mixes them with any per template
defaults. E.g.,

  [% USE Gravatar %]
  Use config arguments if any.

  [% USE Gravatar(default => '/local/default-image.png') %]
  Mix config arguments, if any, with new instance arguments.

=head2 Arguments

=over 4

=item email (required)

The key to using Gravatars is a hex hash of the user's email. This is
generated automatically and sent to gravatar.com as the C<gravatar_id>.

=item default (optional)

The local (any valid image URI) image to use if there is no Gravatar
corresponding to the given email.

=item size (optional)

Gravatars are square. Size is 1 through 80 (pixels) and sets the width
and the height.

=item rating (optional)

G|PG|R|X. The B<maximum> rating of Gravatar you wish returned. If you
have a family friendly forum, for example, you might set it to "G."

=item border (optional)

A hex color, e.g. FF00FF or F0F.

=item base (developer override)

This is allowed as a courtesy for the one or two developers who might
need it. More below.

=item gravatar_id (not allowed)

This is B<not> an option but a generated variable. It is an MD5 hex
hash of the email address. The reason is it not supported as an
optional variable is it would allow avatar hijacking.

=back

The only argument that must be given when you call the C<Gravatar>
plugin is the email. Everything else -- rating, default image, border,
and size -- can be set in three different places: the config, the
C<USE> call, or the C<Gravatar> call. All three of the following
produce the same Gravatar URL.

=head2 Settings via config

Used if the entire "site" should rely on one set of defaults.

  use Template;
  my %config = (
     GRAVATAR => {
         default => "/avatar.png",
         rating => "PG",
         size => 80,
     }
  );

  my $template = <<;
  [% USE Gravatar %]
  [% Gravatar(email => 'me@myself.ego') | html %]
  
  my $tt2 = Template->new(\%config);
  $tt2->process(\$template);

=head2 Settings via instance

Used if a particular template needs its own defaults.

  use Template;
  my $template = <<;
  [% USE Gravatar( default => "/avatar.png",
                   rating => "PG",
                   size => 80 ) %]
  [% Gravatar(email => 'me@myself.ego') | html %]
  
  my $tt2 = Template->new();
  $tt2->process(\$template);

Any other calls with different emails will share the defaults in this
template.

=head2 Settings in the Gravatar call

Used for per URL control.

  use Template;
  my $template = <<;
  [% USE Gravatar %]
  [% Gravatar(email => 'me@myself.ego',
              default => "/avatar.png",
              rating => "PG",
              size => 80 ) | html %]
  
  my $tt2 = Template->new();
  $tt2->process(\$template);

=head2 Base URL (for developers only)

You may also override the base URL for retrieving the Gravatars. It's
set to use the service from www.gravatar.com. It can be overridden in
the config or the C<USE>.

=head1 DIAGNOSTICS

Email is the only required argument. Croaks without it.

Size, border, and rating are also validated on each call. Croaks if an
invalid size (like 0 or 100) or rating (like MA or NC-17) or border
(like ff0 or FF) is given.

=head1 CONFIGURATION AND ENVIRONMENT

No configuration is necessary. You may use the configuration hash of
your new template to pass default information like the default image
location for those without Gravatars. You can also set it in the C<USE>
call per template if needed.

=head1 DEPENDENCIES (SEE ALSO)

L<Template>, L<Template::Plugin>, L<Carp>, L<Digest::MD5>, and
L<URI::Escape>.

http://www.gravatar.com/

=head1 BUGS AND LIMITATIONS

None known. I certainly appreciate bug reports and feedback via
C<bug-template-plugin-gravatar@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/>.

=head1 AUTHOR

Ashley Pond V  C<< <ashley@cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2006, Ashley Pond V C<< <ashley@cpan.org> >>. All rights reserved.

This module is free software; you may redistribute it or modify it or
both under the same terms as Perl itself. See L<perlartistic>.

=cut
