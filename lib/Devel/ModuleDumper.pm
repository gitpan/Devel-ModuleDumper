package Devel::ModuleDumper;
use strict;
use warnings;

our %seen;
BEGIN {
    %seen = %INC;
}

our $VERSION = '0.01';

our %pragmas;
for my $pragma (qw/
    charnames  constant
    diagnostics
    encoding
    feature  fields  filetest
    if  integer
    less  lib  locale
    mro
    open  ops  overload  overloading
    parent
    re
    sigtrap  sort  strict  subs
    threads  threads::shared
    utf8
    vars  vmsish
    warnings  warnings::register
/) {
    $pragmas{$pragma} = 1;
}

our %skips;
for my $class (qw/
    AutoLoader
    Benchmark
    base
    bytes
    Config
    DynaLoader
    XSLoader
/) {
    $skips{$class} = 1;
}

my $ALL = $ENV{MODULEDUMPER_SHOW_ALL};

our $SHOWN = 0;

sub show {
    my $result = '';

    return $result if $SHOWN;

    my $modules = _get_module_information();

    $result .= "Perl\t$]\n";

    for my $module (sort { uc($a) cmp uc($b) } keys %{$modules}) {
        $result .= sprintf "%s\t%s\n", $module, $modules->{$module}->{version};
    }

    $SHOWN = 1;

    return $result;
}

sub _get_module_information {
    my %modules;
    for my $module_path (keys %INC) {
        my $class = _path2class($module_path);
        unless ($ALL) {
            next if $seen{$module_path}
                        || $module_path !~ m!\.pm$!
                        || $pragmas{$class}
                        || $skips{$class}
                        || $class eq __PACKAGE__;
        }
        $modules{$class} = {
            version => _get_version($class),
        };
    }
    return \%modules;
}

sub _path2class {
    my $path = shift;

    my $class = $path;
    $class =~ s!/!::!g;
    $class =~ s!\.pm$!!;

    return $class;
}

sub _get_version {
    my $module = shift;

    my $version = eval {
        my $v = $module->VERSION;
        unless (defined $v) {
            $v = ${"${module}::VERSION"};
        }
        $v;
    };
    if ($@ || !defined $version) {
        $version = 'none';
    }

    return $version;
}

END {
    my $info = show();
    print $info;
}

package # hide the package from the PAUSE indexer
    DB;
sub DB {}

1;

__END__

=head1 NAME

Devel::ModuleDumper - show module information automatically


=head1 SYNOPSIS

    $ perl -d:ModuleDumper -MData::Dumper -e 'print "foo!\n"'
    foo!
    Perl    5.012002
    Carp    1.17
    Data::Dumper    2.125
    Exporter        5.64_01


=head1 DESCRIPTION

C<Devel::ModuleDumper> shows the module information at the end of your script.

This module is especially useful for a L<Benchmark> report.

For example, here is the benchmark script.

    # crypt_benchmark.pl
    
    use strict;
    use warnings;

    use Benchmarks sub {

        use Digest::HMAC_SHA1 qw(hmac_sha1_hex);
        use Digest::HMAC_MD5 qw(hmac_md5_hex);

        my $STR = '@test123';
        my $KEY = 'ABC';

        {
            'hmac_sha1' => sub { hmac_sha1_hex($STR, $KEY); },
            'hmac_md5'  => sub { hmac_md5_hex($STR, $KEY); },
            'crypt'     => sub { crypt($STR, $KEY); },
        };
    };

To invoke with C<Devel::ModuleDumper>.

    $ perl -d:ModuleDumper crypt_benchmark.pl
    
    Benchmark: running crypt, hmac_md5, hmac_sha1 for at least 1 CPU seconds...
         crypt:  1 wallclock secs ( 1.06 usr +  0.00 sys =  1.06 CPU) @ 108196.23/s (n=114688)
      hmac_md5:  1 wallclock secs ( 1.10 usr +  0.00 sys =  1.10 CPU) @ 195490.00/s (n=215039)
     hmac_sha1:  1 wallclock secs ( 1.03 usr +  0.00 sys =  1.03 CPU) @ 111346.60/s (n=114687)
                  Rate     crypt hmac_sha1  hmac_md5
    crypt     108196/s        --       -3%      -45%
    hmac_sha1 111347/s        3%        --      -43%
    hmac_md5  195490/s       81%       76%        --
    
    Perl    5.012002
    Benchmarks      0.05
    Carp    1.17
    Digest::base    1.16
    Digest::HMAC    1.03
    Digest::HMAC_MD5        1.01
    Digest::HMAC_SHA1       1.03
    Digest::MD5     2.39
    Digest::SHA     5.47
    Exporter        5.64_01
    Exporter::Heavy 5.64_01
    MIME::Base64    3.08
    Time::HiRes     1.9719

All you need to do is add C<-d:ModuleDumper>.


=head1 ENVIRONMENT VARIABLE

=over

=item MODINFO_SHOW_ALL

By default, some modules are filtered. If you set C<MODULEDUMPER_SHOW_ALL=1>, all module information will output.

=back


=head1 METHOD

=over

=item show

To build an information of modules. This method returns the string;

=back


=head1 REPOSITORY

Devel::ModuleDumper is hosted on github: L<http://github.com/bayashi/Devel-ModuleDumper>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
