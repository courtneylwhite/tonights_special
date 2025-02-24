import React from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';

const Shelf = ({
                   category,
                   items,
                   categoryIndex,
                   isOpen,
                   onToggle,
                   handleGroceryClick,
                   unicodeToEmoji
               }) => {
    // Function to handle the visibility toggle for this shelf
    const toggleShelf = () => {
        onToggle(category);
    };

    return (
        <div className="rounded-lg overflow-hidden border border-gray-800 transition-all duration-300">
            <div
                className="py-3 px-5 bg-gray-900 flex justify-between items-center cursor-pointer"
                onClick={toggleShelf}
            >
                <div className="flex items-center">
                    <h3 className="text-lg font-medium text-white">{category}</h3>
                    <span className="ml-2 text-gray-400 text-sm">
                        ({items.length} item{items.length !== 1 ? 's' : ''})
                    </span>
                </div>
                <button className="text-gray-400 hover:text-white transition-colors">
                    {isOpen ? <ChevronUp size={20} /> : <ChevronDown size={20} />}
                </button>
            </div>

            {isOpen && (
                <div className="p-4 bg-gray-800">
                    {items.length === 0 ? (
                        <p className="text-gray-400 text-center py-4">No items in this category</p>
                    ) : (
                        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3">
                            {items.map((item, index) => (
                                <div
                                    key={item.id}
                                    className="py-3 flex justify-between items-center hover:bg-gray-700/50 px-3 rounded transition-colors cursor-pointer border border-gray-700"
                                    onClick={() => handleGroceryClick(item.id)}
                                >
                                    <div className="flex items-center overflow-hidden">
                                        {item.emoji && (
                                            <span className="mr-3 text-xl flex-shrink-0" title={item.emoji}>
                                                {unicodeToEmoji(item.emoji)}
                                            </span>
                                        )}
                                        <span className="font-medium truncate">{item.name}</span>
                                    </div>
                                    <div className="text-gray-400 text-sm ml-2 flex-shrink-0">
                                        {item.quantity} {item.unit}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

export default Shelf;