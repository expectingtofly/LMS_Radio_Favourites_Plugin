package Plugins::RadioFavourites::Settings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;
use Slim::Utils::Log;

my $log = logger('plugin.radiofavourites');

use Plugins::RadioFavourites::RadioFavouritesFeeder;


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

		my $stationList = Plugins::RadioFavourites::Plugin::getStationList()||[];

		my $i = 1;
		for my $station (@$stationList) {			
			if ($params->{"pref_folder_$i"} eq 'topLevel') {
				$station->{folder} = undef;
			} else {
				$station->{folder} = $params->{"pref_folder_$i"};
			}
			$station->{name} = $params->{"pref_station_name_$i"};
			$station->{customUrl} = $params->{"pref_custom_url_$i"};
			$i++
		}
		Plugins::RadioFavourites::Plugin::setStationList($stationList);
		$prefs->set('Radio_Favourites_StationList', $stationList);


		#Get rid of deleted items
		my $urlsToDelete = [];

		for (my $i = 1; $i <= scalar @$stationList; $i++) {			
			if ($params->{"pref_delete_favourite_$i"}) {
				main::DEBUGLOG && $log->is_debug && $log->debug("Deleting " . @$stationList[$i-1]->{url} );
				push @$urlsToDelete, @$stationList[$i-1]->{url};
			}
		}
		for my $url (@$urlsToDelete) {			
			Plugins::RadioFavourites::RadioFavouritesFeeder::deleteStation($url);
		}

		my $folders = Plugins::RadioFavourites::RadioFavouritesFeeder::getFolderList() || [];

		for my $folder (@$folders) {
			if ($params->{"pref_delete_folder_$folder"}) {
				Plugins::RadioFavourites::RadioFavouritesFeeder::deleteFolder($folder);
			}
		}

		Plugins::RadioFavourites::RadioFavouritesFeeder::_flushStationCache();

	}

	$params->{favourites} = Plugins::RadioFavourites::Plugin::getStationList() || [];

	my $folders = Plugins::RadioFavourites::RadioFavouritesFeeder::getFolderList() || [];
	$params->{folders} = $folders;
	$params->{hasFolders} = scalar @$folders;

	return $class->SUPER::handler( $client, $params );
}

1;