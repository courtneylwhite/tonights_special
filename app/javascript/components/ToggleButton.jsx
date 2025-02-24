import React from 'react';
import { Minimize2, Maximize2 } from 'lucide-react';

const ToggleButton = ({
                          // Toggle state - should be managed by parent component
                          initialToggleState,

                          // Callback when toggle states change
                          onToggleChange,

                          // Button text customization
                          expandText = "Expand All",
                          collapseText = "Collapse All",

                          // Button styling options
                          buttonClassName = "flex items-center gap-2 px-4 py-2 bg-gray-800 hover:bg-gray-700 text-amber-400 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-500",

                          // Icon customization
                          expandIcon = Maximize2,
                          collapseIcon = Minimize2,
                          iconSize = 18
                      }) => {
    // Calculate if all items are open
    const areAllOpen = () => {
        if (Array.isArray(initialToggleState)) {
            return initialToggleState.every(Boolean);
        } else if (typeof initialToggleState === 'object' && initialToggleState !== null) {
            return Object.values(initialToggleState).every(Boolean);
        }
        return !!initialToggleState; // Handle single boolean case
    };

    // Toggle all items
    const toggleAll = () => {
        const allOpen = areAllOpen();
        let newState;

        if (Array.isArray(initialToggleState)) {
            newState = initialToggleState.map(() => !allOpen);
        } else if (typeof initialToggleState === 'object' && initialToggleState !== null) {
            newState = Object.keys(initialToggleState).reduce((acc, key) => {
                acc[key] = !allOpen;
                return acc;
            }, {});
        } else {
            // Single toggle case
            newState = !initialToggleState;
        }

        if (onToggleChange) onToggleChange(newState);
    };

    // Determine current state to show appropriate UI
    const allOpen = areAllOpen();
    const ExpandIcon = expandIcon;
    const CollapseIcon = collapseIcon;

    return (
        <button
            onClick={toggleAll}
            className={buttonClassName}
        >
            {allOpen ? (
                <>
                    <CollapseIcon size={iconSize}/>
                    <span className="text-sm font-medium">{collapseText}</span>
                </>
            ) : (
                <>
                    <ExpandIcon size={iconSize}/>
                    <span className="text-sm font-medium">{expandText}</span>
                </>
            )}
        </button>
    );
};

export default ToggleButton;