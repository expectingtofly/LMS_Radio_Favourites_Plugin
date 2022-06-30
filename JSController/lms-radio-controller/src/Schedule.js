import React from 'react';
import Container from '@mui/material/Container';
import Avatar from '@mui/material/Avatar';


import {
    useEpg,
    Epg,
    Layout,
    ProgramBox,
    ProgramContent,
    ProgramFlex,
    ProgramStack,
    ProgramTitle,
    ProgramText,
    ProgramImage,
    useProgram,
    Program,
    ProgramItem,
} from "planby";


const Item = ({ program, ...rest }: ProgramItem) => {
    const { styles, formatTime, isLive, isMinWidth } = useProgram({ program, ...rest });

    const { data } = program;
    const { image, title, since, till } = data;

    const sinceTime = formatTime(since);
    const tillTime = formatTime(till);

    return (
        <ProgramBox width={styles.width} style={styles.position}>
            <ProgramContent
                width={styles.width}
                isLive={isLive}
            >
                <ProgramFlex>
                    {isMinWidth && <Avatar sx={{ width: 56, height: 56, mr: 1 }} alt="Preview" src={image} /> }
                    <ProgramStack>
                        <ProgramTitle>{title}</ProgramTitle>
                        <ProgramText>
                            {sinceTime} - {tillTime}
                        </ProgramText>
                    </ProgramStack>
                </ProgramFlex>
            </ProgramContent>
        </ProgramBox>
    );
};



function RFEpg(props) {

    const channels = props.favourites.map((station) => {
        const imageurl = station.stationImage ? station.stationImage.replace("bbc_radio_fourfm", "bbc_radio_four") : null;
        return {
            logo: station.stationImage ? imageurl : station.image,
            uuid: station.url,
        }
    });

    const inTheme = props.theme;

    const mainepg =
        props.schedule.flatMap((station) => {
            const url = station.station;
            return station.schedule.map((schedule, index) => {

                return {
                    channelUuid: url,
                    description: schedule.title2,
                    id: url + index,
                    image: schedule.image,
                    since: schedule.start,
                    till: schedule.end,
                    title: schedule.title1,
                }

            });

        });

    const nowEPG =
        props.favourites.map((station, index) => {
            return {
                channelUuid: station.url,
                description: station.description,
                id: station.url + index,
                image: station.image,
                since: new Date(station.startTime * 1000).toJSON(),
                till: new Date(station.endTime * 1000).toJSON(),
                title: station.title,
            }
        });

    const stationsInSched = props.schedule.map((station) => {
        return station.station;
    });


    const epg = mainepg.concat(nowEPG.filter(function (el) {
        return !stationsInSched.includes(el.channelUuid);
    }));


    var d = new Date();
    d.setHours(0, 0, 0, 0);


    const {
        getEpgProps,
        getLayoutProps,
        onScrollToNow,
        onScrollLeft,
        onScrollRight,
    } = useEpg({
        epg,
        channels,
        startDate: d.toJSON(),
        theme: inTheme,
        sidebarWidth: 64,
    });

    return <Epg {...getEpgProps()}>
        <Layout
            {...getLayoutProps()}
            renderProgram={({ program, ...rest }) => (
                <Item key={program.data.id} program={program} {...rest} />
            )}
        />
    </Epg>


}


class Schedule extends React.Component {
    constructor(props) {
        super(props);
        this.state = {
            daySelected: 0,
            schedule: null,
            isLoading: true,
        }
    }


    getDateForSchedule(inD) {

        var datestring = inD.getFullYear() + "-" + ("0" + (inD.getMonth() + 1)).slice(-2) + "-" + ("0" + inD.getDate()).slice(-2);

        return datestring;
    }


    getSchedule(inD) {

        const d = this.getDateForSchedule(inD);
        console.log("About to call " + d);
        fetch("/api/radiofavourites/schedules/" + d)
            .then(res => res.json())
            .then(
                (result) => {
                    console.log("done schedule");
                    console.log(result.data);

                    this.setState({
                        schedule: result.data,
                        isLoading: false,
                    });
                },
                (error) => {
                    console.error('Failed to get schedule', error);
                }
            );
    }

    componentDidMount() {
        const schedule = this.state.schedule;

        if (schedule === null) {
            console.log("Getting Schedule")

            this.getSchedule(new Date());
        }
    }


