import React, { useState, useCallback, useMemo } from 'react';
import RecipeViewer from './RecipeViewer';
import RecipeEditor from './RecipeEditor';
import { ChevronLeft } from 'lucide-react';

/**
 * Root component for displaying and editing a recipe
 * Manages state and API interactions between RecipeViewer and RecipeEditor
 */
const RecipeDetail = ({ recipe, recipeIngredients, units = [], recipeCategories = [] }) => {
    // Component state
    const [isEditing, setIsEditing] = useState(false);
    const [currentRecipe, setCurrentRecipe] = useState(recipe);
    const [currentIngredients, setCurrentIngredients] = useState(recipeIngredients);
    const [feedbackState, setFeedbackState] = useState({
        showSuccess: false,
        showError: false
    });
    const [availableCategories, setAvailableCategories] = useState(recipeCategories);

    // API helper - get CSRF token once
    const csrfToken = useMemo(() =>
            document.querySelector('[name="csrf-token"]')?.content,
        []);

    // Common API request headers for reuse
    const requestHeaders = useMemo(() => ({
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
    }), [csrfToken]);

    // Show temporary feedback (success or error)
    const showFeedback = useCallback((success) => {
        if (success) {
            setFeedbackState({ showSuccess: true, showError: false });
            setTimeout(() => setFeedbackState({ showSuccess: false, showError: false }), 2000);
        } else {
            setFeedbackState({ showSuccess: false, showError: true });
            setTimeout(() => setFeedbackState({ showSuccess: false, showError: false }), 2000);
        }
    }, []);

    // Handle back button click
    const handleBackClick = useCallback(() => {
        window.location.href = "/recipes";
    }, []);

    // Toggle recipe completion status
    const toggleCompletion = useCallback(async () => {
        try {
            const endpoint = currentRecipe.completed
                ? `/recipes/${currentRecipe.id}/mark_incomplete`
                : `/recipes/${currentRecipe.id}/mark_completed`;

            const response = await fetch(endpoint, {
                method: 'POST',
                headers: requestHeaders
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
                console.error('Failed to update recipe');
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error toggling completion:', error);
            showFeedback(false);
        }
    }, [currentRecipe.completed, currentRecipe.id, requestHeaders, showFeedback]);

    // Fetch recipe categories if needed
    const fetchRecipeCategories = useCallback(async () => {
        try {
            const response = await fetch('/recipe_categories', {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
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
    }, []);

    // Handler for edit button click
    const handleEditClick = useCallback(() => {
        // Only fetch categories if we don't have any yet
        if (availableCategories.length === 0) {
            fetchRecipeCategories();
        }
        setIsEditing(true);
    }, [availableCategories.length, fetchRecipeCategories]);

    // Handler for cancel edit button click
    const handleCancelEdit = useCallback(() => {
        setIsEditing(false);
    }, []);

    // Handler for save changes button click
    const handleSaveChanges = useCallback(async (editedRecipe, editedIngredients) => {
        try {
            // Separate existing ingredients from new ones (new ones have negative IDs)
            const existingIngredients = editedIngredients.filter(ing => ing.id > 0);
            const newIngredients = editedIngredients.filter(ing => ing.id < 0);

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
                recipe_ingredients: existingIngredients.map(ingredient => ({
                    id: ingredient.id,
                    grocery_id: ingredient.grocery_id,
                    quantity: ingredient.quantity,
                    unit_id: ingredient.unit_id,
                    preparation: ingredient.preparation || "",
                    size: ingredient.size || "",
                    name: ingredient.name
                })),
                new_recipe_ingredients: newIngredients.map(ingredient => ({
                    grocery_id: ingredient.grocery_id,
                    quantity: ingredient.quantity,
                    unit_id: ingredient.unit_id,
                    unit_name: units.find(u => u.id === parseInt(ingredient.unit_id))?.name,
                    preparation: ingredient.preparation || "",
                    size: ingredient.size || "",
                    name: ingredient.name
                })),
                deleted_ingredient_ids: currentIngredients
                    .filter(ri => !existingIngredients.find(ei => ei.id === ri.id))
                    .map(ri => ri.id)
            };

            const response = await fetch(`/recipes/${recipe.id}`, {
                method: 'PATCH',
                headers: requestHeaders,
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                const updatedData = await response.json();
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
    }, [currentIngredients, recipe.id, requestHeaders, showFeedback, units]);

    // Handler for delete recipe button click
    const handleDeleteRecipe = useCallback(async () => {
        try {
            const response = await fetch(`/recipes/${recipe.id}`, {
                method: 'DELETE',
                headers: requestHeaders
            });

            if (response.ok) {
                window.location.href = '/recipes';
            } else {
                console.error('Failed to delete recipe');
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error deleting recipe:', error);
            showFeedback(false);
        }
    }, [recipe.id, requestHeaders, showFeedback]);

    // Border class that shows feedback when saving/error
    const borderClass = useMemo(() =>
            feedbackState.showSuccess
                ? 'border-2 border-green-500 border-opacity-100'
                : feedbackState.showError
                    ? 'border-2 border-red-500 border-opacity-100'
                    : 'border-2 border-amber-500',
        [feedbackState.showSuccess, feedbackState.showError]);

    return (
        <div className="min-h-screen bg-black text-white">
            <div className="flex justify-center p-8">
                <div className="max-w-4xl w-full relative">
                    {/* Back Button positioned relative to the content div and vertically centered */}
                    <button
                        onClick={handleBackClick}
                        className="absolute -left-16 top-1/2 -translate-y-1/2 p-2 text-white hover:text-amber-500 transition-colors duration-200 focus:outline-none"
                        aria-label="Go back"
                    >
                        <ChevronLeft size={40} />
                    </button>

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

export default React.memo(RecipeDetail);