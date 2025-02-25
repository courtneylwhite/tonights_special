import React, { useState, useEffect, useRef } from 'react';
import { Plus } from 'lucide-react';
import ItemModal from './ItemModal';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import Shelf from './Shelf';

const Pantry = ({ groceries = {}, units = [] }) => {
    const [groceryData, setGroceryData] = useState(groceries);
    const [filteredGroceryData, setFilteredGroceryData] = useState(groceries);
    const [isItemModalOpen, setIsItemModalOpen] = useState(false);

    // Create initial toggle state for shelves
    const initialToggleState = Object.keys(groceries || {}).reduce((acc, category) => ({
        ...acc,
        [category]: true
    }), {});
    
    const refreshData = async () => {
        try {
            const response = await fetch('/groceries', {
                headers: { 'Accept': 'application/json' }
            });
            const data = await response.json();
            setGroceryData(data);
            setFilteredGroceryData(data); // Reset filtered data when new data is loaded
        } catch (error) {
            console.error('Failed to refresh groceries:', error);
        }
    };

    const handleItemAdded = () => refreshData();
    const handleAddItem = () => setIsItemModalOpen(true);
    const handleGroceryClick = (groceryId) => {
        window.location.href = `/groceries/${groceryId}`;
    };

    // Process the grocery sections for the ItemModal
    const grocerySections = Object.entries(groceryData || {}).map(([name, data]) => ({
        id: data.id,
        name: name
    }));

    // Sort categories by display order
    const sortedFilteredGroceries = Object.entries(filteredGroceryData || {})
        .sort(([, a], [, b]) => a[0]?.display_order - b[0]?.display_order)
        .reduce((acc, [category, data]) => {
            acc[category] = data;
            return acc;
        }, {});

    const hasGroceries = Object.keys(groceryData || {}).length > 0;
    const unicodeToEmoji = (unicodeString) => {
        const hex = unicodeString.replace('U+', '');
        return String.fromCodePoint(parseInt(hex, 16));
    };

    // State to track which shelves are open
    const [shelfToggleState, setShelfToggleState] = useState(initialToggleState);

    // Handler for when a shelf needs to be toggled
    const handleShelfToggle = (category) => {
        setShelfToggleState(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    return (
        <turbo-frame id="groceries_content">
            <div className="min-h-screen bg-black text-white relative">
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        Culinary Inventory
                    </h1>
                    {hasGroceries && (
                        <div className="flex items-center gap-4 max-w-2xl mx-auto">
                            <SearchBar
                                placeholder="Search your collection..."
                                data={groceryData}
                                searchKeys={['name']}
                                onFilteredDataChange={setFilteredGroceryData}
                            />
                            <ToggleButton
                                initialToggleState={shelfToggleState}
                                onToggleChange={setShelfToggleState}
                                expandText="Expand All"
                                collapseText="Collapse All"
                            />
                        </div>
                    )}
                </div>

                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    <div className="flex justify-end mb-4 gap-4">
                        <button
                            onClick={handleAddItem}
                            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                        >
                            <Plus size={18}/>
                            <span className="text-sm font-medium">Grocery</span>
                        </button>
                    </div>

                    {!hasGroceries ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No groceries in your pantry yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(sortedFilteredGroceries).map(([category, sectionData], categoryIndex) => (
                                <Shelf
                                    key={category}
                                    category={category}
                                    items={sectionData.items}
                                    categoryIndex={categoryIndex}
                                    isOpen={shelfToggleState[category]}
                                    onToggle={handleShelfToggle}
                                    handleGroceryClick={handleGroceryClick}
                                    unicodeToEmoji={unicodeToEmoji}
                                />
                            ))}
                        </div>
                    )}
                </div>

                <ItemModal
                    isOpen={isItemModalOpen}
                    onClose={() => setIsItemModalOpen(false)}
                    grocerySections={grocerySections}
                    units={units}
                    onItemAdded={handleItemAdded}
                />
            </div>
        </turbo-frame>
    );
};

export default Pantry;