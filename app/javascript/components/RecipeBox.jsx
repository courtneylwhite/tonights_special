import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import RecipeModal from './RecipeModal';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import ScrollableContainer from './ScrollableContainer';

const Recipes = ({ recipes = {}, units = [] }) => {
    console.log(recipes);
    const [recipeData, setRecipeData] = useState(recipes);
    const [filteredRecipeData, setFilteredRecipeData] = useState(recipes);
    const [isRecipeModalOpen, setIsRecipeModalOpen] = useState(false);

    // Create initial toggle state for containers
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

    const handleRecipeAdded = () => refreshData();
    const handleAddRecipe = () => setIsRecipeModalOpen(true);
    const handleRecipeClick = (recipeId) => {
        window.location.href = `/recipes/${recipeId}`;
    };

    // Process the recipe sections for the RecipeModal
    const recipeCategories = Object.entries(recipeData || {}).map(([name, data]) => ({
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

    // State to track which containers are open
    const [containerToggleState, setContainerToggleState] = useState(initialToggleState);

    // Handler for when a container needs to be toggled
    const handleContainerToggle = (category) => {
        setContainerToggleState(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    return (
        <turbo-frame id="recipes_content">
            <div className="min-h-screen bg-black text-white relative">
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        Culinary Inventory
                    </h1>
                    <div className="flex items-center gap-4 max-w-3xl mx-auto">
                        <SearchBar
                            placeholder="Search your pantry..."
                            data={recipeData}
                            searchKeys={['name']}
                            onFilteredDataChange={setFilteredRecipeData}
                        />
                        <button
                            onClick={handleAddRecipe}
                            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                        >
                            <Plus size={18}/>
                            <span className="text-sm font-medium">Recipe</span>
                        </button>
                        <ToggleButton
                            initialToggleState={containerToggleState}
                            onToggleChange={setContainerToggleState}
                        />
                    </div>
                </div>

                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    {!hasRecipes ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>No recipes in your pantry yet.</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(sortedFilteredRecipes).map(([category, sectionData], categoryIndex) => (
                                <ScrollableContainer
                                    key={category}
                                    category={category}
                                    items={sectionData.items}
                                    categoryIndex={categoryIndex}
                                    isOpen={containerToggleState[category]}
                                    onToggle={handleContainerToggle}
                                    handleRecipeClick={handleRecipeClick}
                                    unicodeToEmoji={unicodeToEmoji}
                                />
                            ))}
                        </div>
                    )}
                </div>

                <RecipeModal
                    isOpen={isRecipeModalOpen}
                    onClose={() => setIsRecipeModalOpen(false)}
                    recipeCategories={recipeCategories}
                    onRecipeAdded={handleRecipeAdded}
                />
            </div>
        </turbo-frame>
    );
};

export default Recipes;