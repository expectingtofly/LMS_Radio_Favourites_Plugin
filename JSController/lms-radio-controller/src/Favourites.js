import React from 'react';
import Typography from '@mui/material/Typography';
import Box from '@mui/material/Box';




class Favourites extends React.Component {
    constructor(props) {
        super(props);
        this.state = {            
            favourites: [],
        }
    }

    
    componentDidUpdate(prevProps, prevState) {

        if (prevProps.playerID !== this.props.playerID) {

            const playerId = this.props.playerID;
            const prevPlayerId = prevProps.playerID;

            if (playerId) {
                console.log("Did mount updated player");
                //this.getNowPlaying(playerId);
                this.getPresets(playerId);
            }
        }
    }





    componentDidMount() {
        const playerId = this.props.playerID;

        if (playerId) {
            console.log("Did mount new player");
            //   this.getNowPlaying(playerId);
            this.getPresets(playerId);
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



        const presets = this.state.presets.slice();

        console.log("Remote Data" + ((time / duration) * 100));
        console.log(remoteMeta);
        console.log("artwork " + artwork);



        return (

            <Stack sx={{ height: 500 }}
                direction="row">
                <Stack direction="column" sx={{ width: 80, padding: 1 }}>
                    <PresetButtons
                        presets={presets}
                        firstPreset={0}
                        lastPreset={3}
                        onClick={(url) => this.handlePresetClick(url)} >
                    </PresetButtons>
                </Stack>
                <Stack direction="column" spacing={2} sx={{  padding: 1 }} >
                    <Card sx={{ height: "auto", minHeight: 400, }}>
                        <CardMedia sx={{ width: "auto", height: 4 / 10,  px: 4, py: 2, mx: "auto" }} component="img"
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
                        <Box sx={{ height: 2 / 10, alignItems: 'center', p: 1 }}>
                            <IconButton aria-label="previous">
                                <SkipPreviousIcon />
                            </IconButton>
                            <IconButton aria-label="play/pause">
                                <PlayArrowIcon sx={{ height: 38, width: 38 }} />
                            </IconButton>
                            <IconButton aria-label="next">
                                <SkipNextIcon />
                            </IconButton>
                        </Box>

                    </Card>
                </Stack>
                <Stack direction="column" sx={{ width: 80, padding: 1 }}>
                    <PresetButtons
                        presets={presets}
                        firstPreset={4}
                        lastPreset={7}
                        onClick={(url) => this.handlePresetClick(url)} >
                    </PresetButtons>
                </Stack>
            </Stack>

        );
    }

}

export default Player;

