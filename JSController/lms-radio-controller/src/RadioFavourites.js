import React from 'react';
import Typography from '@mui/material/Typography';
import Avatar from '@mui/material/Avatar';
import List from '@mui/material/List';
import ListItem from '@mui/material/ListItem';
import ListItemButton from '@mui/material/ListItemButton';
import ListItemText from '@mui/material/ListItemText';
import ListItemAvatar from '@mui/material/ListItemAvatar';
import LinearProgress from '@mui/material/LinearProgress';
import Box from '@mui/material/Box';
import Badge from '@mui/material/Badge';

import { styled } from '@mui/material/styles';

const SmallAvatar = styled(Avatar)(({ theme }) => ({
    width: 25,
    height: 25,
    border: `1px solid ${theme.palette.background.paper}`,
}));

class RadioFavourites extends React.Component {

    trimstring(instring) {
        var maxLength = 60;

        if (!(instring === null) && instring.length) {
            var trimmedString = instring.substr(0, maxLength);

            if (trimmedString.length < instring.length) {
                trimmedString = trimmedString.substr(0, Math.min(trimmedString.length, trimmedString.lastIndexOf(" ")));
                trimmedString = trimmedString + "...";
                console.log(trimmedString);
            }
            return trimmedString;
        } else {

            return '';
        }

    }

    render() {

        const favourites = this.props.favourites;
        const current = Math.trunc(Date.now() / 1000);
        console.log("here are favourites");
        console.log(favourites);

        const favs = favourites.map((fav, index) => {
            const title = this.trimstring(fav.title);
            console.log(fav);
            const progress = Math.trunc(((current - fav.startTime) / (fav.endTime - fav.startTime)) * 100);
            var ds = new Date(0);
            var de = new Date(0);
            ds.setUTCSeconds(fav.startTime);
            de.setUTCSeconds(fav.endTime);

            const start = ("0" + ds.getHours()).slice(-2) + ":" + ("0" + ds.getMinutes()).slice(-2);
            const end = ("0" + de.getHours()).slice(-2) + ":" + ("0" + de.getMinutes()).slice(-2);

            const imageurl = fav.stationImage ? fav.stationImage.replace("bbc_radio_fourfm", "bbc_radio_four") : null;

            const stationImage = fav.stationImage ?
                <Badge overlap="circular" anchorOrigin={{
                    vertical: 'bottom',
                    horizontal: 'right',
                }}
                    badgeContent={
                        <SmallAvatar src={imageurl} />
                    } >
                    <Avatar sx={{ width: 75, height: 75, mr: 1 }} alt={fav.stationName} src={fav.image} />
                </Badge>
                :
                <Avatar sx={{ width: 75, height: 75, mr: 1 }} alt={fav.stationName} src={fav.image} />;

            return (
                <React.Fragment>
                    <ListItem key={'favlist' + index} sx={{ height: 100 }} alignItems="flex-start" onClick={() => this.props.onClick(fav.url)} >
                        <ListItemButton>
                            <ListItemAvatar>
                                {stationImage}
                            </ListItemAvatar>
                            <ListItemText
                                primary={fav.stationName}
                                secondary={
                                    <React.Fragment>
                                        <Typography
                                            sx={{ display: 'inline' }}
                                            component="span"
                                            variant="body2"
                                            color="text.primary"
                                        >{title}
                                        </Typography>

                                    </React.Fragment>
                                }
                            />
                        </ListItemButton>
                    </ListItem>
                    <Box key={"favbox" + index} sx={{ display: 'flex', alignItems: 'center', px:3 }}>
                        <Box key={"starttext" + index} sx={{ minWidth: 35 }}>
                            <Typography variant="body2" color="text.secondary">{start}</Typography>
                        </Box>
                        <Box key={"progress" + index} sx={{ width: '100%', ml: 1, mr: 1 }}>
                            <LinearProgress variant="determinate" value={progress} />
                        </Box>
                        <Box key={"until" + index}sx={{ minWidth: 35 }}>
                            <Typography variant="body2" color="text.secondary">{end}</Typography>
                        </Box>
                    </Box>
                </React.Fragment>

            );
        });

        return (
            <List sx={{ width: '100%', bgcolor: 'background.paper' }}>
                {favs}
            </List >
        );
    }

}

export default RadioFavourites;

