import React, { useMemo } from 'react';
import { ChevronUp, ChevronDown, Edit } from 'lucide-react';

/**
 * GroceryViewer component - displays a grocery item in read-only mode
 */
const GroceryViewer = ({
                           grocery,
                           borderClass,
                           onEdit,
                           onIncrement,
                           onDecrement
                       }) => {
    // Convert Unicode string to emoji
    const unicodeToEmoji = useMemo(() => {
        if (!grocery.emoji) return '❓';
        try {
            const hex = grocery.emoji.replace('U+', '');
            return String.fromCodePoint(parseInt(hex, 16));
        } catch (error) {
            console.error('Error converting unicode to emoji:', error);
            return '❓';
        }
    }, [grocery.emoji]);

    // Format unit name based on quantity
    const formattedUnitName = useMemo(() => {
        if (!grocery.unit) return '';
        return grocery.quantity > 1 ? `${grocery.unit.name}s` : grocery.unit.name;
    }, [grocery.quantity, grocery.unit]);

    return (
        <div className="p-8">
            {/* Main Grocery Card */}
            <div className={`bg-gray-900/90 backdrop-blur-sm rounded-2xl p-8 shadow-xl transition-all duration-300 ${borderClass}`}>
                {/* Name */}
                <h1 className="text-2xl font-bold text-center mb-8 text-amber-400">
                    {grocery.name}
                </h1>

                {/* Emoji */}
                <div className="text-center mb-8">
                    <span className="text-8xl inline-block transform hover:scale-110 transition-transform duration-200">
                        {unicodeToEmoji}
                    </span>
                </div>

                {/* Section */}
                <div className="text-center mb-6 text-gray-400">
                    <p>Section: {grocery.grocery_section?.name || 'Uncategorized'}</p>
                </div>

                {/* Quantity Controls */}
                <div className="flex flex-col items-center">
                    <div className="flex items-center gap-4 mb-2">
                        <button
                            onClick={onDecrement}
                            className="p-2 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-700 hover:border-amber-500 transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                            disabled={grocery.quantity <= 0}
                            aria-label="Decrease quantity"
                        >
                            <ChevronDown className="text-amber-400" size={24} />
                        </button>

                        <div className="bg-gray-800 px-6 py-3 rounded-lg border border-gray-700 min-w-[100px] text-center">
                            <span className="text-2xl font-bold">{Math.round(grocery.quantity)}</span>
                        </div>

                        <button
                            onClick={onIncrement}
                            className="p-2 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-700 hover:border-amber-500 transition-colors duration-200"
                            aria-label="Increase quantity"
                        >
                            <ChevronUp className="text-amber-400" size={24} />
                        </button>
                    </div>

                    {/* Unit */}
                    <div className="text-gray-400 text-sm">
                        {formattedUnitName}
                    </div>
                </div>
            </div>

            {/* Edit button at the bottom, similar to RecipeViewer */}
            <div className="mt-8 text-center">
                <button
                    onClick={onEdit}
                    className="inline-flex items-center px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-amber-400 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-500"
                >
                    <Edit size={18} className="mr-1" />
                    Edit Grocery
                </button>
            </div>
        </div>
    );
};

export default React.memo(GroceryViewer);