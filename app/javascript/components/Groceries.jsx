import React, { useState } from 'react';
import { Search, ChevronDown, ChevronUp, Minimize2, Maximize2 } from 'lucide-react';

const Groceries = ({ groceryItems = {} }) => {
    const unicodeToEmoji = (unicodeString) => {
        const hex = unicodeString.replace('U+', '');
        return String.fromCodePoint(parseInt(hex, 16));
    };

    const [searchTerm, setSearchTerm] = useState('');
    const [openDrawers, setOpenDrawers] = useState(
        Object.keys(groceryItems || {}).reduce((acc, category) => ({
            ...acc,
            [category]: true
        }), {})
    );

    const handleGroceryClick = (groceryId) => {
        window.location.href = `/groceries/${groceryId}`;
    };

    const toggleDrawer = (category) => {
        setOpenDrawers(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    const toggleAll = () => {
        const areAllOpen = Object.values(openDrawers).every(Boolean);
        setOpenDrawers(
            Object.keys(groceryItems || {}).reduce((acc, category) => ({
                ...acc,
                [category]: !areAllOpen
            }), {})
        );
    };

    // Filter items while maintaining the order from display_order
    const filteredGroceryItems = Object.entries(groceryItems || {})
        .sort(([, a], [, b]) => a[0]?.display_order - b[0]?.display_order)
        .reduce((acc, [category, items]) => {
            const filteredItems = items.filter(item =>
                item?.name?.toLowerCase().includes(searchTerm.toLowerCase())
            );
            if (filteredItems.length > 0) {
                acc[category] = filteredItems;
            }
            return acc;
        }, {});

    const areAllOpen = Object.values(openDrawers).every(Boolean);

    return (
        <turbo-frame id="groceries_content">
            <div className="min-h-screen bg-black text-white relative">
                {/* Header with search */}
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        Culinary Inventory
                    </h1>
                    {Object.keys(groceryItems || {}).length > 0 && (
                        <div className="flex items-center gap-4 max-w-2xl mx-auto">
                            <div className="relative flex-1">
                                <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400"
                                        size={20}/>
                                <input
                                    type="text"
                                    placeholder="Search your collection..."
                                    className="w-full pl-12 pr-4 py-3 bg-gray-900/90 backdrop-blur-sm border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white placeholder-gray-400 transition-all duration-300"
                                    value={searchTerm}
                                    onChange={(e) => setSearchTerm(e.target.value)}
                                />
                            </div>
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
                        </div>
                    )}
                </div>

                {/* Cabinet/Shelving Layout */}
                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    {Object.keys(groceryItems || {}).length === 0 ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No groceries in your pantry yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(filteredGroceryItems).map(([category, items], categoryIndex) => (
                                <div
                                    key={category}
                                    className="bg-gray-900/90 backdrop-blur-sm border border-gray-800 rounded-lg overflow-hidden shadow-lg transition-all duration-300 animate-slide-up"
                                    style={{
                                        animationDelay: `${categoryIndex * 100}ms`
                                    }}
                                >
                                    {/* Drawer Handle */}
                                    <button
                                        onClick={() => toggleDrawer(category)}
                                        className="w-full px-6 py-4 flex items-center justify-between border-b border-gray-800 hover:bg-gray-800/50 transition-colors duration-200"
                                    >
                                        <h3>{category}</h3>
                                        {openDrawers[category] ? (
                                            <ChevronUp className="text-amber-400" size={20}/>
                                        ) : (
                                            <ChevronDown className="text-amber-400" size={20}/>
                                        )}
                                    </button>

                                    {/* Drawer Contents */}
                                    <div
                                        className={`transition-all duration-300 ease-in-out ${
                                            openDrawers[category] ? 'max-h-[500px] opacity-100' : 'max-h-0 opacity-0'
                                        } overflow-hidden`}
                                    >
                                        <div className="p-4 bg-gray-900/50">
                                            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                                                {items.map((item, itemIndex) => (
                                                    <div
                                                        key={item?.id || itemIndex}
                                                        onClick={() => handleGroceryClick(item.id)}
                                                        className="bg-gray-800/90 backdrop-blur-sm rounded-lg p-4 border border-gray-700 relative hover:border-amber-500 hover:scale-105 transition-all duration-200 animate-fade-in cursor-pointer"
                                                        style={{
                                                            animationDelay: `${(categoryIndex * 100) + (itemIndex * 50)}ms`
                                                        }}
                                                    >
                                                        <div className="flex flex-col items-center">
                                                            <span className="text-3xl mb-2">
                                                                {unicodeToEmoji(item.emoji)}
                                                            </span>
                                                            <span className="text-sm font-medium text-center text-gray-300">
                                                                {item?.name}
                                                            </span>
                                                            <div className="mt-2 px-2 py-1 bg-amber-500 text-black rounded-full text-xs font-bold">
                                                                {item?.quantity} {item?.unit}
                                                            </div>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </turbo-frame>
    );
};

export default Groceries;