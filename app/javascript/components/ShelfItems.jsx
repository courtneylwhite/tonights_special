import React from 'react';

const ShelfItems = ({ item, categoryIndex, itemIndex, onItemClick, unicodeToEmoji }) => {
    return (
        <div
            key={item?.id || itemIndex}
            onClick={() => onItemClick(item.id)}
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
                    {Math.round(item?.quantity)} {item?.unit}
                </div>
            </div>
        </div>
    );
};

export default ShelfItems;