import React, { useState, useEffect } from 'react';
import { ChevronLeft, CheckCircle, Edit, Save, X, Clock, Users, BookOpen, Trash2 } from 'lucide-react';

const RecipeDetail = ({ recipe, recipeIngredients, units = [], recipeCategories = [] }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [editedRecipe, setEditedRecipe] = useState(recipe);
    const [editedIngredients, setEditedIngredients] = useState(recipeIngredients);
    const [showSuccess, setShowSuccess] = useState(false);
    const [showError, setShowError] = useState(false);
    const [availableCategories, setAvailableCategories] = useState(recipeCategories);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

    // Helper to check if an ingredient is available (has a grocery_id)
    const isIngredientAvailable = (ingredient) => {
        return ingredient.grocery_id !== null && ingredient.grocery_id !== undefined;
    };

    // Format quantity for display (remove .0 for whole numbers)
    const formatQuantity = (quantity) => {
        if (Number.isInteger(quantity) || quantity % 1 === 0) {
            return Math.round(quantity);
        }

        // Common fractions to display
        const fractions = {
            0.25: "¼",
            0.33: "⅓",
            0.5: "½",
            0.67: "⅔",
            0.75: "¾",
            0.125: "⅛",
            0.375: "⅜",
            0.625: "⅝",
            0.875: "⅞",
            0.2: "⅕",
            0.4: "⅖",
            0.6: "⅗",
            0.8: "⅘"
        };

        // Get the decimal part
        const decimalPart = quantity % 1;
        const roundedDecimal = Math.round(decimalPart * 100) / 100;

        // Find the closest fraction
        let closestFraction = null;
        let smallestDifference = 1;

        for (const [key, value] of Object.entries(fractions)) {
            const difference = Math.abs(roundedDecimal - parseFloat(key));
            if (difference < smallestDifference) {
                smallestDifference = difference;
                closestFraction = value;
            }
        }

        // Get the whole number part
        const wholePart = Math.floor(quantity);

        // Return formatted number
        if (wholePart === 0) {
            return closestFraction;
        } else {
            return `${wholePart}${closestFraction}`;
        }
    };

    // Format the instruction text to handle bullets and numbered lists
    const formatInstructions = (text) => {
        if (!text) return "";

        // Split by newlines
        return text.split("\n").map((line, index) => {
            // Check if it's a bullet point or numbered list item
            const isBullet = line.trim().startsWith("•") || line.trim().startsWith("-") || line.trim().startsWith("*");
            const isNumbered = /^\d+[\.\)]/.test(line.trim());

            if (isBullet || isNumbered) {
                return (
                    <div key={index} className="mb-4 flex">
                        <div className="mr-3 text-amber-500 font-bold">{isNumbered ? line.match(/^\d+[\.\)]/)[0] : "•"}</div>
                        <div>{isNumbered ? line.replace(/^\d+[\.\)]/, "").trim() : line.replace(/^[•\-\*]/, "").trim()}</div>
                    </div>
                );
            } else if (line.trim() === "") {
                return <div key={index} className="h-2"></div>;
            } else {
                return (
                    <div key={index} className="mb-4">
                        {line}
                    </div>
                );
            }
        });
    };

    // Handle showing success/error feedback
    const showFeedback = (success) => {
        if (success) {
            setShowSuccess(true);
            setTimeout(() => setShowSuccess(false), 2000);
        } else {
            setShowError(true);
            setTimeout(() => setShowError(false), 2000);
        }
    };

    // Handle recipe field changes in edit mode
    const handleRecipeChange = (field, value) => {
        setEditedRecipe(prev => ({
            ...prev,
            [field]: value
        }));
    };

    // Handle ingredient changes in edit mode
    const handleIngredientChange = (index, field, value) => {
        const updatedIngredients = [...editedIngredients];
        updatedIngredients[index] = {
            ...updatedIngredients[index],
            [field]: value
        };
        setEditedIngredients(updatedIngredients);
    };

    // Cancel editing and revert changes
    const cancelEditing = () => {
        setEditedRecipe(recipe);
        setEditedIngredients(recipeIngredients);
        setIsEditing(false);
    };

    // Save all changes
    const saveChanges = async () => {
        try {
            // Prepare data for submission with deleted ingredients tracking
            const formData = {
                recipe: {
                    name: editedRecipe.name,
                    instructions: editedRecipe.instructions,
                    notes: editedRecipe.notes || "",  // Handle empty notes explicitly
                    recipe_category_id: editedRecipe.recipe_category_id,
                    prep_time: editedRecipe.prep_time || "",  // Handle empty prep_time explicitly
                    cook_time: editedRecipe.cook_time || "",  // Handle empty cook_time explicitly
                    servings: editedRecipe.servings || null   // Handle empty servings explicitly
                },
                recipe_ingredients: editedIngredients.map(ingredient => ({
                    id: ingredient.id,
                    grocery_id: ingredient.grocery_id,
                    quantity: ingredient.quantity,
                    unit_id: ingredient.unit_id,
                    preparation: ingredient.preparation || "",  // Handle empty preparation explicitly
                    size: ingredient.size || "",                // Handle empty size explicitly
                    name: ingredient.name
                })),
                deleted_ingredient_ids: recipe.recipe_ingredients
                    .filter(ri => !editedIngredients.find(ei => ei.id === ri.id))
                    .map(ri => ri.id)
            };

            // Submit to Rails controller
            const response = await fetch(`/recipes/${recipe.id}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content,
                    'Accept': 'application/json'
                },
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                const updatedData = await response.json();
                // Update local state with response data
                setEditedRecipe(updatedData.recipe);
                setEditedIngredients(updatedData.recipe_ingredients);
                showFeedback(true);
                setIsEditing(false);
            } else {
                console.error('Failed to update recipe');
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error updating recipe:', error);
            showFeedback(false);
        }
    };

    // Toggle recipe completion status
    const toggleCompletion = async () => {
        try {
            const endpoint = recipe.completed
                ? `/recipes/${recipe.id}/mark_incomplete`
                : `/recipes/${recipe.id}/mark_completed`;

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content,
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const updatedData = await response.json();
                setEditedRecipe(prev => ({
                    ...prev,
                    completed: !prev.completed,
                    completed_at: updatedData.recipe.completed_at
                }));
                showFeedback(true);
            } else {
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error toggling completion:', error);
            showFeedback(false);
        }
    };

    // Border class that shows feedback when saving/error
    const borderClass = showSuccess
        ? 'border-2 border-green-500 border-opacity-100'
        : showError
            ? 'border-2 border-red-500 border-opacity-100'
            : 'border-2 border-amber-500'; // Changed to border-2 for consistent thickness

    // Handle ingredient deletion
    const handleDeleteIngredient = (id) => {
        // Filter out the ingredient with the given id
        const updatedIngredients = editedIngredients.filter(ingredient => ingredient.id !== id);
        setEditedIngredients(updatedIngredients);
    };

    // Format servings value for display
    const formatServings = (servings) => {
        if (!servings) return null;

        return Number.isInteger(servings) || servings % 1 === 0
            ? `${Math.round(servings)} servings`
            : `${Math.ceil(servings * 2) / 2} servings`;
    };

    // Fetch all recipe categories when entering edit mode if they weren't provided
    useEffect(() => {
        if (isEditing && availableCategories.length === 0) {
            fetchRecipeCategories();
        }
    }, [isEditing, availableCategories.length]);

    // Fetch recipe categories from the server as a fallback
    const fetchRecipeCategories = async () => {
        try {
            const response = await fetch('/recipe_categories', {
                method: 'GET',
                headers: {
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                const data = await response.json();
                setAvailableCategories(data);
            } else {
                console.error('Failed to fetch recipe categories');
            }
        } catch (error) {
            console.error('Error fetching recipe categories:', error);
        }
    };

    // Delete recipe
    return (
        <div className="min-h-screen bg-black text-white">
            <div className="flex justify-center p-8">
                <div className="max-w-4xl w-full">
                    {/* Header section now without Back Button */}
                    <div className="mb-8 flex justify-end items-center">
                        {/* Delete button now positioned at the top in edit mode */}
                        {isEditing && (
                            <button
                                onClick={() => setShowDeleteConfirm(true)}
                                className="inline-flex items-center px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-red-500 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-red-500 hover:bg-red-500/10"
                            >
                                <Trash2 size={18} className="mr-1" />
                                Delete Recipe
                            </button>
                        )}
                    </div>

                    {/* Main Recipe Content with proper file tab styling */}
                    <div className="relative mb-20 mt-16">
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

                        {/* Main Recipe Card with consistent border */}
                        <div className={`bg-gray-900/90 backdrop-blur-sm rounded-lg shadow-xl transition-all duration-300 ${borderClass} mx-auto overflow-hidden`}>
                            {/* Recipe Header */}
                            <div className="relative bg-gray-900 pt-8 px-8 pb-6">
                                {isEditing ? (
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
                                                {availableCategories.length > 0 ? (
                                                    availableCategories.map(category => (
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
                                ) : (
                                    <>
                                        <h1 className="text-3xl md:text-4xl font-bold text-amber-400 mb-5">{editedRecipe.name}</h1>
                                        <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                                            {/* Prep time */}
                                            {editedRecipe.prep_time && (
                                                <div className="px-3 py-1 bg-transparent text-white rounded-md text-sm inline-flex items-center border border-white">
                                                    <Clock size={16} className="mr-2 text-white" />
                                                    <span className="text-amber-400 mr-1">Prep:</span> {editedRecipe.prep_time}
                                                </div>
                                            )}

                                            {/* Cook time */}
                                            {editedRecipe.cook_time && (
                                                <div className="px-3 py-1 bg-transparent text-white rounded-md text-sm inline-flex items-center border border-white">
                                                    <Clock size={16} className="mr-2 text-white" />
                                                    <span className="text-amber-400 mr-1">Cook:</span> {editedRecipe.cook_time}
                                                </div>
                                            )}

                                            {/* Servings */}
                                            {editedRecipe.servings && (
                                                <div className="px-3 py-1 bg-transparent text-white rounded-md text-sm inline-flex items-center border border-white">
                                                    <Users size={16} className="mr-2 text-white" />
                                                    {formatServings(editedRecipe.servings)}
                                                </div>
                                            )}

                                            {/* Completed status button */}
                                            <div
                                                className={`ml-auto px-3 py-1 rounded-md text-sm cursor-pointer inline-flex items-center ${
                                                    editedRecipe.completed ? 'bg-green-500 text-white' : 'bg-amber-500 text-gray-900'
                                                }`}
                                                onClick={toggleCompletion}
                                            >
                                                <CheckCircle size={16} className="mr-2" />
                                                <span>{editedRecipe.completed ? 'Completed' : 'Mark Complete'}</span>
                                            </div>
                                        </div>
                                    </>
                                )}
                            </div>

                            {/* Horizontal rule under the header */}
                            <div className="border-b-2 border-amber-500 mx-4 mb-5"></div>

                            {isEditing ? (
                                // Edit mode for recipe content
                                <div className="p-8 space-y-8">
                                    {/* Delete confirmation popup */}
                                    {showDeleteConfirm && (
                                        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50">
                                            <div className="bg-gray-800 p-6 rounded-lg shadow-xl max-w-md w-full">
                                                <h3 className="text-xl font-bold text-white mb-4">Delete Recipe</h3>
                                                <p className="text-gray-300 mb-6">
                                                    Are you sure you want to delete this recipe? This action cannot be undone.
                                                </p>
                                                <div className="flex justify-end space-x-4">
                                                    <button
                                                        onClick={() => setShowDeleteConfirm(false)}
                                                        className="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 transition-colors"
                                                    >
                                                        Cancel
                                                    </button>
                                                    <button
                                                        onClick={deleteRecipe}
                                                        className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors flex items-center"
                                                    >
                                                        <Trash2 size={16} className="mr-2" />
                                                        Delete
                                                    </button>
                                                </div>
                                            </div>
                                        </div>
                                    )}

                                    {/* Edit mode for ingredients */}
                                    <div className="mb-8">
                                        <h2 className="text-xl font-semibold mb-4 text-amber-400 border-b border-gray-700 pb-2">Ingredients</h2>
                                        <div className="space-y-4">
                                            {editedIngredients.map((ingredient, index) => (
                                                <div key={ingredient.id} className="bg-gray-800 rounded-lg p-4 relative">
                                                    {/* Delete ingredient button */}
                                                    <button
                                                        onClick={() => handleDeleteIngredient(ingredient.id)}
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
                                                                onChange={(e) => handleIngredientChange(index, 'name', e.target.value)}
                                                                className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                                                            />
                                                        </div>
                                                        <div className="flex gap-2">
                                                            <div className="flex flex-col w-1/3">
                                                                <label className="text-gray-400 mb-1">Quantity</label>
                                                                <input
                                                                    type="number"
                                                                    value={ingredient.quantity}
                                                                    onChange={(e) => handleIngredientChange(index, 'quantity', parseFloat(e.target.value))}
                                                                    className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                                                                    min="0.1"
                                                                    step="0.1"
                                                                />
                                                            </div>
                                                            <div className="flex flex-col w-2/3">
                                                                <label className="text-gray-400 mb-1">Unit</label>
                                                                <select
                                                                    value={ingredient.unit_id}
                                                                    onChange={(e) => handleIngredientChange(index, 'unit_id', e.target.value)}
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
                                                                onChange={(e) => handleIngredientChange(index, 'size', e.target.value)}
                                                                className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                                                                placeholder="e.g., large, small, medium"
                                                            />
                                                        </div>
                                                        <div className="flex flex-col">
                                                            <label className="text-gray-400 mb-1">Preparation</label>
                                                            <input
                                                                type="text"
                                                                value={ingredient.preparation || ''}
                                                                onChange={(e) => handleIngredientChange(index, 'preparation', e.target.value)}
                                                                className="px-3 py-2 bg-gray-700 border border-gray-600 rounded text-white"
                                                                placeholder="e.g., chopped, diced, minced"
                                                            />
                                                        </div>
                                                    </div>
                                                </div>
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
                            ) : (
                                // Display mode - Enhanced recipe card layout with cohesive ingredient lines
                                <div className="p-8">
                                    <div className="grid grid-cols-1 md:grid-cols-2 gap-0">
                                        {/* Left column - Ingredients */}
                                        <div className="md:border-r border-gray-700 md:pr-8">
                                            <h2 className="text-xl font-semibold mb-6 text-amber-400 border-b border-gray-700 pb-2">
                                                Ingredients
                                            </h2>

                                            <div className="space-y-5">
                                                {editedIngredients.map(ingredient => (
                                                    <div key={ingredient.id} className="flex items-center space-x-2">
                                                        {/* Check mark, tightly coupled with text */}
                                                        {isIngredientAvailable(ingredient) ? (
                                                            <div className="h-5 w-5 bg-green-500/20 rounded-full flex items-center justify-center flex-shrink-0">
                                                                <CheckCircle size={16} className="text-green-500" />
                                                            </div>
                                                        ) : (
                                                            <div className="w-5 h-5 rounded-full border border-gray-600 flex-shrink-0"></div>
                                                        )}

                                                        {/* Quantity and unit, immediately next to check */}
                                                        <span className="text-amber-400 font-medium whitespace-nowrap">
                                                            {formatQuantity(ingredient.quantity)} {ingredient.unit_abbreviation || ingredient.unit_name || 'ea'}
                                                        </span>

                                                        {/* Ingredient details, part of the same line */}
                                                        <span className="text-white">
                                                            {ingredient.size ? <span className="text-gray-400">{ingredient.size} </span> : ''}
                                                            {ingredient.name}
                                                            {ingredient.preparation ? <span className="text-gray-400 italic">, {ingredient.preparation}</span> : ''}
                                                        </span>
                                                    </div>
                                                ))}
                                            </div>
                                        </div>

                                        {/* Right column - Instructions */}
                                        <div className="md:pl-8 mt-6 md:mt-0">
                                            <h2 className="text-xl font-semibold mb-6 text-amber-400 border-b border-gray-700 pb-2">
                                                Instructions
                                            </h2>
                                            <div className="text-left text-gray-100">
                                                {formatInstructions(editedRecipe.instructions)}
                                            </div>
                                        </div>
                                    </div>

                                    {/* Notes section (full width, below the two columns) */}
                                    {editedRecipe.notes && (
                                        <div className="mt-8 pt-4 border-t border-gray-800">
                                            <h2 className="text-xl font-semibold mb-4 text-amber-400 pb-2">
                                                Notes
                                            </h2>
                                            <div className="text-left whitespace-pre-wrap text-gray-300 italic">
                                                {editedRecipe.notes}
                                            </div>
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>

                    {/* Action buttons at the bottom */}
                    {!isEditing ? (
                        <div className="mt-8 text-center">
                            <button
                                onClick={() => setIsEditing(true)}
                                className="inline-flex items-center px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-amber-400 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-500"
                            >
                                <Edit size={18} className="mr-1" />
                                Edit Recipe
                            </button>
                        </div>
                    ) : (
                        <div className="mt-8 text-center space-x-4">
                            <button
                                onClick={saveChanges}
                                className="inline-flex items-center px-4 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400"
                            >
                                <Save size={18} className="mr-1" />
                                Save Recipe
                            </button>
                            <button
                                onClick={cancelEditing}
                                className="inline-flex items-center px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors duration-200 border border-gray-700"
                            >
                                <X size={18} className="mr-1" />
                                Cancel
                            </button>
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default RecipeDetail;