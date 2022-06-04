import React from 'react';
import Stack from '@mui/material/Stack';
import Card from '@mui/material/Card';
import CardMedia from '@mui/material/CardMedia';
import PresetButtons from './PresetButtons';
import RadioFavourites from './RadioFavourites';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';
import IconButton from '@mui/material/IconButton';
import RewindIcon from '@mui/icons-material/FastRewind';
import PlayArrowIcon from '@mui/icons-material/PlayArrow';
import PauseIcon from '@mui/icons-material/Pause';
import FastForwardIcon from '@mui/icons-material/FastForward';






function MediaButtons(props) {
    const playIcon = props.playStatus === 'play' ? <PauseIcon sx={{ height: 38, width: 38 }} /> : <PlayArrowIcon sx={{ height: 38, width: 38 }} />
    const playStatus= props.playStatus;

    return (
        <React.Fragment>
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
        </React.Fragment>
    );
}






class Player extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            nowPlaying: null,
            presets: [],
            radioFavourites: null,
        }
    }

    getNowPlaying(playerId) {
        console.log("About to call");
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

                    console.log("done now playing");
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
        fetch("/api/players/" + playerId + "/radiofavourites")
            .then(res => res.json())
            .then(
                (result) => {
                    this.setState({
                        radioFavourites: result.data,
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
            { method: "POST",
            body: '{"playStatus":"' + action + '"}'})
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
        console.log(this.props.selectedPlayerMetaData);
        const meta = this.props.selectedPlayerMetaData;
        const remoteMeta = this.props.selectedPlayerMetaData ? this.props.selectedPlayerMetaData.remoteMeta : null;
        const artwork = remoteMeta && remoteMeta.artwork_url ? remoteMeta.artwork_url : '';
        const title = remoteMeta && remoteMeta.title ? remoteMeta.title : '';
        const artist = remoteMeta && remoteMeta.artist ? remoteMeta.artist : '';
        const album = remoteMeta && remoteMeta.remote_title ? remoteMeta.remote_title : (remoteMeta?.album ? remoteMeta.album : '');


        const duration = meta && meta.duration ? meta.duration : 1;
        const time = meta && meta.time ? meta.time : 1;
        const playStatus = meta && meta.mode ? meta.mode : '';

        const favourites = this.state.radioFavourites?this.state.radioFavourites.slice():[];

        const presets = this.state.presets.slice();

        console.log("Remote Data" + ((time / duration) * 100));
        console.log(remoteMeta);
        console.log("artwork " + artwork);

        const temp =  <Stack direction="column" sx={{  width:4/10, padding: 1 }}>
        <RadioFavourites 
        favourites = {favourites}
        onClick={(url) => this.handlePresetClick(url)} />
        </Stack>



        return (             
           <React.Fragment>                
                <Stack direction="column" sx={{ width: 80, padding: 1 }}>
                    <PresetButtons
                        presets={presets}
                        firstPreset={0}
                        lastPreset={7}
                        onClick={(url) => this.handlePresetClick(url)} >
                    </PresetButtons>
                </Stack>
                <Stack direction="column" spacing={2} sx={{
                    padding: 1,
                    width : 8/10                    
                }} >
                    <Card sx={{ height: "auto", minHeight: 500, }}>
                        <CardMedia sx={{ width: "auto", height: 5 / 10, px: 4, py: 2, mx: "auto" }} component="img"
                            alt="Nothing"
                            image={artwork}>
                        </CardMedia>
                        <Box sx={{ height: 4 / 10, p: 1, border: '1px dashed grey' }}>
                            <Typography gutterBottom variant="subtitle1" component="div">
                                {title}
                            </Typography>
                            <Typography gutterBottom variant="subtitle2" component="div">
                                {artist}
                            </Typography>
                            <Typography gutterBottom variant="subtitle2" component="div">
                                {album}
                            </Typography>
                        </Box>
                        <Box sx={{ height: 1 / 10,  alignItems: 'center'  }}>
                            <MediaButtons
                                playStatus={playStatus}
                                onClick={(pStatus) => this.handlePlayClick(pStatus)} />
                        </Box>

                    </Card>
                </Stack>               
            </React.Fragment>        

        );
    }

}

export default Player;

