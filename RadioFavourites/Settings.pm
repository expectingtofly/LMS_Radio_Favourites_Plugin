package Plugins::RadioFavourites::Settings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;

my $prefs = preferences('plugin.RadioFavourites');


sub name {
	return 'PLUGIN_RADIOFAVOURITES';
}


sub page {
	return 'plugins/RadioFavourites/settings/basic.html';
}


sub prefs {
	return ( $prefs, qw(is_radio) );
}


sub handler {
	my ( $class, $client, $params, $callback, @args ) = @_;

	if ($params->{saveSettings}) {
		if ($params->{clearFavouriteStations}) {
			$prefs->set('Radio_Favourites_StationList', []);
			Plugins::RadioFavourites::Plugin::setStationList([]);
		}
		if ($params->{deleteAllFolders}) {
			$prefs->set('Radio_Favourites_FolderList', []);
			Plugins::RadioFavourites::RadioFavouritesFeeder::setFolderList([]);
		}
	}
    return $class->SUPER::handler( $client, $params );
}

1;