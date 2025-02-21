import React, { useState } from 'react'
import { Search } from 'lucide-react'

const SearchBar = ({ searchTerm, setSearchTerm }) => {
    return (
        <div className="relative flex-1">
            <Search
                className="absolute left-4 top-1/2 transform -translate-y-1/2 text-gray-400"
                size={20}
            />
            <input
                type="text"
                placeholder="Search your collection..."
                className="w-full pl-12 pr-4 py-3 bg-gray-900/90 backdrop-blur-sm border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white placeholder-gray-400 transition-all duration-300"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
            />
        </div>
    );
};

export default SearchBar;