package Plugins::RadioFavourites::Plugin;

# Copyright (C) 2021 Stuart McLean stu@expectingtofly.co.uk

#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
#  MA 02110-1301, USA.


use warnings;
use strict;

use base qw(Slim::Plugin::OPMLBased);

use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;
use Slim::Utils::Prefs;

use Data::Dumper;

use Plugins::RadioFavourites::RadioFavouritesFeeder;

my $log = Slim::Utils::Log->addLogCategory(
	{
		'category'     => 'plugin.RadioFavourites',
		'defaultLevel' => 'WARN',
		'description'  => getDisplayName(),
	}
);

my $prefs = preferences('plugin.RadioFavourites');

my $stationList = $prefs->get('Radio_Favourites_StationList');
my $handlerList = [];


sub initPlugin {
	my $class = shift;

	$prefs->init(
		{
			is_radio => 1
		}
	);


	$class->SUPER::initPlugin(
		feed   => \&Plugins::RadioFavourites::RadioFavouritesFeeder::stationlist,
		tag    => 'RadioFavourites',
		menu   => 'radios',
		is_app => $class->can('nonSNApps') && (!($prefs->get('is_radio'))) ? 1 : undef,
		weight => 1,
	);

	# make sure the value is defined, otherwise it would be enabled again
	$prefs->setChange(
		sub {
			$prefs->set($_[0], 0) unless defined $_[1];
		},
		'pref_is_radio'
	);

	if ( !$::noweb ) {
		require Plugins::RadioFavourites::Settings;
		Plugins::RadioFavourites::Settings->new;
	}


	return;
}


sub postinitPlugin {

	Plugins::RadioFavourites::RadioFavouritesFeeder::init();

	return;
}


sub getDisplayName { return 'PLUGIN_RADIOFAVOURITES'; }


sub playerMenu {
	my $class = shift;

	if ($prefs->get('is_radio')  || (!($class->can('nonSNApps')))) {
		$log->info('Placing in Radio Menu');
		return 'RADIO';
	}else{
		$log->info('Placing in App Menu');
		return;
	}
}


sub getStationList {
	return $stationList;
}


sub setStationList {
	my	$stationListIn = shift;
	$stationList = $stationListIn;
}


sub addStationToWOTR {
	my $stationDetails = shift;

	#name
	#stationKey

	#url
	#handlerFunctionKey

	for my $station (@$stationList) {
		if ($station->{url} eq $stationDetails->{url}) {
			$log->warn("Duplicate station, station not added");
			return;
		}
	}

	push @$stationList, $stationDetails;

	$prefs->set( 'Radio_Favourites_StationList', $stationList );

	return 1;
}


sub _addStationCLI {
	my $request = shift;
	my $client = $request->client;

	# check this is the correct command.
	if ($request->isNotCommand([['radiofavourites'], ['addStation']])) {
		$request->setStatusBadDispatch();
		return;
	}


	my $items = [];


	if (!(defined $request->getParam('act'))) {

		push @$items,
		  {
			text => string('PLUGIN_RADIOFAVOURITES_ADD_STATION'),
			actions => {
				go => {
					player => 0,
					cmd    => ['radiofavourites', 'addStation' ],
					params => {
						name =>  		$request->getParam('name'),
						stationKey => 	$request->getParam('stationKey'),
						url =>  		$request->getParam('url'),
						handlerFunctionKey =>  $request->getParam('handlerFunctionKey'),
						act => 'add'
					},
				}
			},
			nextWindow => 'parent',
		  };
		$request->addResult('offset', 0);
		$request->addResult('count', scalar @$items);
		$request->addResult('item_loop', $items);
		$request->setStatusDone;

	} else {

		my $act = $request->getParam('act');
		if ($act eq 'add') {
			addStationToWOTR(
				{
					name =>  		$request->getParam('name'),
					stationKey => 	$request->getParam('stationKey'),
					url =>  		$request->getParam('url'),
					handlerFunctionKey =>  $request->getParam('handlerFunctionKey')
				}
			);
			my $result = string('PLUGIN_RADIOFAVOURITES_STATION_ADDED');
			$request->addResult($result);
			$client->showBriefly(
				{
					line => [ $result, string('PLUGIN_RADIOFAVOURITES') ],
				}
			);

			$request->setStatusDone();

		}
	}

}


sub addHandler{
	my $handler = shift;

	#handlerFunctionkey
	#handlerSub

	push @$handlerList, $handler;

}


sub getHandlers {
	return $handlerList;
}

1;
