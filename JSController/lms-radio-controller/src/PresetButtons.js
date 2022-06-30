import React from 'react';
import Stack from '@mui/material/Stack';
import Button from '@mui/material/Button';
import Tooltip from '@mui/material/Tooltip';

class PresetButtons extends React.Component {

    render() {

        const presets = this.props.presets.slice(this.props.firstPreset, this.props.lastPreset + 1);

        console.log(presets);

        const buttons = presets.map((preset, index) => {
            if (preset?.URL) {
                return (<Tooltip key={"psettip" + (this.props.firstPreset + index) + 1} title={preset.text}><Button key={"psetbtn" + (this.props.firstPreset + index) + 1} variant="contained" onClick={() => this.props.onClick(preset.URL)}>{(this.props.firstPreset + index) + 1}</Button></Tooltip>)
            } else {
                return (<Button key={"psetbtn" + (this.props.firstPreset + index) + 1} variant="outlined" disabled >{(this.props.firstPreset + index) + 1}</Button>)
            }
        });


        return (

            <Stack direction="column" spacing={2}>
                {buttons}
            </Stack>

        );
    }
}

export default PresetButtons;

