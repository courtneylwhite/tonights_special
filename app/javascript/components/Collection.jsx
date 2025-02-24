import React, { useState, useEffect } from 'react';
import { Plus } from 'lucide-react';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import Shelf from './Shelf';

const Collection = ({
                        // Core data props
                        data = {},                           // The collection data organized by categories
                        title = "Collection",                // Title displayed at the top

                        // Configuration props
                        searchKeys = ['name'],               // Which item properties to search
                        sortKey = 'display_order',           // Property to sort categories by

                        // Custom handlers
                        onItemClick,                         // Function to handle item clicks
                        onAddItem,                           // Function to handle add item button clicks
                        refreshData,                         // Function to refresh data from API

                        // Customization props
                        addButtonText = "Add Item",          // Text for the add button
                        emptyCollectionText = "No items in this collection yet.",
                        headerClassName = "bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10",
                        bodyClassName = "max-w-5xl mx-auto p-6 relative z-0",
                        frameId,                             // Optional turbo-frame ID

                        // Optional emoji conversion function
                        emojiConverter,

                        // Optional element renderers for customization
                        renderHeader,                        // Custom header renderer
                        renderAddButton,                     // Custom add button renderer

                        // Additional props to be passed to child components
                        itemModalProps,                      // Props for ItemModal if used
                        children                             // Additional content to render
                    }) => {
    const [collectionData, setCollectionData] = useState(data);
    const [filteredData, setFilteredData] = useState(data);

    // Create initial toggle state for sections
    const initialToggleState = Object.keys(data || {}).reduce((acc, category) => ({
        ...acc,
        [category]: true
    }), {});

    // State to track which sections are open
    const [sectionToggleState, setSectionToggleState] = useState(initialToggleState);

    // Update data when props change
    useEffect(() => {
        setCollectionData(data);
        setFilteredData(data);

        // Update toggle state for any new categories
        setSectionToggleState(prev => {
            const newState = { ...prev };
            Object.keys(data || {}).forEach(category => {
                if (newState[category] === undefined) {
                    newState[category] = true;
                }
            });
            return newState;
        });
    }, [data]);

    // Handler for toggling a section
    const handleSectionToggle = (category) => {
        setSectionToggleState(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    // Sort categories by the provided sort key
    const sortedFilteredData = Object.entries(filteredData || {})
        .sort(([, a], [, b]) => {
            // Handle cases where the sort key might be nested
            const valueA = sortKey.includes('.')
                ? sortKey.split('.').reduce((obj, key) => obj?.[key], a)
                : a[sortKey];

            const valueB = sortKey.includes('.')
                ? sortKey.split('.').reduce((obj, key) => obj?.[key], b)
                : b[sortKey];

            return valueA - valueB;
        })
        .reduce((acc, [category, data]) => {
            acc[category] = data;
            return acc;
        }, {});

    const hasItems = Object.keys(collectionData || {}).length > 0;

    // Default emoji converter if none provided
    const defaultEmojiConverter = (unicodeString) => {
        if (!unicodeString) return '';
        const hex = unicodeString.replace('U+', '');
        return String.fromCodePoint(parseInt(hex, 16));
    };

    // Use provided emoji converter or default
    const unicodeToEmoji = emojiConverter || defaultEmojiConverter;

    // Default add button renderer
    const defaultAddButton = () => (
        <button
            onClick={onAddItem}
            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
        >
            <Plus size={18}/>
            <span className="text-sm font-medium">{addButtonText}</span>
        </button>
    );

    // Default header renderer
    const defaultHeader = () => (
        <div className={headerClassName}>
            <h1 className="text-center mb-8">
                {title}
            </h1>
            {hasItems && (
                <div className="flex items-center gap-4 max-w-2xl mx-auto">
                    <SearchBar
                        placeholder={`Search ${title.toLowerCase()}...`}
                        data={collectionData}
                        searchKeys={searchKeys}
                        onFilteredDataChange={setFilteredData}
                    />
                    <ToggleButton
                        initialToggleState={sectionToggleState}
                        onToggleChange={setSectionToggleState}
                        expandText="Expand All"
                        collapseText="Collapse All"
                    />
                </div>
            )}
        </div>
    );

    // Wrap content in a turbo-frame if frameId is provided
    const content = (
        <div className="min-h-screen bg-black text-white relative">
            {renderHeader ? renderHeader() : defaultHeader()}

            <div className={bodyClassName}>
                {onAddItem && (
                    <div className="flex justify-end mb-4 gap-4">
                        {renderAddButton ? renderAddButton() : defaultAddButton()}
                    </div>
                )}

                {!hasItems ? (
                    <div className="text-center text-gray-400 py-12">
                        <p>{emptyCollectionText}</p>
                    </div>
                ) : (
                    <div className="space-y-4">
                        {Object.entries(sortedFilteredData).map(([category, sectionData], categoryIndex) => (
                            <Shelf
                                key={category}
                                category={category}
                                items={sectionData.items}
                                categoryIndex={categoryIndex}
                                isOpen={sectionToggleState[category]}
                                onToggle={handleSectionToggle}
                                handleGroceryClick={onItemClick}
                                unicodeToEmoji={unicodeToEmoji}
                            />
                        ))}
                    </div>
                )}

                {children}
            </div>
        </div>
    );

    return frameId ? (
        <turbo-frame id={frameId}>
            {content}
        </turbo-frame>
    ) : content;
};

export default Collection;