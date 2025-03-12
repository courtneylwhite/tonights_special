import React, { useState, useCallback, useMemo } from 'react';
import { Save, X, Trash2, Plus } from 'lucide-react';

/**
 * Ingredient form component to reduce complexity of main component
 */
const IngredientForm = React.memo(({
                                       ingredient,
                                       units,
                                       onIngredientChange,
                                       onDeleteIngredient
                                   }) => {
    const handleChange = useCallback((field, value) => {
        onIngredientChange(field, value);
    }, [onIngredientChange]);

    const handleDelete = useCallback(() => {
        onDeleteIngredient(ingredient.id);
    }, [onDeleteIngredient, ingredient.id]);

    return (
        <div className="bg-gray-800 rounded-lg p-4 relative">
            {/* Delete ingredient button */}
            <button
                onClick={handleDelete}
                className="absolute top-2 right-2 text-red-500 hover:text-red-400 p-1 rounded-full hover:bg-gray-700"
                aria-label="Delete ingredient"
            >
                <X size={16} />
            </button>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex flex-col">
                    <label className="text-gray-400 mb-1">Name</label>
                    <input
                        type="text"
                        value={ingredient.name}
                        onChange={(e) => handleChange('name', e.target.value)}
                        className={`px-3 py-2 bg-gray-700 border ${
                            !ingredient.name ? 'border-red-500' : 'border-gray-600'
                        } rounded text-white`}
                    />
                    {!ingredient.name && (
                        <span className="text-red-500 text-xs mt-1">Required</span>
                    )}
                </div>
                <div className="flex gap-2">
                    <div className="flex flex-col w-1/3">
                        <label className="text-gray-400 mb-1">Quantity</label>
                        <input
                            type="number"
                            value={ingredient.quantity}
                            onChange={(e) => handleChange('quantity', parseFloat(e.target.value))}
                            className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                            min="0.1"
                            step="0.1"
                        />
                    </div>
                    <div className="flex flex-col w-2/3">
                        <label className="text-gray-400 mb-1">Unit</label>
                        <select
                            value={ingredient.unit_id}
                            onChange={(e) => handleChange('unit_id', e.target.value)}
                            className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                        >
                            {units.map(unit => (
                                <option key={unit.id} value={unit.id}>
                                    {unit.name}
                                </option>
                            ))}
                        </select>
                    </div>
                </div>
                <div className="flex flex-col">
                    <label className="text-gray-400 mb-1">Size</label>
                    <input
                        type="text"
                        value={ingredient.size || ''}
                        onChange={(e) => handleChange('size', e.target.value)}
                        className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                        placeholder="e.g., large, small, medium"
                    />
                </div>
                <div className="flex flex-col">
                    <label className="text-gray-400 mb-1">Preparation</label>
                    <input
                        type="text"
                        value={ingredient.preparation || ''}
                        onChange={(e) => handleChange('preparation', e.target.value)}
                        className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                        placeholder="e.g., chopped, diced, minced"
                    />
                </div>
            </div>
        </div>
    );
});

/**
 * Delete confirmation dialog component
 */
const DeleteConfirmationDialog = React.memo(({ onConfirm, onCancel }) => {
    return (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50">
            <div className="bg-gray-800 p-6 rounded-lg shadow-xl max-w-md w-full">
                <h3 className="text-xl font-bold text-white mb-4">Delete Recipe</h3>
                <p className="text-gray-300 mb-6">
                    Are you sure you want to delete this recipe? This action cannot be undone.
                </p>
                <div className="flex justify-end space-x-4">
                    <button
                        onClick={onCancel}
                        className="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 transition-colors"
                    >
                        Cancel
                    </button>
                    <button
                        onClick={onConfirm}
                        className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors flex items-center"
                    >
                        <Trash2 size={16} className="mr-2" />
                        Delete
                    </button>
                </div>
            </div>
        </div>
    );
});

/**
 * RecipeEditor component - handles the editing of a recipe
 */
