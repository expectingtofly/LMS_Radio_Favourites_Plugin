package Plugins::RadioFavourites::FolderProtocolHandler;

# Copyright (C) 2020 stu@expectingtofly.co.uk
#
# This file is part of LMS_RADIO_FAVOURITES_PLUGIN
#
# LMS_RADIO_FAVOURITES_PLUGIN is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# LMS_RADIO_FAVOURITES_PLUGIN is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with LMS_BBC_Sounds_Plugin.  If not, see <http://www.gnu.org/licenses/>.

use strict;

use Plugins::RadioFavourites::RadioFavouritesFeeder;

Slim::Player::ProtocolHandlers->registerHandler('radfavfolder', __PACKAGE__);

use Slim::Utils::Log;
my $log = logger('plugin.radiofavourites');

sub canDirectStream { 0 }
sub isRemote { 1 }


sub explodePlaylist {
	my ( $class, $client, $url, $cb ) = @_;

	if ($main::VERSION lt '8.2.0') {
		$log->warn("Radio Station Folder Favourites only supported in LMS 8.2.0 and greater");
		$cb->(['Radio Favourites Folder Favourites require LMS 8.2.0 or greater']);
		return;
	}

	my @group = split /:\/\//, $url;
	my $folder = @group[1];


	Plugins::RadioFavourites::RadioFavouritesFeeder::folderStationList(	$client, $cb, undef, {folder => $folder});


	return;
}


1;

