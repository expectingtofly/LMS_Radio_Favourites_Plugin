package Plugins::WhatsOnTheRadio::Settings;

use strict;
use base qw(Slim::Web::Settings);

use Slim::Utils::Prefs;

my $prefs = preferences('plugin.WhatsOnTheRadio');


sub name {
	return 'PLUGIN_WHATSONTHERADIO';
}


sub page {
	return 'plugins/WhatsOnTheRadio/settings/basic.html';
}


sub prefs {
	return ( $prefs, qw(is_radio) );
}


sub handler {
	my ( $class, $client, $params, $callback, @args ) = @_;

	if ($params->{saveSettings}) {
		if ($params->{clearFavouriteStations}) {
			$prefs->set('WOTR_StationList', []);
			Plugins::WhatsOnTheRadio::Plugin::setStationList([]);
		}
	}
    return $class->SUPER::handler( $client, $params );
}

1;