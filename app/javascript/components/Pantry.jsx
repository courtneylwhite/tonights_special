import React, { useState, useMemo } from 'react';
import { Plus } from 'lucide-react';
import SectionModal from './SectionModal';
import ItemModal from './ItemModal';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import Shelf from './Shelf';

const Pantry = ({ groceries = {}, units = [] }) => {
    const [groceryData, setGroceryData] = useState(groceries);
    const [searchTerm, setSearchTerm] = useState('');
    const [isModalOpen, setIsModalOpen] = useState(false);
    const [isItemModalOpen, setIsItemModalOpen] = useState(false);
    const [openShelves, setOpenShelves] = useState(
        Object.keys(groceries || {}).reduce((acc, category) => ({
            ...acc,
            [category]: true
        }), {})
    );

    const refreshData = async () => {
        try {
            const response = await fetch('/groceries', {
                headers: { 'Accept': 'application/json' }
            });
            const data = await response.json();
            setGroceryData(data);
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

    const handleSectionAdded = () => refreshData();
    const handleItemAdded = () => refreshData();
    const handleAddSection = () => setIsModalOpen(true);
    const handleAddItem = () => setIsItemModalOpen(true);
    const handleGroceryClick = (groceryId) => {
        window.location.href = `/groceries/${groceryId}`;
    };

    const toggleShelf = (category) => {
        setOpenShelves(prev => ({ ...prev, [category]: !prev[category] }));
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

    const processedData = useMemo(() => {
        const filteredGroceries = Object.entries(groceryData || {})
            .sort(([, a], [, b]) => a[0]?.display_order - b[0]?.display_order)
            .reduce((acc, [category, sectionData]) => {
                acc[category] = {
                    ...sectionData,
                    items: sectionData.items.filter(item =>
                        item?.name?.toLowerCase().includes(searchTerm.toLowerCase())
                    )
                }
                return acc;
            }, {});

        const grocerySections = Object.entries(groceryData || {}).map(([name, data]) => ({
            id: data.id,
            name: name
        }));

        return { filteredGroceries, grocerySections };
    }, [groceryData, searchTerm]);

    const areAllOpen = Object.values(openShelves).every(Boolean);
    const hasGroceries = Object.keys(groceryData || {}).length > 0;
    const unicodeToEmoji = (unicodeString) => {
        const hex = unicodeString.replace('U+', '');
        return String.fromCodePoint(parseInt(hex, 16));
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

                    {!hasGroceries ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No groceries in your pantry yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(processedData.filteredGroceries).map(([category, sectionData], categoryIndex) => (
                                <Shelf
                                    key={category}
                                    category={category}
                                    items={sectionData.items}
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
                    sections={Object.keys(groceries || {}).length}
                    onSuccess={handleSectionAdded}
                />

                <ItemModal
                    isOpen={isItemModalOpen}
                    onClose={() => setIsItemModalOpen(false)}
                    grocerySections={processedData.grocerySections}
                    units={units}
                    onItemAdded={handleItemAdded}
                />
            </div>
        </turbo-frame>
    );
};

export default Pantry;