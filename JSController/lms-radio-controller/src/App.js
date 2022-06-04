import './App.css';
import React from 'react';
import Player from './Player';

import MenuItem from '@mui/material/MenuItem';
import AppBar from '@mui/material/AppBar';
import Toolbar from '@mui/material/Toolbar';
import Typography from '@mui/material/Typography';
import IconButton from '@mui/material/IconButton';
import MenuIcon from '@mui/icons-material/Menu';
import Menu from '@mui/material/Menu';
import Button from '@mui/material/Button';
import KeyboardArrowDownIcon from '@mui/icons-material/KeyboardArrowDown';
import RestoreIcon from '@mui/icons-material/Restore';
import FavoriteIcon from '@mui/icons-material/Favorite';
import ArchiveIcon from '@mui/icons-material/Archive';

import Paper from '@mui/material/Paper';
import BottomNavigation from '@mui/material/BottomNavigation';
import BottomNavigationAction from '@mui/material/BottomNavigationAction';


import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';

const _lib = require('./cometd');



function PlayerSelect(props) {
  const playerOptions = props.players.map((player, index) => {
    return (<MenuItem onClick={(event) => handleMenuItemClick(event, index)} key={player.playerID}
      selected={player.playerID === props.selectedPlayerID} value={player.playerID}>{player.name}</MenuItem>)
  });
  const [anchorEl, setAnchorEl] = React.useState(null);
  const [playerName, setPlayerName] = React.useState(null);
  const player = props.selectedPlayerID ? props.selectedPlayerID : '';
  const open = Boolean(anchorEl);

  const handleClick = (event) => {
    console.log("HandleClick " + event);
    setAnchorEl(event.currentTarget);
  };

  const handleClose = (event) => {
    console.log("It closed " + event);
    setAnchorEl(null);
    //props.onChange(event.target.value);
  };

  const handleMenuItemClick = (event, index) => {

    console.log("It closed " + index);
    props.onChange(props.players[index].playerID);
    setAnchorEl(null);
    setPlayerName(props.players[index].name);
  };

  return (
    <div>
      <Button color="inherit"
        id="player-select-button"
        aria-controls={open ? 'player-select-menu' : undefined}
        aria-haspopup="true"
        aria-expanded={open ? 'true' : undefined}
        onClick={handleClick}
        endIcon={<KeyboardArrowDownIcon />}
      >
        {playerName ? playerName : 'Select Player'}
      </Button>
      <Menu
        id="player-select-menu"
        aria-labelledby="layer-select-button"
        anchorEl={anchorEl}
        open={open}
        onClose={handleClose}
        anchorOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
        transformOrigin={{
          vertical: 'top',
          horizontal: 'left',
        }}
      >
        {playerOptions}</Menu>
    </div>
  );
}

class RadioController extends React.Component {
  constructor(props) {
    super(props);
    console.log("constructor");
    this.state = {
      players: [],
      selectedPlayer: null,
      selectedPlayerID: null,
      selectedPlayerMetaData: null,
      cometD: new _lib.CometD(),
    }
    this.havePlayers = false;
    this.firedupcometd = false;
    this.counter = 0;

  }

  cancelConnectionFailureTimer() {
    if (undefined !== this.connectionFailureTimer) {
      clearTimeout(this.connectionFailureTimer);
      this.connectionFailureTimer = undefined;
    }
  }


  scheduleNextPlayerStatusUpdate(timeout) {
    console.log("Player status update whatever that is");
  }


  fireupCometD(cometd) {
    console.log("COMETD create");

    var lmsIsConnected = undefined; // Not connected, or disconnected...    



    // Handshake with callback.
    cometd.configure({ url: '/cometd', logLevel: 'debug', maxBackoff: 10000, supportedConnectionTypes: ["long-polling"] });

    cometd.websocketEnabled = false;

    console.log("We can log here");



    cometd.addListener('/meta/handshake', (message) => {

      console.log("But not here");
      if (eval(message).successful) {
        console.log("subscribing to server status");

        cometd.subscribe('/' + cometd.getClientId() + '/**', (res) => { this.handleCometDMessage(res); });
        cometd.subscribe('/slim/subscribe',
          function (res) { },
          { data: { response: '/' + cometd.getClientId() + '/slim/serverstatus', request: ['', ['serverstatus', 0, 30, 'subscribe:60']] } });
      }
    });

    cometd.addListener('/meta/disconnect', function (message) {

      console.log("connnecting, what happened in 'ere ?");
      console.log(message);

    });


    cometd.addListener('/meta/connect', (message) => {
      console.log("connnecting, what happened?");
      var connected = eval(message).successful;

      console.log("or here");
      if (connected !== lmsIsConnected) {
        lmsIsConnected = connected;
        if (!connected) {
          this.cancelConnectionFailureTimer();
          // Delay showing red 'i' icon for 2 seconds - incase of itermittent failures
          this.connectionFailureTimer = setTimeout(function () {

            console.log("COMETD NOT connectd LMS!!")
            this.connectionFailureTimer = undefined;
          }.bind(this), 2000);
        } else {
          console.log("COMETD connectd LMS!!")
          this.scheduleNextPlayerStatusUpdate(500);
        }
      }
    });


    console.log("and here");


    console.log("also here");
    cometd.handshake();
  }