const RecipeEditor = ({
                          recipe,
                          recipeIngredients,
                          units = [],
                          recipeCategories = [],
                          borderClass,
                          onSave,
                          onCancel,
                          onDelete
                      }) => {
    const [editedRecipe, setEditedRecipe] = useState(recipe);
    const [editedIngredients, setEditedIngredients] = useState(recipeIngredients);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
    const [nextTempId, setNextTempId] = useState(-1); // Used for temporary IDs of new ingredients

    // Handle recipe field changes in edit mode
    const handleRecipeChange = useCallback((field, value) => {
        setEditedRecipe(prev => ({
            ...prev,
            [field]: value
        }));
    }, []);

    // Handle ingredient changes in edit mode
    const handleIngredientChange = useCallback((index, field, value) => {
        setEditedIngredients(prevIngredients => {
            const updatedIngredients = [...prevIngredients];
            updatedIngredients[index] = {
                ...updatedIngredients[index],
                [field]: value
            };
            return updatedIngredients;
        });
    }, []);

    // Create a wrapper function to pass to IngredientForm
    const handleIngredientFieldChange = useCallback((index) => {
        return (field, value) => handleIngredientChange(index, field, value);
    }, [handleIngredientChange]);

    // Handle ingredient deletion
    const handleDeleteIngredient = useCallback((id) => {
        setEditedIngredients(prevIngredients =>
            prevIngredients.filter(ingredient => ingredient.id !== id)
        );
    }, []);

    // Handle adding a new ingredient
    const handleAddIngredient = useCallback(() => {
        // Create a new ingredient with default values and a temporary ID
        const newIngredient = {
            id: nextTempId, // Temporary ID (negative to avoid conflicts with server IDs)
            name: "",
            quantity: 1,
            unit_id: units.length > 0 ? units[0].id : "", // Default to first unit if available
            size: "",
            preparation: "",
            grocery_id: null
        };

        // Add the new ingredient to the list
        setEditedIngredients(prev => [...prev, newIngredient]);

        // Decrement the temp ID for next new ingredient
        setNextTempId(prevId => prevId - 1);
    }, [nextTempId, units]);

    // Check if all required fields are filled - memoized for performance
    const isFormValid = useMemo(() => {
        // Check recipe name
        if (!editedRecipe.name.trim()) return false;

        // Check ingredients (must have at least one valid ingredient)
        if (editedIngredients.length === 0) return false;

        // All ingredients must have names and valid quantities
        return editedIngredients.every(ing =>
            ing.name.trim() &&
            ing.quantity > 0
        );
    }, [editedRecipe.name, editedIngredients]);

    // Handle saving changes
    const handleSaveClick = useCallback(() => {
        if (isFormValid) {
            onSave(editedRecipe, editedIngredients);
        } else {
            // Could add an error message here if needed
            alert("Please fill in all required fields before saving");
        }
    }, [isFormValid, editedRecipe, editedIngredients, onSave]);

    // Handle delete confirmation
    const handleDeleteConfirm = useCallback(() => {
        setShowDeleteConfirm(false);
        onDelete();
    }, [onDelete]);

    // Handle cancel delete confirmation
    const handleCancelDelete = useCallback(() => {
        setShowDeleteConfirm(false);
    }, []);

    // Open delete confirmation dialog
    const handleDeleteClick = useCallback(() => {
        setShowDeleteConfirm(true);
    }, []);

    return (
        <div className="relative mb-20 mt-16">
            {/* Delete confirmation popup */}
            {showDeleteConfirm && (
                <DeleteConfirmationDialog
                    onConfirm={handleDeleteConfirm}
                    onCancel={handleCancelDelete}
                />
            )}

            {/* File Tab at the top */}
            <div className="absolute -top-8 left-8 z-10">
                <div className="flex h-8">
                    <div className="bg-amber-500 border-t-2 border-l-2 border-r-2 border-amber-500 rounded-t-lg px-12 flex items-center justify-center w-48">
                        <span className="text-gray-900 font-bold italic">
                            {editedRecipe.recipe_category?.name || "Recipe"}
                        </span>
                    </div>
                </div>
            </div>

            {/* Header section with delete button */}
            <div className="absolute -top-16 right-0">
                <button
                    onClick={handleDeleteClick}
                    className="inline-flex items-center px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-red-500 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-red-500 hover:bg-red-500/10"
                >
                    <Trash2 size={18} className="mr-1" />
                    Delete Recipe
                </button>
            </div>

            {/* Main Recipe Card with consistent border */}
            <div className={`bg-gray-900/90 backdrop-blur-sm rounded-lg shadow-xl transition-all duration-300 ${borderClass} mx-auto overflow-hidden`}>
                {/* Recipe Header */}
                <div className="relative bg-gray-900 pt-8 px-8 pb-6">
                    <div className="space-y-4">
                        <div className="flex flex-col">
                            <label className="text-amber-400 mb-1 font-medium">Recipe Name</label>
                            <input
                                type="text"
                                value={editedRecipe.name}
                                onChange={(e) => handleRecipeChange('name', e.target.value)}
                                className="px-4 py-2 bg-gray-800 border border-amber-500 rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                                placeholder="Recipe name"
                            />
                        </div>
                        <div className="flex flex-col">
                            <label className="text-amber-400 mb-1 font-medium">Category</label>
                            <select
                                value={editedRecipe.recipe_category_id}
                                onChange={(e) => handleRecipeChange('recipe_category_id', e.target.value)}
                                className="px-4 py-2 bg-gray-800 border border-amber-500 rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                            >
                                {recipeCategories.length > 0 ? (
                                    recipeCategories.map(category => (
                                        <option key={category.id} value={category.id}>
                                            {category.name}
                                        </option>
                                    ))
                                ) : (
                                    <option value={editedRecipe.recipe_category_id}>
                                        {editedRecipe.recipe_category?.name}
                                    </option>
                                )}
                            </select>
                        </div>

                        {/* Add input fields for prep time, cook time, and servings */}
                        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-4">
                            <div className="flex flex-col">
                                <label className="text-amber-400 mb-1 font-medium">Prep Time</label>
                                <input
                                    type="text"
                                    value={editedRecipe.prep_time || ''}
                                    onChange={(e) => handleRecipeChange('prep_time', e.target.value)}
                                    className="px-4 py-2 bg-gray-800 border border-amber-500 rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                                    placeholder="e.g. 15 mins"
                                />
                            </div>
                            <div className="flex flex-col">
                                <label className="text-amber-400 mb-1 font-medium">Cook Time</label>
                                <input
                                    type="text"
                                    value={editedRecipe.cook_time || ''}
                                    onChange={(e) => handleRecipeChange('cook_time', e.target.value)}
                                    className="px-4 py-2 bg-gray-800 border border-amber-500 rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                                    placeholder="e.g. 30 mins"
                                />
                            </div>
                            <div className="flex flex-col">
                                <label className="text-amber-400 mb-1 font-medium">Servings</label>
                                <input
                                    type="number"
                                    step="0.5"
                                    min="0.5"
                                    value={editedRecipe.servings || ''}
                                    onChange={(e) => handleRecipeChange('servings', parseFloat(e.target.value))}
                                    className="px-4 py-2 bg-gray-800 border border-amber-500 rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                                    placeholder="e.g. 4"
                                />
                            </div>
                        </div>
                    </div>
                </div>

                {/* Horizontal rule under the header */}
                <div className="border-b-2 border-amber-500 mx-4 mb-5"></div>

                {/* Edit mode for recipe content */}
                <div className="p-8 space-y-8">
                    {/* Edit mode for ingredients */}
                    <div className="mb-8">
                        <div className="flex justify-between items-center mb-4">
                            <h2 className="text-xl font-semibold text-amber-400 border-b border-gray-700 pb-2">Ingredients</h2>
                            <button
                                onClick={handleAddIngredient}
                                className="inline-flex items-center px-3 py-1 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors text-sm"
                            >
                                <Plus size={16} className="mr-1" />
                                Add Ingredient
                            </button>
                        </div>
                        <div className="space-y-4">
                            {editedIngredients.map((ingredient, index) => (
                                <IngredientForm
                                    key={ingredient.id}
                                    ingredient={ingredient}
                                    units={units}
                                    onIngredientChange={handleIngredientFieldChange(index)}
                                    onDeleteIngredient={handleDeleteIngredient}
                                />
                            ))}
                        </div>
                    </div>

                    {/* Edit mode for instructions */}
                    <div className="mb-8">
                        <h2 className="text-xl font-semibold mb-4 text-amber-400 border-b border-gray-700 pb-2">Instructions</h2>
                        <textarea
                            value={editedRecipe.instructions}
                            onChange={(e) => handleRecipeChange('instructions', e.target.value)}
                            className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white min-h-[200px] focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                        />
                    </div>

                    {/* Edit mode for notes */}
                    <div>
                        <h2 className="text-xl font-semibold mb-4 text-amber-400 border-b border-gray-700 pb-2">Notes</h2>
                        <textarea
                            value={editedRecipe.notes || ''}
                            onChange={(e) => handleRecipeChange('notes', e.target.value)}
                            className="w-full bg-gray-800 border border-gray-700 rounded-lg px-4 py-3 text-white min-h-[100px] focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                            placeholder="Add notes about this recipe..."
                        />
                    </div>
                </div>
            </div>

            {/* Action buttons at the bottom */}
            <div className="mt-8 text-center space-x-4">
                <button
                    onClick={handleSaveClick}
                    disabled={!isFormValid}
                    className={`inline-flex items-center px-4 py-2 ${
                        isFormValid
                            ? 'bg-amber-500 hover:bg-amber-600 text-black'
                            : 'bg-gray-500 text-gray-300 cursor-not-allowed'
                    } rounded-lg transition-colors duration-200 border ${
                        isFormValid ? 'border-amber-400' : 'border-gray-600'
                    }`}
                >
                    <Save size={18} className="mr-1" />
                    Save Recipe
                </button>
                <button
                    onClick={onCancel}
                    className="inline-flex items-center px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors duration-200 border border-gray-700"
                >
                    <X size={18} className="mr-1" />
                    Cancel
                </button>
            </div>
        </div>
    );
};

export default React.memo(RecipeEditor);