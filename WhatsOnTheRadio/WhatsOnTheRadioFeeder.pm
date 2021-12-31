package Plugins::WhatsOnTheRadio::WhatsOnTheRadioFeeder;

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

use Slim::Utils::Strings qw(string);
use Slim::Utils::Log;

use Data::Dumper;
use POSIX qw(strftime);

my $log = logger('plugin.whatsontheradio');


sub stationlist {
    my ( $client, $callback, $args ) = @_;
    main::DEBUGLOG && $log->is_debug && $log->debug("++stationlist");

    my $stationList = Plugins::WhatsOnTheRadio::Plugin::getStationList();

    my $stationCount = 0;
    if ($stationList) {
        $stationCount = scalar @$stationList;
    }
    my $stationCounter = 0;

    my $menu = [];

    if ($stationCount == 0) {
         main::DEBUGLOG && $log->is_debug && $log->debug("No Stations");
         $callback->( { items => {name=>'No Stations Added. Add a station from a compatible plugin', type=>'text'} } );
         return;         
    }

    main::DEBUGLOG && $log->is_debug && $log->debug("Stations : $stationCount");

    for my $station (@$stationList) {
        main::DEBUGLOG && $log->is_debug && $log->debug("Station loop");
        main::DEBUGLOG && $log->is_debug && $log->debug(Dumper($station));
        if (my $function = getFunctionFromKey($station->{handlerFunctionKey})) {
            $function->($station->{url}, $station->{stationKey}, 'now', 
            sub {  ## success
                my $result = shift;
                main::DEBUGLOG && $log->is_debug && $log->debug("Success");
                main::DEBUGLOG && $log->is_debug && $log->debug(Dumper($result));
                my $startTime =  strftime( '%H:%M ', localtime($result->{startTime}) );
                my $endTime =  strftime( '%H:%M ', localtime($result->{endTime}) );
                push @$menu, {
                    name        => $station->{name} . ' - ' .  $result->{title},
					type        => 'audio',                    
                    line2       =>  $startTime . ' to ' . $endTime . ' ' . $result->{description},                    					
					image       => $result->{image},					
					url         => $station->{url},					
					on_select   => 'play'
                };
                $stationCounter++;
                main::DEBUGLOG && $log->is_debug && $log->debug("Got it $stationCounter $stationCount");
                if ($stationCounter >= $stationCount) {                     
                    main::DEBUGLOG && $log->is_debug && $log->debug("Complete collection");
                    $callback->( { items => $menu } );
                }
            },
            sub {  ## failure
             main::DEBUGLOG && $log->is_debug && $log->debug("Fail");
             push @$menu, {
                    name        => $station->{name},
					type        => 'audio',
                    artist      => 'Could not retrieve now playing',                      
					url         => $station->{url},					
					on_select   => 'play'
                };
                $stationCounter++;
                main::DEBUGLOG && $log->is_debug && $log->debug("Fail $StationCounter $stationCount");
                if ($stationCounter >= $stationCount) {
                    $callback->( { items => $menu } );
                }


             } );
        }        
    }
    return;
}

sub getFunctionFromKey {
    my $key = shift;

    my $handlerList = Plugins::WhatsOnTheRadio::Plugin::getHandlers();

    main::DEBUGLOG && $log->is_debug && $log->debug(Dumper($handlerList));
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

1;