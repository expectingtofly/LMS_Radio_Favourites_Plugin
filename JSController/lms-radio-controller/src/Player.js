import React from 'react';
import Stack from '@mui/material/Stack';
import Container from '@mui/material/Container';
import Card from '@mui/material/Card';
import CardMedia from '@mui/material/CardMedia';

import PresetButtons from './PresetButtons';
import RadioFavourites from './RadioFavourites';
import Schedule from './Schedule';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import RewindIcon from '@mui/icons-material/FastRewind';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PauseIcon from '@mui/icons-material/Pause';
import FastForwardIcon from '@mui/icons-material/FastForward';

import PlayCircleOutlineIcon from '@mui/icons-material/PlayCircleOutline';
import FavoriteIcon from '@mui/icons-material/Favorite';
import ViewListIcon from '@mui/icons-material/ViewList';

import Paper from '@mui/material/Paper';
import BottomNavigation from '@mui/material/BottomNavigation';
import BottomNavigationAction from '@mui/material/BottomNavigationAction';






function MediaButtons(props) {
    const playIcon = props.playStatus === 'play' ? <PauseIcon sx={{ height: 38, width: 38 }} /> : <PlayArrowIcon sx={{ height: 38, width: 38 }} />
    const playStatus = props.playStatus;    

    return (
        <Container>
            <IconButton aria-label="previous">
                <RewindIcon />
            </IconButton>
            <IconButton
                aria-label="play/pause"
                onClick={() => props.onClick(playStatus)}
            >
                {playIcon}
            </IconButton>
            <IconButton aria-label="next">
                <FastForwardIcon />
            </IconButton>
        </Container>
    );
}






