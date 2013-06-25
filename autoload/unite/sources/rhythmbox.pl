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
my $rhythmbox = $bus->get_service("org.gnome.Rhythmbox3");
my $rhythmdb = $rhythmbox->get_object("/org/gnome/Rhythmbox3/RhythmDB", "org.gnome.Rhythmbox3.RhythmDB"); 
my $mediaplayer = $bus->get_service("org.mpris.MediaPlayer2.rhythmbox");
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