    render() {

        const schedule = this.state.schedule;
        const favs = this.props.favourites;
        const isLoading = this.state.isLoading;
        const themePalette = this.props.themePalette;
        console.log('theme');
        console.log(themePalette);

        const theme = {
            primary: {
                600: "#F7FAFC",
                900: "#CBD5E0"
            },
            grey: {
                300: "#2D3748"
            },
            white: "#1A202C",
            green: {
                300: "#2c7a7b"
            },
            scrollbar: {
                border: "#171923",
                thumb: {
                    bg: "#718096"
                }
            },
            loader: {
                teal: "#5DDADB",
                purple: "#3437A2",
                pink: "#F78EB6",
                bg: "#171923db"
            },
            gradient: {
                blue: {
                    300: "#A0AEC0",
                    600: "#E2E8F0",
                    900: "#A0AEC0"
                }
            },
            text: {
                grey: {
                    300: "#2D3748",
                    500: "#1A202C"
                }
            },
            timeline: {
                divider: {
                    bg: "#1A202C"
                }
            }
        };
        /*
               const realtheme=   {
                    "mode": "light",
                    "common": {
                        "black": "#000",
                        "white": "#fff"
                    },
                    "primary": {
                        "main": "#1976d2",
                        "light": "#42a5f5",
                        "dark": "#1565c0",
                        "contrastText": "#fff"
                    },
                    "secondary": {
                        "main": "#9c27b0",
                        "light": "#ba68c8",
                        "dark": "#7b1fa2",
                        "contrastText": "#fff"
                    },
                    "error": {
                        "main": "#d32f2f",
                        "light": "#ef5350",
                        "dark": "#c62828",
                        "contrastText": "#fff"
                    },
                    "warning": {
                        "main": "#ed6c02",
                        "light": "#ff9800",
                        "dark": "#e65100",
                        "contrastText": "#fff"
                    },
                    "info": {
                        "main": "#0288d1",
                        "light": "#03a9f4",
                        "dark": "#01579b",
                        "contrastText": "#fff"
                    },
                    "success": {
                        "main": "#2e7d32",
                        "light": "#4caf50",
                        "dark": "#1b5e20",
                        "contrastText": "#fff"
                    },
                    "grey": {
                        "50": "#fafafa",
                        "100": "#f5f5f5",
                        "200": "#eeeeee",
                        "300": "#e0e0e0",
                        "400": "#bdbdbd",
                        "500": "#9e9e9e",
                        "600": "#757575",
                        "700": "#616161",
                        "800": "#424242",
                        "900": "#212121",
                        "A100": "#f5f5f5",
                        "A200": "#eeeeee",
                        "A400": "#bdbdbd",
                        "A700": "#616161"
                    },
                    "contrastThreshold": 3,
                    "tonalOffset": 0.2,
                    "text": {
                        "primary": "rgba(0, 0, 0, 0.87)",
                        "secondary": "rgba(0, 0, 0, 0.6)",
                        "disabled": "rgba(0, 0, 0, 0.38)"
                    },
                    "divider": "rgba(0, 0, 0, 0.12)",
                    "background": {
                        "paper": "#fff",
                        "default": "#fff"
                    },
                    "action": {
                        "active": "rgba(0, 0, 0, 0.54)",
                        "hover": "rgba(0, 0, 0, 0.04)",
                        "hoverOpacity": 0.04,
                        "selected": "rgba(0, 0, 0, 0.08)",
                        "selectedOpacity": 0.08,
                        "disabled": "rgba(0, 0, 0, 0.26)",
                        "disabledBackground": "rgba(0, 0, 0, 0.12)",
                        "disabledOpacity": 0.38,
                        "focus": "rgba(0, 0, 0, 0.12)",
                        "focusOpacity": 0.12,
                        "activatedOpacity": 0.12
                    }
                }
        
                */




        const schedView = (schedule === null) || (favs === null) ?
            <div>No Shedule yet</div>
            : <RFEpg favourites={favs}
                schedule={schedule}
                isLoading={isLoading}
                theme={theme}
            />
        console.log('Is theme here?');
        console.log(themePalette);


        return (
            <Container sx={{
                bgcolor: 'background.paper',
                position: 'relative',
                maxHeight: 550,
            }}>
                {schedView}
            </Container>

        );
    }


}

export default Schedule;

