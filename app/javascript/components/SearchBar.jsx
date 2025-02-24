import React, { useState, useEffect } from 'react';
import { Search } from 'lucide-react';

// A more reusable SearchBar component that can work with any data
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

        const lowercaseTerm = term.toLowerCase();

        // If data is an array of objects (flat structure)
        if (Array.isArray(data)) {
            return data.filter(item =>
                keys.some(key =>
                    item[key]?.toLowerCase().includes(lowercaseTerm)
                )
            );
        }

        // If data is an object of collections (nested structure like groceries)
        if (typeof data === 'object' && data !== null) {
            return Object.entries(data).reduce((acc, [category, categoryData]) => {
                // Handle different data structures - could be object with items array
                // or other structures depending on your application
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

        // Default fallback
        return data;
    };

    return (
        <div className="relative flex-1">
            <Search
                className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={20}
            />
            <input
                type="text"
                placeholder={placeholder}
                className="w-full pl-12 pr-4 py-3 bg-gray-900/90 backdrop-blur-sm border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white placeholder-gray-400 transition-all duration-300"
                value={internalSearchTerm}
                onChange={(e) => setInternalSearchTerm(e.target.value)}
            />
        </div>
    );
};

export default SearchBar;