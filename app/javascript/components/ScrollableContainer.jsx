import React, { useRef, useState, useEffect } from 'react';
import { ChevronDown, ChevronUp, ChevronLeft, ChevronRight, CheckCircle } from 'lucide-react';

const ScrollableContainer = ({
                                 category,
                                 items,
                                 categoryIndex,
                                 isOpen,
                                 onToggle,
                                 handleItemClick,
                                 unicodeToEmoji
                             }) => {
    const scrollContainerRef = useRef(null);
    const [showLeftArrow, setShowLeftArrow] = useState(false);
    const [showRightArrow, setShowRightArrow] = useState(false);

    // Function to handle the visibility toggle for this container
    const toggleContainer = () => {
        onToggle(category);
    };

    // Check if we need to show scroll arrows
    useEffect(() => {
        if (!scrollContainerRef.current || !isOpen) return;

        const checkScrollPosition = () => {
            const { scrollLeft, scrollWidth, clientWidth } = scrollContainerRef.current;
            setShowLeftArrow(scrollLeft > 0);
            setShowRightArrow(scrollLeft < scrollWidth - clientWidth - 10); // 10px buffer
        };

        // Check initially and when items change
        checkScrollPosition();

        // Add scroll event listener
        scrollContainerRef.current.addEventListener('scroll', checkScrollPosition);

        // Cleanup
        return () => {
            if (scrollContainerRef.current) {
                scrollContainerRef.current.removeEventListener('scroll', checkScrollPosition);
            }
        };
    }, [isOpen, items]);

    // Scroll functions
    const scrollLeft = () => {
        if (!scrollContainerRef.current) return;
        scrollContainerRef.current.scrollBy({
            left: -300,
            behavior: 'smooth'
        });
    };

    const scrollRight = () => {
        if (!scrollContainerRef.current) return;
        scrollContainerRef.current.scrollBy({
            left: 300,
            behavior: 'smooth'
        });
    };

    // Group items into columns with max 3 rows per column
    const groupItemsIntoColumns = (items) => {
        const columns = [];
        const MAX_ROWS = 3;

        for (let i = 0; i < items.length; i += MAX_ROWS) {
            columns.push(items.slice(i, i + MAX_ROWS));
        }

        return columns;
    };

    const itemColumns = groupItemsIntoColumns(items);

    return (
        <div className="rounded-lg overflow-hidden border border-gray-800 transition-all duration-300">
            <div
                className="py-3 px-5 bg-gray-900 flex justify-between items-center cursor-pointer"
                onClick={toggleContainer}
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
                <div className="p-4 bg-gray-800 relative">
                    {items.length === 0 ? (
                        <p className="text-gray-400 text-center py-4">No items in this category</p>
                    ) : (
                        <div className="relative">
                            {/* Scroll Container */}
                            <div
                                ref={scrollContainerRef}
                                className="overflow-x-auto py-2 flex gap-6 hide-scrollbar"
                                style={{
                                    scrollbarWidth: 'none',
                                    msOverflowStyle: 'none',
                                    paddingLeft: '4px',
                                    paddingRight: '4px'
                                }}
                            >
                                {itemColumns.map((column, columnIndex) => (
                                    <div key={columnIndex} className="flex-shrink-0 flex flex-col gap-2">
                                        {column.map((item) => (
                                            <div
                                                key={item.id}
                                                className="flex items-center gap-3 py-2 px-3 bg-gray-800/90 backdrop-blur-sm rounded-lg border border-gray-700 hover:border-amber-500 hover:bg-gray-700 transition-all duration-200 cursor-pointer"
                                                onClick={() => handleItemClick(item.id)}
                                                style={{
                                                    minWidth: '240px'
                                                }}
                                            >
                                                {/* Availability Indicator - only shown if can_make property exists and is true */}
                                                {item.can_make && (
                                                    <CheckCircle size={16} className="text-green-500 fill-green-500/20 flex-shrink-0" />
                                                )}

                                                {/* Emoji */}
                                                {item.emoji && (
                                                    <span className="text-xl flex-shrink-0" title={item.emoji}>
                                                        {unicodeToEmoji(item.emoji)}
                                                    </span>
                                                )}

                                                {/* Quantity Badge - for groceries */}
                                                {item.quantity && item.unit && (
                                                    <span className="px-2 py-0.5 bg-amber-500 text-black rounded-full text-xs font-bold flex-shrink-0">
                                                        {item.quantity} {item.unit}
                                                    </span>
                                                )}

                                                {/* Item Name */}
                                                <span className="font-medium text-sm text-white">
                                                    {item.name}
                                                </span>
                                            </div>
                                        ))}
                                    </div>
                                ))}
                            </div>

                            {/* Left Arrow */}
                            {showLeftArrow && (
                                <button
                                    onClick={scrollLeft}
                                    className="absolute left-0 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-gray-900/80 backdrop-blur-sm text-white flex items-center justify-center shadow-lg border border-gray-700 hover:bg-amber-500 hover:text-black transition-colors z-10"
                                    aria-label="Scroll left"
                                >
                                    <ChevronLeft size={18} />
                                </button>
                            )}

                            {/* Right Arrow */}
                            {showRightArrow && (
                                <button
                                    onClick={scrollRight}
                                    className="absolute right-0 top-1/2 -translate-y-1/2 h-8 w-8 rounded-full bg-gray-900/80 backdrop-blur-sm text-white flex items-center justify-center shadow-lg border border-gray-700 hover:bg-amber-500 hover:text-black transition-colors z-10"
                                    aria-label="Scroll right"
                                >
                                    <ChevronRight size={18} />
                                </button>
                            )}

                            {/* Optional gradient fades for scroll indication */}
                            {showLeftArrow && (
                                <div className="pointer-events-none absolute left-0 top-0 bottom-0 w-8 bg-gradient-to-r from-gray-800 to-transparent z-0" />
                            )}
                            {showRightArrow && (
                                <div className="pointer-events-none absolute right-0 top-0 bottom-0 w-8 bg-gradient-to-l from-gray-800 to-transparent z-0" />
                            )}
                        </div>
                    )}
                </div>
            )}
        </div>
    );
};

export default ScrollableContainer;