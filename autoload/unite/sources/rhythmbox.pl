use strict;
use Config::Simple;
use File::Find;
use File::Spec::Functions;
use URI::file;
use Net::DBus qw/ dbus_string dbus_boolean/;
use Getopt::Long;

sub library_path {
    my $config = Config::Simple->new(
        catfile($ENV{HOME}, '.config', 'user-dirs.dirs'));
    my $path = $config->param("XDG_MUSIC_DIR");
    $path =~ s/\$([A-Z]+)/$ENV{$1}/e;
    $path;
}

my ($toggle, $uri);
GetOptions('play=s' => \$uri, toggle => \$toggle);

my $bus = Net::DBus->find;
my $rhythmbox = $bus->get_service("org.gnome.Rhythmbox");
my $shell = $rhythmbox->get_object("/org/gnome/Rhythmbox/Shell", "org.gnome.Rhythmbox.Shell"); 
my $player = $rhythmbox->get_object("/org/gnome/Rhythmbox/Player", "org.gnome.Rhythmbox.Player"); 

if ($toggle) {
    $player->playPause(1);
} elsif ($uri) {
    $shell->loadURI($uri, 1);
} else {
    finddepth(sub {
        return if $_ eq '.' || $_ eq '..' || $_ !~ /\.mp3$|\.ogg$/;
        eval {
            my $uri = URI::file->new($File::Find::name)->as_string;
            my $props = $shell->getSongProperties($uri);
            printf "%s\t%s\t%s\t%s\n",
                 $props->{artist}, $props->{album}, $props->{title}, $uri;
        };
    }, library_path);
}
