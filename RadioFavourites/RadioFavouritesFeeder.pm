package Plugins::RadioFavourites::RadioFavouritesFeeder;

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

use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;
use Slim::Utils::Prefs;

use Data::Dumper;
use POSIX qw(strftime);

my $log = logger('plugin.RadioFavourites');
my $prefs = preferences('plugin.RadioFavourites');

my $folderList = [];


sub init {

	$folderList = $prefs->get('Radio_Favourites_FolderList');
	Slim::Control::Request::addDispatch(['radiofavourites','addStation'],[0, 0, 1, \&Plugins::RadioFavourites::Plugin::_addStationCLI]);
	Slim::Control::Request::addDispatch(['radiofavourites','manage'],[0, 0, 1, \&_manageCLI]);
	return;
}


sub stationlist {
	my ( $client, $callback, $args ) = @_;
	main::DEBUGLOG && $log->is_debug && $log->debug("++stationlist");

	my $stationList = Plugins::RadioFavourites::Plugin::getStationList();

	my $stationCount = 0;
	if ($stationList) {
		$stationCount = scalar @$stationList;
	}
	my $stationCounter = 0;

	my $menu = [];
	my $folderMenu = [];	

	if ($folderList) {
		for my $folder (@$folderList) {
			push @$folderMenu,
			  {
				name => $folder,
				type => 'link',
				items => [],
				itemActions => {
					info => {
						command     => ['radiofavourites', 'manage'],
						fixedParams => { act => 'deletefolder', folder => $folder },
					},
				}
			  };
		}
	}

	if ($stationCount == 0) {
		main::DEBUGLOG && $log->is_debug && $log->debug("No Stations");
		$callback->( { items => [{name=> string('PLUGIN_RADIOFAVOURITES_NOSTATIONS_MESSAGE'), type=>'text'}] } );
		return;
	}

	main::DEBUGLOG && $log->is_debug && $log->debug("Stations : $stationCount");
	my $i = 0;
	for my $station (@$stationList) {		
		if (my $function = getFunctionFromKey($station->{handlerFunctionKey})) {
			$function->(
				$station->{url},
				$station->{stationKey},
				$station->{name},
				'now',
				sub {  ## success
					my $result = shift;					
					my $startTime =  strftime( '%H:%M', localtime($result->{startTime}) );
					my $endTime =  strftime( '%H:%M', localtime($result->{endTime}) );
					my $item = {
						name        => $result->{stationName} . ' - ' .  $result->{title},
						type        => 'audio',
						line2       =>  $startTime . ' to ' . $endTime . ' ' . $result->{description},
						image       => $result->{image},
						itemActions => {
							info => {
								command     => ['radiofavourites', 'manage'],
								fixedParams => { stationUrl => $result->{url}, stationItem => $i++ }
							}
						},
						url         => $result->{url},
						on_select   => 'play'
					};


					if (!placeItemInFolder($folderMenu,$item)) {
						push @$menu, $item;
					}
					$stationCounter++;
					main::DEBUGLOG && $log->is_debug && $log->debug("Station Programme Collection : $stationCounter $stationCount");

					if ($stationCounter >= $stationCount) {
						main::DEBUGLOG && $log->is_debug && $log->debug("Complete station collection");
						@$menu = sort { $a->{name} cmp $b->{name} } @$menu;
						arrangeMenus($menu, $folderMenu);
						$callback->( { items => $menu } );
					}
				},
				sub {  ## failure
					my $result = shift;
					$log->warn('Failed to retrieve station now on data');
					my $item = {
						name        => $result->{stationName},
						type        => 'audio',
						artist      => string('PLUGIN_RADIOFAVOURITES_NONOWPLAYINGAVAILABLE'),
						itemActions => {
							info => {
								command     => ['radiofavourites', 'manage'],
								fixedParams => { stationUrl => $result->{url}, stationItem => $i++ }
							}
						},
						url         => $result->{url},
						on_select   => 'play'
					};

					if (!placeItemInFolder($folderMenu,$item)) {
						push @$menu, $item;
					}

					$stationCounter++;
					main::DEBUGLOG && $log->is_debug && $log->debug("Fail Station Collection $stationCounter $stationCount");
					if ($stationCounter >= $stationCount) {
						arrangeMenus($menu, $folderMenu);
						$callback->( { items => $menu } );

					}
				}
			);
		} else {

			$log->warn("No Function key for station, has the plugin been uninstalled");
			my $item = {
				name        => $station->{stationName},
				type        => 'audio',
				artist      => string('PLUGIN_RADIOFAVOURITES_NONOWPLAYINGAVAILABLE'),
				itemActions => {
					info => {
						command     => ['radiofavourites', 'manage'],
						fixedParams => { stationUrl => $station->{url}, stationItem => $i++ }
					}
				},
				url         => $station->{url},
				on_select   => 'play'
			};

			if (!placeItemInFolder($folderMenu,$item)) {
				push @$menu, $item;
			}

			$stationCounter++;
			main::DEBUGLOG && $log->is_debug && $log->debug("Fail Station collection No Function key $stationCounter $stationCount");
			if ($stationCounter >= $stationCount) {
				arrangeMenus($menu, $folderMenu);
				$callback->( { items => $menu } );

			}

		}
	}
	return;
}


