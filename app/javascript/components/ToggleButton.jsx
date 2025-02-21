import React from 'react';
import { Minimize2, Maximize2 } from 'lucide-react';

const ToggleButton = ({ areAllOpen, toggleAll }) => {
    return (
        <button
            onClick={toggleAll}
            className="flex items-center gap-2 px-4 py-2 bg-gray-800 hover:bg-gray-700 text-amber-400 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-500"
        >
            {areAllOpen ? (
                <>
                    <Minimize2 size={18}/>
                    <span className="text-sm font-medium">Collapse All</span>
                </>
            ) : (
                <>
                    <Maximize2 size={18}/>
                    <span className="text-sm font-medium">Expand All</span>
                </>
            )}
        </button>
    );
};

export default ToggleButton;