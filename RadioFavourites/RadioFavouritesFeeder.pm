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
use Slim::Utils::Cache;

use Data::Dumper;
use POSIX qw(strftime);
use Digest::MD5 qw(md5_hex);

my $log = logger('plugin.radiofavourites');
my $prefs = preferences('plugin.RadioFavourites');
my $cache = Slim::Utils::Cache->new();

my $folderList = [];


sub init {

	$folderList = $prefs->get('Radio_Favourites_FolderList');
	Slim::Control::Request::addDispatch(['radiofavourites','addStation'],[0, 0, 1, \&Plugins::RadioFavourites::Plugin::_addStationCLI]);
	Slim::Control::Request::addDispatch(['radiofavourites','manage'],[0, 0, 1, \&_manageCLI]);

	_flushStationCache();  # clear the cache on reboot.
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

	my $menu = [];
	my $folderMenu = [];

	if ($folderList) {
		for my $folder (@$folderList) {
			push @$folderMenu,
			  {
				name => $folder,
				type => 'link',
				url => \&folderStationList,
				passthrough => [ { folder => $folder } ],
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

	getStationsForFolder($stationList, 1, '', $menu, sub { completeStationCollection($menu, $folderMenu, $callback); });

	return;
}


sub folderStationList {
	my ( $client, $callback, $args, $passDict ) = @_;

	my $folder = $passDict->{'folder'};

	my $menu = [];
	my $stationList = Plugins::RadioFavourites::Plugin::getStationList();

	getStationsForFolder(
		$stationList,
		0, $folder, $menu,
		sub {
			@$menu = sort { $a->{name} cmp $b->{name} } @$menu;
			$callback->({items => $menu});
		}
	);

	return;
}


sub isFolder {
	my $folder = shift;

	if ($folder) {
		for my $realFolder (@$folderList) {
			if ($folder eq $realFolder ) {
				return 1;
			}
		}
	}
	return;
}


sub getStationsForFolder {
	my ( $allStations, $isTop, $folder, $menu, $completionCallback ) = @_;

	#Get only those stations that are for this folder
	my $subStationList = [];

	for my $station (@$allStations) {
		if ($isTop) {
			if (!(isFolder($station->{folder})) ) {
				push @$subStationList, $station;
			}
		} else {
			if ($station->{folder} eq $folder) {
				push @$subStationList, $station;
			}
		}
	}


	my $stationCount = scalar @$subStationList;
	my $stationCounter = 0;

	if ($stationCount == 0) {
		main::DEBUGLOG && $log->is_debug && $log->debug("No Stations");
		$completionCallback->();
		return;
	}

	main::DEBUGLOG && $log->is_debug && $log->debug("Stations : $stationCount");

	my $i = 0;
	for my $station (@$subStationList) {
		if ( my $item = _getCachedItem($station->{url}) ) {
			$stationCounter++;
			push @$menu, $item;
			if ($stationCounter >= $stationCount) {
				$completionCallback->();
			}
		} else {

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

						if ($result->{endTime}) { #cache
							_cacheItem($result->{url}, $item, ($result->{endTime} - time()));
						}

						push @$menu, $item;

						$stationCounter++;
						main::DEBUGLOG && $log->is_debug && $log->debug("Station Programme Collection : $stationCounter $stationCount");

						if ($stationCounter >= $stationCount) {
							$completionCallback->();
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

						_cacheItem($result->{url}, $item, 120);

						push @$menu, $item;

						$stationCounter++;
						main::DEBUGLOG && $log->is_debug && $log->debug("Fail Station Collection $stationCounter $stationCount");
						if ($stationCounter >= $stationCount) {
							$completionCallback->();
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

				_cacheItem($station->{url}, $item, 120);

				push @$menu, $item;

				$stationCounter++;
				main::DEBUGLOG && $log->is_debug && $log->debug("Fail Station collection No Function key $stationCounter $stationCount");
				if ($stationCounter >= $stationCount) {
					$completionCallback->();
				}

			}
		}
	}
}


sub arrangeMenus{
	my $menu =shift;
	my $folderMenu = shift;

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
							move => $request->getParam('stationUrl'),
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
		for my $station (@$stationList) {
			if ($station->{url} eq $request->getParam('move')) {
				$station->{folder} = $request->getParam('folder');
			}
		}
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
					$prefs->set('Radio_Favourites_StationList', $stationList);
					Plugins::RadioFavourites::Plugin::setStationList($stationList);
				}
				$i++;
			}
		}
	}

	$request->setStatusDone;
	return;

}


sub completeStationCollection {
	my ( $menu, $folderMenu, $callback ) = @_;
	main::DEBUGLOG && $log->is_debug && $log->debug("Complete station collection");
	@$menu = sort { $a->{name} cmp $b->{name} } @$menu;
	arrangeMenus($menu, $folderMenu);
	$callback->( { items => $menu } );
}


sub _cacheItem {
	my $url  = shift;
	my $item = shift;
	my $seconds = shift;
	main::DEBUGLOG && $log->is_debug && $log->debug("++_cacheMenu");
	my $cacheKey = 'RF:' . md5_hex($url);

	$cache->set( $cacheKey, \$item, $seconds );

	main::DEBUGLOG && $log->is_debug && $log->debug("--_cacheMenu");
	return;
}


sub _getCachedItem {
	my $url = shift;
	main::DEBUGLOG && $log->is_debug && $log->debug("++_getCachedMenu");

	my $cacheKey = 'RF:' . md5_hex($url);

	if ( my $cachedMenu = $cache->get($cacheKey) ) {
		my $item = ${$cachedMenu};
		main::DEBUGLOG && $log->is_debug && $log->debug("--_getCachedMenu got cached menu");
		return $item;
	}else {
		main::DEBUGLOG && $log->is_debug && $log->debug("--_getCachedMenu no cache");
		return;
	}
}


sub _flushStationCache {
	my $url  = shift;
	main::DEBUGLOG && $log->is_debug && $log->debug("++_removeCacheMenu");
	my $stationList = Plugins::RadioFavourites::Plugin::getStationList();

	for my $station (@$stationList) {
		my $cacheKey = 'RF:' . md5_hex($station->{url});
		$cache->remove($cacheKey);
	}

	main::DEBUGLOG && $log->is_debug && $log->debug("--_removeCacheMenu");
	return;
}

1;