  playerUnsubscribe(cometd, id) {

    console.log("Unsubscribe: " + id);
    cometd.subscribe('/slim/subscribe', function (res) { },
      { data: { response: '/' + cometd.getClientId() + '/slim/playerstatus/' + id, request: [id, ["status", "-", 1, "subscribe:-"]] } });
  }

  playerSubscribe(cometd, id) {

    console.log("Subscribe: " + id + " Client id : " + cometd.getClientId());

    cometd.subscribe('/slim/subscribe', function (res) { },
      { data: { response: '/' + cometd.getClientId() + '/slim/playerstatus/' + id, request: [id, ["status", "-", 1, "tags:cdegiloqrstyAABKNST", "subscribe:30"]] } });

  }


  handleCometDMessage(msg) {
    console.log("COMETD Message");

    const msgType = msg.channel.indexOf('/slim/playerstatus/') > 0 ? 'player' : 'server';

    if (msgType === 'player') {
      console.log("Player status cometD");
      const metadata = msg.data;
      console.log(metadata);
      this.setState({
        selectedPlayerMetaData: metadata,
      });
    } else {
      console.log("server status cometD");
    }


  }

  componentDidMount() {
    this.counter++;
    console.log('DidMount ' + this.counter);
    if (!this.havePlayers) {
      this.havePlayers = true;

      fetch("/api/players")
        .then(res => res.json())
        .then(
          (result) => {
            console.log('got players');
            console.log(result.data);
            if (result.data) {
              this.setState({
                players: result.data,
              });
            }
            else {
              this.setState({
                players: [],
              });
            }

          },
          (error) => {
            console.error('Failed to get players', error);
          }
        );
    }
    console.log('DidMount x ' + this.counter);
    if (!this.firedupcometd) {
      this.firedupcometd = true;
      this.fireupCometD(this.state.cometD);
    }
  }

  playerChange(playerIn) {
    const player = this.state.players.find(obj => { return obj.playerID === playerIn });
    const prevPlayer = this.state.selectedPlayerID;
    if (prevPlayer) {
      this.playerUnsubscribe(this.state.cometD, prevPlayer);
    }

    this.setState({
      selectedPlayer: player,
      selectedPlayerID: playerIn,
    });
    this.playerSubscribe(this.state.cometD, playerIn);

  }


  render() {
    const players = this.state.players;
    const playerID = this.state.selectedPlayerID;
    console.log("Rendor " + this.counter);
    const playerMetaData = this.state.selectedPlayerMetaData;


    return (
    <div className="radio-controller">
      <AppBar position="static">
        <Toolbar>
          <IconButton
            size="large"
            edge="start"
            color="inherit"
            aria-label="menu"
            sx={{ mr: 2 }}
          >
            <MenuIcon />
          </IconButton>
          <Typography variant="h6" component="div" sx={{ flexGrow: 1 }}>
            Radio Controller
          </Typography>
          <PlayerSelect players={players}
            selectedPlayerID={playerID}
            onChange={(p) => this.playerChange(p)} />
        </Toolbar>
      </AppBar>
      <Player playerID={playerID}
        selectedPlayerMetaData={playerMetaData}
      />
      <Paper sx={{ position: 'fixed', bottom: 0, left: 0, right: 0 }} elevation={3}>
        <BottomNavigation
          showLabels         
        >
          <BottomNavigationAction label="Player" icon={<RestoreIcon />} />
          <BottomNavigationAction label="Radio Favourites" icon={<FavoriteIcon />} />
          <BottomNavigationAction label="Schedule" icon={<ArchiveIcon />} />
        </BottomNavigation>
      </Paper>

    </div>
    );
  }
}

function App() {
  return (
    <RadioController />
  );
}


export default App;
