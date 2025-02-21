import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import SectionModal from './SectionModal';
import ItemModal from './ItemModal';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import Shelf from './Shelf';

const Pantry = ({ groceries = {} }) => {
    const [groceryData, setGroceryData] = useState(groceries);
    const refreshData = async () => {
        try {
            const response = await fetch('/groceries', {
                headers: {
                    'Accept': 'application/json'
                }
            });
            const data = await response.json();
            setGroceryData(data);

            // Update openShelves state with new sections
            setOpenShelves(
                Object.keys(data || {}).reduce((acc, category) => ({
                    ...acc,
                    [category]: true
                }), {})
            );
        } catch (error) {
            console.error('Failed to refresh groceries:', error);
        }
    };

    const unicodeToEmoji = (unicodeString) => {
        const hex = unicodeString.replace('U+', '');
        return String.fromCodePoint(parseInt(hex, 16));
    };
    const [searchTerm, setSearchTerm] = useState('');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isItemModalOpen, setIsItemModalOpen] = useState(false);
    const [openShelves, setOpenShelves] = useState(
        Object.keys(groceries || {}).reduce((acc, category) => ({
            ...acc,
            [category]: true
        }), {})
    );
    const handleAddSection = () => {
        setIsModalOpen(true);
    };
    const handleSectionAdded = async (newSection) => {
        await refreshData();
    };
    const handleAddItem = () => {
        setIsItemModalOpen(true);
    };
    const handleGroceryClick = (groceryId) => {
        window.location.href = `/groceries/${groceryId}`;
    };
    const toggleShelf = (category) => {
        setOpenShelves(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };
    const toggleAll = () => {
        const areAllOpen = Object.values(openShelves).every(Boolean);
        setOpenShelves(
            Object.keys(groceryData || {}).reduce((acc, category) => ({
                ...acc,
                [category]: !areAllOpen
            }), {})
        );
    };
    const filteredGroceries = Object.entries(groceryData || {})
        .sort(([, a], [, b]) => a[0]?.display_order - b[0]?.display_order)
        .reduce((acc, [category, items]) => {
            acc[category] = items.filter(item =>
                item?.name?.toLowerCase().includes(searchTerm.toLowerCase())
            );
            return acc;
        }, {});
    const areAllOpen = Object.values(openShelves).every(Boolean);

    return (
        <turbo-frame id="groceries_content">
            <div className="min-h-screen bg-black text-white relative">
                {/* Header with search */}
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        Culinary Inventory
                    </h1>
                    {Object.keys(groceryData || {}).length > 0 && (
                        <div className="flex items-center gap-4 max-w-2xl mx-auto">
                            <SearchBar
                                searchTerm={searchTerm}
                                setSearchTerm={setSearchTerm}
                            />
                            <ToggleButton
                                areAllOpen={areAllOpen}
                                toggleAll={toggleAll}
                            />
                        </div>
                    )}
                </div>

                {/* Cabinet/Shelving Layout */}
                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    <div className="flex justify-end mb-4 gap-4">
                        <button
                            onClick={handleAddSection}
                            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                        >
                            <Plus size={18}/>
                            <span className="text-sm font-medium">Section</span>
                        </button>
                        <button
                            onClick={handleAddItem}
                            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                        >
                            <Plus size={18}/>
                            <span className="text-sm font-medium">Grocery</span>
                        </button>
                    </div>

                    {Object.keys(groceryData || {}).length === 0 ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No groceries in your pantry yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(filteredGroceries).map(([category, items], categoryIndex) => (
                                <Shelf
                                    key={category}
                                    category={category}
                                    items={items}
                                    categoryIndex={categoryIndex}
                                    isOpen={openShelves[category]}
                                    onToggle={toggleShelf}
                                    handleGroceryClick={handleGroceryClick}
                                    unicodeToEmoji={unicodeToEmoji}
                                />
                            ))}
                        </div>
                    )}
                </div>

                <SectionModal
                    isOpen={isModalOpen}
                    onClose={() => setIsModalOpen(false)}
                    onSuccess={handleSectionAdded}
                />

                <ItemModal
                    isOpen={isItemModalOpen}
                    onClose={() => setIsItemModalOpen(false)}
                />
            </div>
        </turbo-frame>
    );
};

export default Pantry;