use strict;
use Config::Simple;
use File::Find;
use File::Spec::Functions;
use URI::file;
use Net::DBus qw/ dbus_string dbus_boolean/;
use Getopt::Long;
use JSON::XS;

sub library_path {
    my $path;
    if (my $gsettings = `which gsettings 2> /dev/null`) {
        my $ret = `gsettings get org.gnome.rhythmbox.rhythmdb locations`;
        $ret =~ s/^\['([^']+)'.*/\1/;
        $path = URI->new($ret)->file;
    } else {
        my $config = Config::Simple->new(
            catfile($ENV{HOME}, '.config', 'user-dirs.dirs'));
        if ($config) {
            $path = $config->param("XDG_MUSIC_DIR");
            $path =~ s/\$([A-Z]+)/$ENV{$1}/e;
        }
    }
    $path;
}

my ($toggle, $uri);
GetOptions('play=s' => \$uri, toggle => \$toggle);

my $bus = Net::DBus->find;
my $rhythmbox = $bus->get_service("org.gnome.Rhythmbox3");
my $rhythmdb = $rhythmbox->get_object("/org/gnome/Rhythmbox3/RhythmDB", "org.gnome.Rhythmbox3.RhythmDB"); 
my $mediaplayer;
while (!defined $mediaplayer) {
  eval { $mediaplayer = $bus->get_service("org.mpris.MediaPlayer2.rhythmbox") };
  sleep 1
}
my $player = $mediaplayer->get_object("/org/mpris/MediaPlayer2", "org.mpris.MediaPlayer2.Player"); 

if ($toggle) {
    $player->PlayPause();
} elsif ($uri) {
    $player->OpenUri($uri);
} else {
    finddepth(sub {
        return if $_ eq '.' || $_ eq '..' || $_ !~ /\.mp3$|\.ogg$/;
        eval {
            my $uri = URI::file->new($File::Find::name)->as_string;
            my $props = $rhythmdb->GetEntryProperties($uri);
            printf "%s\t%s\t%s\t%s\n",
                 $props->{artist}, $props->{album}, $props->{title}, $uri;
        };
    }, library_path);
}
