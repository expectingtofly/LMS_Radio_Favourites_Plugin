package Plugins::WhatsOnTheRadio::Plugin;

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

use Plugins::WhatsOnTheRadio::WhatsOnTheRadioFeeder;

my $log = Slim::Utils::Log->addLogCategory(
	{
		'category'     => 'plugin.whatsontheradio',
		'defaultLevel' => 'DEBUG',
		'description'  => getDisplayName(),
	}
);

my $prefs = preferences('plugin.whatsontheradio');

my $stationList = $prefs->get('WOTR_StationList');
my $handlerList = [];

Slim::Control::Request::addDispatch(['wotr','addStation'],[0, 0, 1, \&_addStationCLI]);


sub initPlugin {
	my $class = shift;

	$prefs->init(
		{
			is_radio => 0
		}
	);


	$class->SUPER::initPlugin(
		feed   => \&Plugins::WhatsOnTheRadio::WhatsOnTheRadioFeeder::stationlist,
		tag    => 'whatsontheradio',
		menu   => 'radios',
		is_app => $class->can('nonSNApps') && (!($prefs->get('is_radio'))) ? 1 : undef,
		weight => 1,
	);

	if ( !$::noweb ) {
		require Plugins::WhatsOnTheRadio::Settings;
		Plugins::WhatsOnTheRadio::Settings->new;
	}


	return;
}


sub getDisplayName { return 'PLUGIN_WHATSONTHERADIO'; }


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

	main::DEBUGLOG && $log->is_debug && $log->debug("StationDetails : " . Dumper($stationDetails));

	push @$stationList, $stationDetails;
	main::DEBUGLOG && $log->is_debug && $log->debug("StationList : " . Dumper($stationList));	

	$prefs->set( 'WOTR_StationList', $stationList );

}


sub _addStationCLI {
	my $request = shift;
	my $client = $request->client;

	main::DEBUGLOG && $log->is_debug && $log->debug(Dumper($request));

	# check this is the correct command.
	if ($request->isNotCommand([['wotr'], ['addStation']])) {
		$request->setStatusBadDispatch();
		return;
	}


	my $items = [];


	if (!(defined $request->getParam('act'))) {

		push @$items,
		  {
			text => "Add to What's On The Radio",
			actions => {
				go => {
					player => 0,
					cmd    => ['wotr', 'addStation' ],
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
			my $result = 'Station Added';
			$request->addResult($result);
			$client->showBriefly(
				{
					line => [ $result, "What's on The Radio" ],
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
