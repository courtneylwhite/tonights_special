import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';

const ErrorAlert = ({ message }) => (
    <div className="bg-red-900/50 border border-red-500 text-red-200 px-4 py-3 rounded-lg mb-4">
        {message}
    </div>
);

const RecipeModal = ({
                         isOpen,
                         onClose,
                         recipeCategories = [],
                         onRecipeAdded = () => {},
                     }) => {
    const initialFormState = {
        name: '',
        ingredients: '',
        instructions: '',
        notes: '',
        recipe_category_id: '',
        new_category_name: '',
    };

    const [formData, setFormData] = useState(initialFormState);
    const [error, setError] = useState(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [parsedIngredients, setParsedIngredients] = useState([]);
    const [showPreview, setShowPreview] = useState(false);
    const [isAddingCategoryMode, setIsAddingCategoryMode] = useState(false);

    useEffect(() => {
        if (!isOpen) {
            setFormData(initialFormState);
            setError(null);
            setParsedIngredients([]);
            setShowPreview(false);
            setIsAddingCategoryMode(false);
        }
    }, [isOpen]);

    // Simple frontend parser for ingredients preview
    useEffect(() => {
        if (formData.ingredients.trim() === '') {
            setParsedIngredients([]);
            return;
        }

        // Simple parsing logic for ingredient preview
        const lines = formData.ingredients.split('\n').filter(line => line.trim() !== '');
        const ingredients = [];

        for (const line of lines) {
            // Very basic ingredient parsing for preview
            const quantityMatch = line.match(/^(\d+\/\d+|\d+\.\d+|\d+)?\s*([a-zA-Z]+)?\s*(.+)/);
            if (quantityMatch) {
                const [_, quantity, unit, name] = quantityMatch;
                ingredients.push({
                    quantity: quantity || '',
                    unit: unit || '',
                    name: name.trim()
                });
            } else {
                ingredients.push({ name: line.trim(), quantity: '', unit: '' });
            }
        }

        setParsedIngredients(ingredients);
    }, [formData.ingredients]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setIsSubmitting(true);
        const token = document.querySelector('meta[name="csrf-token"]')?.content;

        try {
            // Send ingredients and instructions as separate fields
            const requestData = {
                recipe: {
                    name: formData.name,
                    ingredients: formData.ingredients,
                    instructions: formData.instructions,
                    notes: formData.notes,
                }
            };

            // Handle category data based on mode
            if (isAddingCategoryMode && formData.new_category_name?.trim()) {
                // Creating a new category
                requestData.new_category = {
                    name: formData.new_category_name,
                    display_order: recipeCategories.length + 1
                };
            } else {
                // Using an existing category
                requestData.recipe.recipe_category_id = formData.recipe_category_id;
            }

            const response = await fetch('/recipes', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': token,
                    'Accept': 'application/json'
                },
                body: JSON.stringify(requestData)
            });

            const data = await response.json();

            if (!response.ok) {
                const errorMessage = data.message || (data.errors ?
                    data.errors.join(', ') :
                    'Failed to create recipe. Please try again.');
                setError(errorMessage);
                return;
            }

            onRecipeAdded(data);
            onClose();

        } catch (error) {
            console.error('Fetch error details:', error);
            setError('An unexpected error occurred. Please try again.');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));

        // If they select "Add New Category" option
        if (name === 'recipe_category_id' && value === 'new') {
            setIsAddingCategoryMode(true);
        }
    };

    const cancelAddCategory = () => {
        setIsAddingCategoryMode(false);
        setFormData(prev => ({
            ...prev,
            recipe_category_id: '',
            new_category_name: ''
        }));
    };

    const togglePreview = () => {
        setShowPreview(!showPreview);
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-gray-900 border border-gray-800 rounded-lg p-6 w-full max-w-3xl max-h-[90vh] overflow-y-auto relative">
                <button
                    onClick={onClose}
                    className="absolute right-4 top-4 text-gray-400 hover:text-white transition-colors duration-200"
                    disabled={isSubmitting}
                >
                    <X size={24} />
                </button>

                <h2 className="text-xl font-semibold mb-6 text-white">Add New Recipe</h2>

                {error && <ErrorAlert message={error} />}

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label htmlFor="name" className="block text-sm font-medium text-gray-300 mb-1">
                            Recipe Name
                        </label>
                        <input
                            type="text"
                            id="name"
                            name="name"
                            value={formData.name}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                            required
                            disabled={isSubmitting}
                            placeholder="e.g., Chocolate Chip Cookies"
                        />
                    </div>

                    {!isAddingCategoryMode ? (
                        <div>
                            <label htmlFor="recipe_category_id" className="block text-sm font-medium text-gray-300 mb-1">
                                Recipe Category
                            </label>
                            <select
                                id="recipe_category_id"
                                name="recipe_category_id"
                                value={formData.recipe_category_id}
                                onChange={handleChange}
                                className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                required
                                disabled={isSubmitting}
                            >
                                <option value="">Select a category</option>
                                {recipeCategories.map((category) => (
                                    <option key={category.id} value={category.id}>
                                        {category.name}
                                    </option>
                                ))}
                                <option value="new" className="font-medium text-amber-400">
                                    + Add New Category
                                </option>
                            </select>
                        </div>
                    ) : (
                        <div>
                            <label htmlFor="new_category_name" className="block text-sm font-medium text-gray-300 mb-1">
                                New Category Name
                            </label>
                            <div className="relative">
                                <input
                                    type="text"
                                    id="new_category_name"
                                    name="new_category_name"
                                    value={formData.new_category_name}
                                    onChange={handleChange}
                                    className="w-full px-4 py-2 pr-10 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                    placeholder="Enter category name"
                                    required={isAddingCategoryMode}
                                    disabled={isSubmitting}
                                />
                                <button
                                    type="button"
                                    onClick={cancelAddCategory}
                                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-200"
                                    disabled={isSubmitting}
                                >
                                    <X size={16} />
                                </button>
                            </div>
                        </div>
                    )}

                    <div>
                        <label htmlFor="ingredients" className="block text-sm font-medium text-gray-300 mb-1">
                            Ingredients
                        </label>
                        <textarea
                            id="ingredients"
                            name="ingredients"
                            value={formData.ingredients}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white h-36"
                            required
                            disabled={isSubmitting}
                            placeholder="Enter ingredients, one per line
e.g., 2 cups flour
1 tsp salt
1/2 cup sugar"
                        />
                        <div className="text-gray-400 text-xs mt-1 ml-1">
                            List one ingredient per line with quantity, unit, and ingredient name.
                        </div>
                    </div>

                    <div>
                        <label htmlFor="instructions" className="block text-sm font-medium text-gray-300 mb-1">
                            Instructions
                        </label>
                        <textarea
                            id="instructions"
                            name="instructions"
                            value={formData.instructions}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white h-36"
                            required
                            disabled={isSubmitting}
                            placeholder="Enter recipe instructions step by step
e.g., 1. Mix dry ingredients
2. Add wet ingredients
3. Bake at 350°F for 25 minutes"
                        />
                    </div>

                    <div>
                        <label htmlFor="notes" className="block text-sm font-medium text-gray-300 mb-1">
                            Notes (Optional)
                        </label>
                        <textarea
                            id="notes"
                            name="notes"
                            value={formData.notes}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white h-24"
                            disabled={isSubmitting}
                            placeholder="Any additional notes about the recipe"
                        />
                    </div>

                    {parsedIngredients.length > 0 && (
                        <div>
                            <button
                                type="button"
                                onClick={togglePreview}
                                className="text-amber-400 hover:text-amber-300 text-sm font-medium flex items-center"
                            >
                                {showPreview ? "Hide Ingredients Preview" : "Show Ingredients Preview"}
                            </button>

                            {showPreview && (
                                <div className="mt-2 bg-gray-800/50 border border-gray-700 rounded-lg p-4 text-gray-300">
                                    <h3 className="font-medium text-amber-400 mb-2">Preview (How your ingredients will be parsed)</h3>

                                    <div className="mb-4">
                                        <h4 className="text-white font-medium mb-2">Ingredients</h4>
                                        <ul className="list-disc pl-5 space-y-1">
                                            {parsedIngredients.map((ingredient, index) => (
                                                <li key={index}>
                                                    {ingredient.quantity && <span>{ingredient.quantity} </span>}
                                                    {ingredient.unit && <span>{ingredient.unit} </span>}
                                                    <span>{ingredient.name}</span>
                                                </li>
                                            ))}
                                        </ul>
                                    </div>

                                    <div className="text-xs italic text-gray-500 mt-3">
                                        Note: This preview shows how the ingredients might be parsed. The actual parsing on the server may be more accurate.
                                    </div>
                                </div>
                            )}
                        </div>
                    )}

                    <button
                        type="submit"
                        className="w-full px-6 py-3 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 font-medium disabled:opacity-50 disabled:cursor-not-allowed mt-2"
                        disabled={isSubmitting || (isAddingCategoryMode && !formData.new_category_name?.trim())}
                    >
                        {isSubmitting ? 'Creating Recipe...' : 'Create Recipe'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default RecipeModal;