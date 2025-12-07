import React from 'react';
import './VolumeSlider.css';

const VolumeSlider = ({ value, onChange }) => {
    const handleChange = (e) => {
        onChange(parseFloat(e.target.value));
    };
    
    return (
        <div className="volume-slider-container">
            <input
                type="range"
                min="0"
                max="1"
                step="0.1"
                value={value}
                onChange={handleChange}
                className="volume-slider"
            />
            <div className="volume-indicators">
                <span>0%</span>
                <span>50%</span>
                <span>100%</span>
            </div>
        </div>
    );
};

export default VolumeSlider;