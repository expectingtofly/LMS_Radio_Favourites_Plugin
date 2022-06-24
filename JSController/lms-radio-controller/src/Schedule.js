import React from 'react';
import Container from '@mui/material/Container';


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
  } from "planby";


  


function RFEpg(props) {

    const channels = props.favourites.map((station) => {
        const imageurl = station.stationImage ? station.stationImage.replace("bbc_radio_fourfm", "bbc_radio_four") : null;
        return {
            logo: station.stationImage ? imageurl : station.image,
            uuid: station.url,
        }
    });

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
    d.setHours(0,0,0,0);


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
    });

    return <Epg {...getEpgProps()}>
        <Layout
            {...getLayoutProps()}
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




        const schedView = (schedule === null) || (favs === null) ?
            <div>No Shedule yet</div>
            : <RFEpg favourites={favs}
                schedule={schedule}
                isLoading = {isLoading}
            />


        return (
            <React.Fragment>
                {schedView}
            </React.Fragment>

        );
    }


}

export default Schedule;

