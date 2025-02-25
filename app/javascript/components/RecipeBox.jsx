import React, { useState, useEffect, useRef } from 'react';
import { Plus } from 'lucide-react';
import ItemModal from './ItemModal';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import Shelf from './Shelf';

const RecipeBox = ({ recipes = {}, units = [] }) => {
    const [recipeData, setRecipeData] = useState(recipes);
    const [filteredRecipeData, setFilteredRecipeData] = useState(recipes);
    const [isItemModalOpen, setIsItemModalOpen] = useState(false);

    // Create initial toggle state for shelves
    const initialToggleState = Object.keys(recipes || {}).reduce((acc, category) => ({
        ...acc,
        [category]: true
    }), {});

    const refreshData = async () => {
        try {
            const response = await fetch('/recipes', {
                headers: { 'Accept': 'application/json' }
            });
            const data = await response.json();
            setRecipeData(data);
            setFilteredRecipeData(data); // Reset filtered data when new data is loaded
        } catch (error) {
            console.error('Failed to refresh recipes:', error);
        }
    };

    const handleItemAdded = () => refreshData();
    const handleAddItem = () => setIsItemModalOpen(true);
    const handleRecipeClick = (recipeId) => {
        window.location.href = `/recipes/${recipeId}`;
    };

    // Process the recipe sections for the ItemModal
    const recipeSections = Object.entries(recipeData || {}).map(([name, data]) => ({
        id: data.id,
        name: name
    }));

    // Sort categories by display order
    const sortedFilteredRecipes = Object.entries(filteredRecipeData || {})
        .sort(([, a], [, b]) => a[0]?.display_order - b[0]?.display_order)
        .reduce((acc, [category, data]) => {
            acc[category] = data;
            return acc;
        }, {});

    const hasRecipes = Object.keys(recipeData || {}).length > 0;
    const unicodeToEmoji = (unicodeString) => {
        const hex = unicodeString.replace('U+', '');
        return String.fromCodePoint(parseInt(hex, 16));
    };

    // State to track which shelves are open
    const [shelfToggleState, setShelfToggleState] = useState(initialToggleState);

    // Handler for when a shelf needs to be toggled
    const handleShelfToggle = (category) => {
        setShelfToggleState(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    return (
        <turbo-frame id="recipes_content">
            <div className="min-h-screen bg-black text-white relative">
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        Recipes
                    </h1>
                    {hasRecipes && (
                        <div className="flex items-center gap-4 max-w-3xl mx-auto">
                            <SearchBar
                                placeholder="Search your collection..."
                                data={recipeData}
                                searchKeys={['name']}
                                onFilteredDataChange={setFilteredRecipeData}
                            />
                            <button
                                onClick={handleAddItem}
                                className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                            >
                                <Plus size={18}/>
                                <span className="text-sm font-medium">Recipe</span>
                            </button>
                            <ToggleButton
                                initialToggleState={shelfToggleState}
                                onToggleChange={setShelfToggleState}
                            />
                        </div>
                    )}
                </div>

                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    {!hasRecipes ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No recipes in your recipe box yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(sortedFilteredRecipes).map(([category, sectionData], categoryIndex) => (
                                <Shelf
                                    key={category}
                                    category={category}
                                    items={sectionData.items}
                                    categoryIndex={categoryIndex}
                                    isOpen={shelfToggleState[category]}
                                    onToggle={handleShelfToggle}
                                    handleRecipeClick={handleRecipeClick}
                                    unicodeToEmoji={unicodeToEmoji}
                                />
                            ))}
                        </div>
                    )}
                </div>

                <ItemModal
                    isOpen={isItemModalOpen}
                    onClose={() => setIsItemModalOpen(false)}
                    recipeSections={recipeSections}
                    units={units}
                    onItemAdded={handleItemAdded}
                />
            </div>
        </turbo-frame>
    );
};

export default RecipeBox;