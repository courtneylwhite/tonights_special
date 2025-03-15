import React, { useMemo, useState, useRef, useEffect } from 'react';
import { ChevronUp, ChevronDown, Edit } from 'lucide-react';

/**
 * GroceryViewer component - displays a grocery item in read-only mode
 */
const GroceryViewer = ({
                           grocery,
                           borderClass,
                           onEdit,
                           onIncrement,
                           onDecrement,
                           onQuantityChange
                       }) => {
    // State for the quantity input
    const [quantityInput, setQuantityInput] = useState(grocery.quantity);
    // State to track if the input is focused
    const [isInputFocused, setIsInputFocused] = useState(false);
    // Ref to store the timeout ID for auto-save
    const autoSaveTimeoutRef = useRef(null);

    // Simplified renderEmoji function for GroceryViewer
    const renderEmoji = useMemo(() => {
        // Default to shopping cart emoji if the input is empty
        if (!grocery.emoji) return '🛒';

        // Case 1: If it's already an emoji character (not starting with U+)
        if (!grocery.emoji.startsWith('U+')) {
            return grocery.emoji;
        }

        // Case 2: If it's a Unicode format (U+XXXX)
        try {
            const hex = grocery.emoji.replace('U+', '');
            return String.fromCodePoint(parseInt(hex, 16));
        } catch (error) {
            console.error('Error converting emoji:', error);
            return '🛒'; // Default to shopping cart emoji on error
        }
    }, [grocery.emoji]);

    // Format unit name based on quantity
    const formattedUnitName = useMemo(() => {
        if (!grocery.unit) return '';
        return grocery.quantity > 1 ? `${grocery.unit.name}s` : grocery.unit.name;
    }, [grocery.quantity, grocery.unit]);

    // Handler for input change
    const handleInputChange = (e) => {
        // Allow only numbers and decimals
        const value = e.target.value;
        if (value === '' || /^[0-9]*\.?[0-9]*$/.test(value)) {
            setQuantityInput(value);

            // Clear any existing timeout to avoid multiple saves
            if (autoSaveTimeoutRef.current) {
                clearTimeout(autoSaveTimeoutRef.current);
            }

            // Set a new timeout to save after 800ms of no typing
            autoSaveTimeoutRef.current = setTimeout(() => {
                const parsedValue = value === '' ? 0 : parseFloat(value);
                if (parsedValue !== grocery.quantity) {
                    onQuantityChange(parsedValue);
                    // Blur the input field to remove focus after saving
                    document.activeElement.blur();
                }
            }, 800);
        }
    };

    // Handler for input blur
    const handleInputBlur = () => {
        setIsInputFocused(false);

        // Clear any pending timeout
        if (autoSaveTimeoutRef.current) {
            clearTimeout(autoSaveTimeoutRef.current);
            autoSaveTimeoutRef.current = null;
        }

        // Save on blur as a fallback
        const parsedValue = quantityInput === '' ? 0 : parseFloat(quantityInput);
        if (parsedValue !== grocery.quantity) {
            onQuantityChange(parsedValue);
        }
    };

    // Handler for input focus
    const handleInputFocus = () => {
        setIsInputFocused(true);
    };

    // Handler for keyboard input
    const handleKeyDown = (e) => {
        if (e.key === 'Enter') {
            e.target.blur(); // Trigger the blur event to save
        }
    };

    // Update local state when grocery prop changes
    useEffect(() => {
        setQuantityInput(grocery.quantity);
    }, [grocery.quantity]);

    // Clean up timeout on unmount
    useEffect(() => {
        return () => {
            if (autoSaveTimeoutRef.current) {
                clearTimeout(autoSaveTimeoutRef.current);
            }
        };
    }, []);

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
                        {renderEmoji}
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

                        <div className="bg-gray-800 px-2 py-1 rounded-lg border border-gray-700 min-w-[100px] text-center">
                            <input
                                id="quantity-input"
                                type="text"
                                value={quantityInput}
                                onChange={handleInputChange}
                                onBlur={handleInputBlur}
                                onFocus={handleInputFocus}
                                onKeyDown={handleKeyDown}
                                className="bg-gray-800 text-2xl font-bold text-center w-full outline-none"
                                aria-label="Quantity"
                            />
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