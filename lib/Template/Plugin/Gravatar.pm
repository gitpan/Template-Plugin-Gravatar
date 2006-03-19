package Template::Plugin::Gravatar;

our $VERSION = '0.01';

use warnings; no warnings 'uninitialized';
use strict;
use Carp;
use Digest::MD5 ();
use URI::Escape ();

use base "Template::Plugin";

my $Gravatar_Base = 'http://www.gravatar.com/avatar.php';


sub new {
    my ( $class, $context, $instance_args ) = @_;
    $instance_args ||= {};
    $context->{GRAVATAR} ||= {};
    my %args;

    $args{default} = $instance_args->{default} || $context->{GRAVATAR}->{default};
    $args{size} = $instance_args->{size} || $context->{GRAVATAR}->{size};
    $args{rating} = $instance_args->{rating} || $context->{GRAVATAR}->{rating};
    $args{border} = $instance_args->{border} || $context->{GRAVATAR}->{border};

    # overriding the base might be nice for some developers

    $args{base} = $instance_args->{base} ||
        $context->{GRAVATAR}->{base} || $Gravatar_Base;

    return sub {
        my $args = shift || {};
        $args = {
            %args,
            %{$args}
        };
        $args->{email} || croak "Cannot generate a Gravatar URI without an email";
        if ( $args->{size} ) {
            $args->{size} >= 1 and $args->{size} <= 80
                or croak "Gravatar size must be 1 .. 80";
        }
        if ( $args->{rating} ) {
            $args->{rating} =~ /\A(?:G|PG|R|X)\Z/
                or croak "Gravatar rating can only be G, PG, R, or X";
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
                       join("&amp;",
                            @pairs
                            )
                       );

        return $uri;
    }
}

1;

__END__

=head1 NAME

Template::Plugin::Gravatar - (beta software) configurable generation of Gravatar URLs from email addresses.

=head1 VERSION

0.01

=head1 SYNOPSIS

 [% USE Gravatar %]
 [% FOR user IN user_list %]
  <img src="[% Gravatar( email => user.email ) %]"
    alt="[% user.name %]" />
 [% END %]

 # OR a mini CGI example
 use strict;
 use CGI qw( header start_html end_html );
 use Template;

 my %config = ( # ... your other config stuff
               GRAVATAR => { default => '/local/image.png',
                             size => 80,
                             rating => 'R' },
               );

 my $tt2 = Template->new(\%config);

 my $user = { email => 'whatever@wherever.whichever',
              rating => 'PG',
              name => "Manamana",
              size => 75 };

 print header(), start_html();

 $tt2->process(\*DATA, { user => $user })
     or warn $Template::ERROR;

 print end_html();

 __DATA__
 [% USE Gravatar %] 
 [% FILTER html %]
  <img src="[% Gravatar( user ) %]"
    alt="[% user.name %]" />
 [% END %]

=head1 DESCRIPTION

Please see http://www.gravatar.com/implement.php for more on the
service interface and http://www.gravatar.com/ for information about
Gravatars (globally recognized avatars) in general.

All of the options supported in Gravatars--default, rating, size, and
border--can be used here. The gravatar_id is generated from a given
email.

=head1 INTERFACE 

=head2 new

Not called directly. Called when you "USE" the plugin. Takes defaults
from the template config hash and mixes them with any per template
defaults. E.g.,

 [% USE Gravatar %]
 Use config defaults if any.

 [% USE Gravatar(default => '/local/default-image.png') %]
 Mix config defaults, if any, with new ones.

=over 4

=item default (optional)

The local (any valid image URI) image to use if there is no Gravatar
corresponding to the given email.

=item size (optional)

Gravatars are square. Size is 1 through 80 (pixels) and sets the width
and the height. Default if none is set is 40.

=item rating (optional)

G|PG|R|X. The B<maximum> rating of Gravatar you wish returned. If you
have a family friendly forum, for example, you might set it to 'G.'

=item border (optional)

A hex color, e.g. FF00FF or F0F.

=item gravatar_id (not allowed)

This is B<not> an option but a generated variable. It is a hash of the
email address. The reason is it not supported as an optional variable
is it would allow avatar hijacking.

=item base (developer override)

This is allowed as a courtesy for the one or two developers who might
need it.

=back

=head1 DIAGNOSTICS

Email is the only required argument. Croaks without it.

Size and rating are also validated on each call. Croaks if an invalid
size (like 0 or 100) or rating (like MA or NC-17) is given.

=head1 CONFIGURATION AND ENVIRONMENT

No configuration is necessary. You may use the configuration hash of
your new template to pass default information like the default image
location for those without Gravatars. You can also set it in the USE
call per template if needed.

=head1 DEPENDENCIES (SEE ALSO)

L<Template>, L<Template::Plugin>, L<Carp>, L<Digest::MD5>, and
L<URI::Escape>.

http://www.gravatar.com/

=head1 BUGS AND LIMITATIONS

None known. This is beta software and I'd really appreciate bug
reports and feature requests via
C<bug-template-plugin-gravatar@rt.cpan.org>, or through the web
interface at L<http://rt.cpan.org/>.

=head1 AUTHOR

Ashley Pond V  C<< <ashley@cpan.org> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006, Ashley Pond V C<< <ashley@cpan.org> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
