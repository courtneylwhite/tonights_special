import React, { useState, useEffect } from 'react';
// No Lucide import

const SearchBar = ({
                       placeholder = "Search...",
                       onFilteredDataChange,
                       data,
                       searchKeys = ['name'],
                       debounceTime = 300
                   }) => {
    const [searchTerm, setSearchTerm] = useState('');
    const [internalSearchTerm, setInternalSearchTerm] = useState('');

    // Debounce the search input to avoid excessive filtering
    useEffect(() => {
        const handler = setTimeout(() => {
            setSearchTerm(internalSearchTerm);
        }, debounceTime);

        return () => {
            clearTimeout(handler);
        };
    }, [internalSearchTerm, debounceTime]);

    // Filter the data whenever searchTerm changes
    useEffect(() => {
        if (!data) return;

        const filteredData = filterData(data, searchTerm, searchKeys);
        onFilteredDataChange(filteredData);
    }, [searchTerm, data, searchKeys, onFilteredDataChange]);

    // Generic filtering function that can work with different data structures
    const filterData = (data, term, keys) => {
        if (!term.trim()) return data;

        // Rest of your filter function...
        const lowercaseTerm = term.toLowerCase();

        if (Array.isArray(data)) {
            return data.filter(item =>
                keys.some(key =>
                    item[key]?.toLowerCase().includes(lowercaseTerm)
                )
            );
        }

        if (typeof data === 'object' && data !== null) {
            return Object.entries(data).reduce((acc, [category, categoryData]) => {
                if (Array.isArray(categoryData)) {
                    const filteredItems = categoryData.filter(item =>
                        keys.some(key =>
                            item[key]?.toLowerCase().includes(lowercaseTerm)
                        )
                    );

                    if (filteredItems.length > 0) {
                        acc[category] = filteredItems;
                    }
                } else if (categoryData.items && Array.isArray(categoryData.items)) {
                    const filteredItems = categoryData.items.filter(item =>
                        keys.some(key =>
                            item[key]?.toLowerCase().includes(lowercaseTerm)
                        )
                    );

                    if (filteredItems.length > 0) {
                        acc[category] = {
                            ...categoryData,
                            items: filteredItems
                        };
                    }
                }

                return acc;
            }, {});
        }

        return data;
    };

    // Clear the search input
    const handleClearSearch = () => {
        setInternalSearchTerm('');
        setSearchTerm('');
    };

    // Create a base64 encoded SVG for the search icon - amber color
    const searchIconBase64 = btoa(`
        <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="#fbbf24" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <circle cx="11" cy="11" r="8"></circle>
            <line x1="21" y1="21" x2="16.65" y2="16.65"></line>
        </svg>
    `);

    // Create a base64 encoded SVG for the X icon - amber color
    const clearIconBase64 = btoa(`
        <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="#fbbf24" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
            <line x1="18" y1="6" x2="6" y2="18"></line>
            <line x1="6" y1="6" x2="18" y2="18"></line>
        </svg>
    `);

    return (
        <div className="relative flex-1">
            <input
                type="text"
                placeholder={placeholder}
                className="w-full pl-12 pr-10 py-3 bg-gray-900/90 backdrop-blur-sm border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white placeholder-gray-400 transition-all duration-300"
                value={internalSearchTerm}
                onChange={(e) => setInternalSearchTerm(e.target.value)}
                style={{
                    backgroundImage: `url('data:image/svg+xml;base64,${searchIconBase64}')`,
                    backgroundRepeat: 'no-repeat',
                    backgroundPosition: '16px center',
                    backgroundSize: '20px'
                }}
            />

            {/* Clear button - only shown when there's text */}
            {internalSearchTerm && (
                <button
                    onClick={handleClearSearch}
                    className="absolute right-3 top-1/2 transform -translate-y-1/2 h-6 w-6 rounded-full bg-gray-800 hover:bg-gray-700 transition-colors duration-200 flex items-center justify-center"
                    aria-label="Clear search"
                    type="button"
                    style={{
                        backgroundImage: `url('data:image/svg+xml;base64,${clearIconBase64}')`,
                        backgroundRepeat: 'no-repeat',
                        backgroundPosition: 'center',
                        backgroundSize: '14px'
                    }}
                >
                </button>
            )}
        </div>
    );
};

export default SearchBar;