import React from 'react';
import './RingtoneItem.css';

const RingtoneItem = ({ name, url, isActive, onClick }) => {
    return (
        <div 
            className={`ringtone-item ${isActive ? 'active' : ''}`}
            onClick={onClick}
        >
            <div className="ringtone-info">
                <div className="ringtone-name">{name}</div>
                <div className="ringtone-url">{url.substring(0, 40)}{url.length > 40 ? '...' : ''}</div>
            </div>
            <div className="ringtone-status">
                {isActive && (
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                        <path d="M5 12L10 17L19 8" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"/>
                    </svg>
                )}
            </div>
        </div>
    );
};

export default RingtoneItem;