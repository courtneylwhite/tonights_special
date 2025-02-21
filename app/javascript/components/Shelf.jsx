import React from 'react';
import { ChevronDown, ChevronUp } from 'lucide-react';
import ShelfItems from './ShelfItems';

const Shelf = ({
                   category,
                   items,
                   categoryIndex,
                   isOpen,
                   onToggle,
                   handleGroceryClick,
                   unicodeToEmoji
               }) => {
    return (
        <div
            className="bg-gray-900/90 backdrop-blur-sm border border-gray-800 rounded-lg overflow-hidden shadow-lg transition-all duration-300 animate-slide-up"
            style={{
                animationDelay: `${categoryIndex * 100}ms`
            }}
        >
            {/* Shelf Header */}
            <button
                onClick={() => onToggle(category)}
                className="w-full px-6 py-4 flex items-center justify-between border-b border-gray-800 hover:bg-gray-800/50 transition-colors duration-200"
            >
                <h3>{category}</h3>
                {isOpen ? (
                    <ChevronUp className="text-amber-400" size={20}/>
                ) : (
                    <ChevronDown className="text-amber-400" size={20}/>
                )}
            </button>

            {/* Shelf Contents */}
            <div
                className={`transition-all duration-300 ease-in-out ${
                    isOpen ? 'max-h-[500px] opacity-100' : 'max-h-0 opacity-0'
                } overflow-hidden`}
            >
                <div className="p-4 bg-gray-900/50">
                    <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                        {items.map((item, itemIndex) => (
                            <ShelfItems
                                key={item?.id || itemIndex}
                                item={item}
                                categoryIndex={categoryIndex}
                                itemIndex={itemIndex}
                                onItemClick={handleGroceryClick}
                                unicodeToEmoji={unicodeToEmoji}
                            />
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
};

export default Shelf;