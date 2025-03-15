import React, { useState, useMemo } from 'react';
import { Plus } from 'lucide-react';
import GroceryModal from './GroceryModal';
import SearchBar from '../SearchBar';
import ToggleButton from '../ToggleButton';
import ScrollableContainer from '../ScrollableContainer';

const Pantry = ({ groceries = {}, units = [] }) => {
    const [groceryData, setGroceryData] = useState(groceries);
    const [filteredGroceryData, setFilteredGroceryData] = useState(groceries);
    const [isItemModalOpen, setIsItemModalOpen] = useState(false);

    // Create initial toggle state for containers
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

    // Process the grocery sections for the GroceryModal
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

    // Define a simple emoji rendering function that will be passed to ScrollableContainer
    const renderEmoji = (emojiInput) => {
        // Default to shopping cart emoji if the input is empty
        if (!emojiInput) return '🛒';

        // Case 1: If it's already an emoji character (not starting with U+)
        if (!emojiInput.startsWith('U+')) {
            return emojiInput;
        }

        // Case 2: If it's a Unicode format (U+XXXX)
        try {
            const hex = emojiInput.replace('U+', '');
            return String.fromCodePoint(parseInt(hex, 16));
        } catch (error) {
            console.error('Error converting emoji:', error);
            return '🛒'; // Default to shopping cart emoji on error
        }
    };

    // State to track which containers are open
    const [containerToggleState, setContainerToggleState] = useState(initialToggleState);

    // Handler for when a container needs to be toggled
    const handleContainerToggle = (category) => {
        setContainerToggleState(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    return (
        <turbo-frame id="groceries_content">
            <div className="min-h-screen bg-black text-white relative">
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        Grocery Inventory
                    </h1>
                    <div className="flex items-center gap-4 max-w-3xl mx-auto">
                        <SearchBar
                            placeholder="Search your groceries..."
                            data={groceryData}
                            searchKeys={['name']}
                            onFilteredDataChange={setFilteredGroceryData}
                        />
                        <button
                            onClick={handleAddItem}
                            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                        >
                            <Plus size={18}/>
                            <span className="text-sm font-medium">Grocery</span>
                        </button>
                        <ToggleButton
                            initialToggleState={containerToggleState}
                            onToggleChange={setContainerToggleState}
                        />
                    </div>
                </div>

                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    {!hasGroceries ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No groceries in here yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(sortedFilteredGroceries).map(([category, sectionData], categoryIndex) => (
                                <ScrollableContainer
                                    key={category}
                                    category={category}
                                    items={sectionData.items}
                                    categoryIndex={categoryIndex}
                                    isOpen={containerToggleState[category]}
                                    onToggle={handleContainerToggle}
                                    handleItemClick={handleGroceryClick}
                                    renderEmoji={renderEmoji}
                                />
                            ))}
                        </div>
                    )}
                </div>

                <GroceryModal
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