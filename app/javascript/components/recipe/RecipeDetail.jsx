import React, { useState } from 'react';
import RecipeViewer from '../recipe/RecipeViewer';
import RecipeEditor from '../recipe/RecipeEditor';

const RecipeDetail = ({ recipe, recipeIngredients, units = [], recipeCategories = [] }) => {
    const [isEditing, setIsEditing] = useState(false);
    const [currentRecipe, setCurrentRecipe] = useState(recipe);
    const [currentIngredients, setCurrentIngredients] = useState(recipeIngredients);
    const [showSuccess, setShowSuccess] = useState(false);
    const [showError, setShowError] = useState(false);
    const [availableCategories, setAvailableCategories] = useState(recipeCategories);

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

    // Toggle recipe completion status
    const toggleCompletion = async () => {
        try {
            const endpoint = currentRecipe.completed
                ? `/recipes/${currentRecipe.id}/mark_incomplete`
                : `/recipes/${currentRecipe.id}/mark_completed`;

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
                setCurrentRecipe(prev => ({
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

    // Fetch recipe categories from the server
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

    // Handle switching to edit mode
    const handleEditClick = () => {
        if (availableCategories.length === 0) {
            fetchRecipeCategories();
        }
        setIsEditing(true);
    };

    // Handle canceling edit mode
    const handleCancelEdit = () => {
        setIsEditing(false);
    };

    // Handle saving recipe changes
    const handleSaveChanges = async (editedRecipe, editedIngredients) => {
        try {
            // Prepare data for submission with deleted ingredients tracking
            const formData = {
                recipe: {
                    name: editedRecipe.name,
                    instructions: editedRecipe.instructions,
                    notes: editedRecipe.notes || "",
                    recipe_category_id: editedRecipe.recipe_category_id,
                    prep_time: editedRecipe.prep_time || "",
                    cook_time: editedRecipe.cook_time || "",
                    servings: editedRecipe.servings || null
                },
                recipe_ingredients: editedIngredients.map(ingredient => ({
                    id: ingredient.id,
                    grocery_id: ingredient.grocery_id,
                    quantity: ingredient.quantity,
                    unit_id: ingredient.unit_id,
                    preparation: ingredient.preparation || "",
                    size: ingredient.size || "",
                    name: ingredient.name
                })),
                deleted_ingredient_ids: currentIngredients
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
                setCurrentRecipe(updatedData.recipe);
                setCurrentIngredients(updatedData.recipe_ingredients);
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

    // Handle recipe deletion
    const handleDeleteRecipe = async () => {
        try {
            const response = await fetch(`/recipes/${recipe.id}`, {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content,
                    'Accept': 'application/json'
                }
            });

            if (response.ok) {
                // Redirect to recipes index page
                window.location.href = '/recipes';
            } else {
                console.error('Failed to delete recipe');
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error deleting recipe:', error);
            showFeedback(false);
        }
    };

    // Border class that shows feedback when saving/error
    const borderClass = showSuccess
        ? 'border-2 border-green-500 border-opacity-100'
        : showError
            ? 'border-2 border-red-500 border-opacity-100'
            : 'border-2 border-amber-500';

    return (
        <div className="min-h-screen bg-black text-white">
            <div className="flex justify-center p-8">
                <div className="max-w-4xl w-full">
                    {isEditing ? (
                        <RecipeEditor
                            recipe={currentRecipe}
                            recipeIngredients={currentIngredients}
                            units={units}
                            recipeCategories={availableCategories}
                            borderClass={borderClass}
                            onSave={handleSaveChanges}
                            onCancel={handleCancelEdit}
                            onDelete={handleDeleteRecipe}
                        />
                    ) : (
                        <RecipeViewer
                            recipe={currentRecipe}
                            recipeIngredients={currentIngredients}
                            borderClass={borderClass}
                            onEdit={handleEditClick}
                            onToggleCompletion={toggleCompletion}
                        />
                    )}
                </div>
            </div>
        </div>
    );
};

export default RecipeDetail;