sub arrangeMenus{
	my $menu =shift;
	my $folderMenu = shift;

	@$menu = sort { $a->{name} cmp $b->{name} } @$menu;

	unshift @$menu, @$folderMenu;

	createFolderMenu($menu);
	
	return;
}


sub createFolderMenu {
	my $menu =shift;

	push @$menu,
	  {
		name => string('PLUGIN_RADIOFAVOURITES_CREATE_FOLDER'),
		type => 'search',
		url =>  \&createFolder,
		nextWindow => 'refresh'
	  };
	return;
}


sub createFolder {
	my ( $client, $callback, $args, $passDict ) = @_;	

	my $folder = $args->{'search'};

	main::DEBUGLOG && $log->is_debug && $log->debug("Create Folder $folder");

	push @$folderList, $folder;

	$prefs->set( 'Radio_Favourites_FolderList', $folderList );
	my $replMenu = {
		type        => 'text',
		name        => string('PLUGIN_RADIOFAVOURITES_FOLDER_CREATED'),
		showBriefly => 1,
		popback     => 1,
		refresh     => 1,
	};

	$callback->( [$replMenu] );


	return;
}


sub setFolderList {
	my $list = shift;
	$folderList = $list;	
}


sub getFunctionFromKey {
	my $key = shift;

	my $handlerList = Plugins::RadioFavourites::Plugin::getHandlers();

	main::DEBUGLOG && $log->is_debug && $log->debug("Function Key $key");

	for my $handler (@$handlerList) {
		if ($handler->{handlerFunctionKey} eq $key) {
			main::DEBUGLOG && $log->is_debug && $log->debug("Found $key");
			return $handler->{handlerSub};
		}
	}
	$log->error("No Function Key Found");
	return;
}


sub _manageCLI {
	my $request = shift;
	my $client = $request->client;

	# check this is the correct command.
	if ($request->isNotCommand([['radiofavourites'], ['manage']])) {
		$request->setStatusBadDispatch();
		return;
	}

	my $items = [];

	if (defined $request->getParam('stationItem')) {
		for my $folder (@$folderList) {
			push @$items,
			  {
				text => string('PLUGIN_RADIOFAVOURITES_MOVE_TO') . ' ' . $folder . ' ' . string('PLUGIN_RADIOFAVOURITES_FOLDER'),
				actions => {
					go => {
						player => 0,
						cmd    => ['radiofavourites', 'manage' ],
						params => {
							move => $request->getParam('stationItem'),
							folder =>  $folder
						},
					},
				},
				nextWindow => 'parent',
			  };
		}
		push @$items,
		  {
			text => string('PLUGIN_RADIOFAVOURITES_DELETE_STATION'),
			actions => {
				go => {
					player => 0,
					cmd    => ['radiofavourites', 'manage' ],
					params => {
						act =>'confirmdeletestation',
						stationUrl =>  $request->getParam('stationUrl')
					},
				},
			},
			nextWindow => 'parent',
		  };

		$request->addResult('offset', 0);
		$request->addResult('count', scalar @$items);
		$request->addResult('item_loop', $items);
	} elsif (defined $request->getParam('move')) {
		my $stationList = Plugins::RadioFavourites::Plugin::getStationList();
		@$stationList[$request->getParam('move')]->{folder} = $request->getParam('folder');
		Plugins::RadioFavourites::Plugin::setStationList($stationList);
		$prefs->set( 'Radio_Favourites_StationList', $stationList );
	} elsif (defined $request->getParam('act')) {
		if ($request->getParam('act') eq 'deletefolder') {
			push @$items,
			  {
				text => string('PLUGIN_RADIOFAVOURITES_DELETE_FOLDER'),
				actions => {
					go => {
						player => 0,
						cmd    => ['radiofavourites', 'manage' ],
						params => {
							act =>'confirmdeletefolder',
							folder =>  $request->getParam('folder')
						},
					},
				},
				nextWindow => 'parent',
			  };
			$request->addResult('offset', 0);
			$request->addResult('count', scalar @$items);
			$request->addResult('item_loop', $items);
		} elsif ($request->getParam('act') eq 'confirmdeletefolder') {
			my $i = 0;
			for my $folder (@$folderList) {
				if ($folder eq $request->getParam('folder')) {
					splice @$folderList, $i, 1;
					$prefs->set( 'Radio_Favourites_FolderList', $folderList );
				}
				$i++;
			}
		} elsif ($request->getParam('act') eq 'confirmdeletestation') {
			my $stationList = Plugins::RadioFavourites::Plugin::getStationList();
			my $i = 0;
			for my $station (@$stationList) {
				if ($station->{url} eq $request->getParam('stationUrl')) {
					splice @$stationList, $i, 1;
					$prefs->set('Radio_Favourites_StationList', []);
					Plugins::RadioFavourites::Plugin::setStationList($stationList);
				}
				$i++;
			}
		}
	}

	$request->setStatusDone;
	return;

}


sub placeItemInFolder {
	my $folderMenu = shift;
	my $item = shift;

	my $url = $item->{url};
	my $stationList = Plugins::RadioFavourites::Plugin::getStationList();

	for my $station (@$stationList) {
		if ($url eq $station->{url}) {
			if (defined $station->{folder}) {
				for my $folder (@$folderMenu) {
					if ($folder->{name} eq $station->{folder}) {
						my $items = $folder->{items};
						push @$items, $item;
						return 1;
					}
				}
			}
		}
	}
	return;
}

1;