class Player extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            nowPlaying: null,
            presets: [],
            radioFavourites: null,
            navValue: "player",
        }
    }

    getNowPlaying(playerId) {
        fetch("/api/players/" + playerId + "/queue")
            .then(res => res.json())
            .then(
                (result) => {
                    const np = {
                        title: result.data[0].title,
                        artist: result.data[0].artist,
                        album: result.data[0].album,
                        cover: result.data[0].coverUrl,
                    }

                    this.setState({
                        nowPlaying: np,
                    });
                },
                (error) => {
                    console.error('Failed to get queue', error);
                }
            );
    }

    getPresets(playerId) {
        fetch("/api/players/" + playerId + "/presets")
            .then(res => res.json())
            .then(                
                (result) => {                    
                    this.setState({
                        presets: result.data,
                    });
                },
                (error) => {
                    console.error('Failed to get queue', error);
                }
            );

    }

    getFavourites(playerId) {
        fetch("/api/radiofavourites")
            .then(res => res.json())
            .then(
                (result) => {
                    var objs = result.data.sort((a, b) => (a.stationName > b.stationName) ? 1 : ((b.stationName > a.stationName) ? -1 : 0))
                    this.setState({
                        radioFavourites: objs,
                    });
                },
                (error) => {
                    console.error('Failed to get radioFavourites', error);
                }
            );

    }

    handlePresetClick(url) {
        const playerId = this.props.playerID;
        const uri = encodeURIComponent(url);
        fetch("/api/players/" + playerId + "/queue/" + uri,
            { method: "POST" })
            .then(
                (result) => {
                    console.log("set preset" + url);

                },
                (error) => {
                    console.error('Failed to get set item', error);
                }
            );
    }

    handlePlayClick(status) {
        const playerId = this.props.playerID;
        const action = status === 'play' ? 'paused' : 'playing'
        fetch("/api/players/" + playerId + "/play-status",
            {
                method: "POST",
                body: '{"playStatus":"' + action + '"}'
            })
            .then(
                (result) => {
                    console.log("play changed");

                },
                (error) => {
                    console.error('Failed to change play status', error);
                }
            );

    }

    componentDidUpdate(prevProps, prevState) {

        if (prevProps.playerID !== this.props.playerID) {

            const playerId = this.props.playerID;
            const prevPlayerId = prevProps.playerID;

            if (playerId) {
                console.log("Did mount updated player");
                //this.getNowPlaying(playerId);
                this.getPresets(playerId);
                this.getFavourites(playerId);
            }
        }
    }





    componentDidMount() {
        const playerId = this.props.playerID;

        if (playerId) {
            console.log("Did mount new player");
            //   this.getNowPlaying(playerId);
            this.getPresets(playerId);
            this.getFavourites(playerId);
        }
    }

    render() {
        console.log("render");
        const meta = this.props.selectedPlayerMetaData;
        const remoteMeta = this.props.selectedPlayerMetaData ? this.props.selectedPlayerMetaData.remoteMeta : null;
        const artwork = remoteMeta && remoteMeta.artwork_url ? remoteMeta.artwork_url : '';
        const title = remoteMeta && remoteMeta.title ? remoteMeta.title : '';
        const artist = remoteMeta && remoteMeta.artist ? remoteMeta.artist : '';
        const album = remoteMeta && remoteMeta.remote_title ? remoteMeta.remote_title : (remoteMeta?.album ? remoteMeta.album : '');
        const themePalette =  this.props.themePalette;


        const duration = meta && meta.duration ? meta.duration : 1;
        const time = meta && meta.time ? meta.time : 1;
        const playStatus = meta && meta.mode ? meta.mode : '';

        const favourites = this.state.radioFavourites ? this.state.radioFavourites.slice() : [];

        const presets = this.state.presets.slice();


        const navValue = this.state.navValue;


        const viewFavourites =
            <RadioFavourites
                favourites={favourites}
                onClick={(url) => this.handlePresetClick(url)} />;

        const viewSchedule =
            <Schedule favourites={favourites}
                     themePalette={themePalette} />;


        const viewPlay =

            <Box sx={{ backgroundColor: 'background.default' }} >
                <Stack direction="column"  justifyContent="space-between" spacing={2}>

                    <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={2} >

                        <Stack direction="column" sx={{ width: 80, padding: 1 }}>
                            <PresetButtons
                                presets={presets}
                                firstPreset={0}
                                lastPreset={3}
                                onClick={(url) => this.handlePresetClick(url)} >
                            </PresetButtons>
                        </Stack>


                        <Paper sx={{ p: 1 }}>

                            <CardMedia component="img"
                                alt="Nothing"
                                image={artwork}
                                sx={{ maxHeight: 200, maxWidth: 200 }}
                            >
                            </CardMedia>

                        </Paper>
                        <Stack direction="column" sx={{ width: 80, padding: 1 }}>
                            <PresetButtons
                                presets={presets}
                                firstPreset={4}
                                lastPreset={7}
                                onClick={(url) => this.handlePresetClick(url)} >
                            </PresetButtons>
                        </Stack>

                    </Stack>

                    <Container sx={{ p: 1,  textAlign: 'Center' }}>
                        <Typography gutterBottom variant="subtitle1" component="div">
                            {title}
                        </Typography>

                        <Typography gutterBottom variant="subtitle2" component="div">
                            {artist}
                        </Typography>
                        <Typography gutterBottom variant="subtitle2" component="div">
                            {album}
                        </Typography>
                    </Container>

                    <Box sx={{ p: 1,  textAlign: 'Center' }}>
                        <MediaButtons
                            playStatus={playStatus}
                            onClick={(pStatus) => this.handlePlayClick(pStatus)} />
                    </Box>

                </Stack>
            </Box>;



        const viewNav = navValue === "player" ? viewPlay : navValue === "favourites" ? viewFavourites : viewSchedule;

        return (

            <React.Fragment>
                {viewNav}
                <Paper sx={{ position: 'fixed', bottom: 0, left: 0, right: 0, zIndex: 'top' }} elevation={3}>
                    <BottomNavigation
                        showLabels

                        value={navValue}
                        onChange={(event, newValue) => {
                            this.setState({
                                navValue: newValue
                            })
                        }}
                    >
                        <BottomNavigationAction value="player" label="Player" icon={<PlayCircleOutlineIcon />} />
                        <BottomNavigationAction value="schedule" label="EPG" icon={<ViewListIcon />} />
                        <BottomNavigationAction value="favourites" label="Radio Favourites" icon={<FavoriteIcon />} />
                    </BottomNavigation>
                </Paper>
            </React.Fragment>

        );
    }

}

export default Player;

