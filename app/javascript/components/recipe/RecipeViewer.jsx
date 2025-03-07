import React, { useMemo, useCallback } from 'react';
import { ChevronLeft, CheckCircle, Edit, Clock, Users } from 'lucide-react';

/**
 * IngredientLine component - renders a single ingredient line
 */
const IngredientLine = React.memo(({ ingredient }) => {
    // Helper function to format quantity (convert decimals to fractions where possible)
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

    // Is the ingredient available in the pantry?
    const isAvailable = ingredient.grocery_id !== null && ingredient.grocery_id !== undefined;

    return (
        <div className="flex items-center space-x-2">
            {/* Check mark, tightly coupled with text */}
            {isAvailable ? (
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
    );
});

/**
 * Instructions component - formats and renders the recipe instructions
 */
const Instructions = React.memo(({ text }) => {
    const formattedInstructions = useMemo(() => {
        if (!text) return [];

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
    }, [text]);

    return <>{formattedInstructions}</>;
});

/**
 * RecipeViewer component - displays a recipe in read-only mode
 */
const RecipeViewer = ({ recipe, recipeIngredients, borderClass, onEdit, onToggleCompletion }) => {
    // Format servings value for display
    const formattedServings = useMemo(() => {
        if (!recipe.servings) return null;

        return Number.isInteger(recipe.servings) || recipe.servings % 1 === 0
            ? `${Math.round(recipe.servings)} servings`
            : `${Math.ceil(recipe.servings * 2) / 2} servings`;
    }, [recipe.servings]);

    // Handle edit button click
    const handleEditClick = useCallback(() => {
        onEdit();
    }, [onEdit]);

    // Handle toggle completion status button click
    const handleToggleCompletion = useCallback(() => {
        onToggleCompletion();
    }, [onToggleCompletion]);

    return (
        <div className="relative mb-20 mt-16">
            {/* File Tab at the top */}
            <div className="absolute -top-8 left-8 z-10">
                <div className="flex h-8">
                    <div className="bg-amber-500 border-t-2 border-l-2 border-r-2 border-amber-500 rounded-t-lg px-12 flex items-center justify-center w-48">
                        <span className="text-gray-900 font-bold italic">
                            {recipe.recipe_category?.name || "Recipe"}
                        </span>
                    </div>
                </div>
            </div>

            {/* Main Recipe Card with consistent border */}
            <div className={`bg-gray-900/90 backdrop-blur-sm rounded-lg shadow-xl transition-all duration-300 ${borderClass} mx-auto overflow-hidden`}>
                {/* Recipe Header */}
                <div className="relative bg-gray-900 pt-8 px-8 pb-6">
                    <h1 className="text-3xl md:text-4xl font-bold text-amber-400 mb-5">{recipe.name}</h1>
                    <div className="flex flex-col sm:flex-row sm:items-center gap-4">
                        {/* Prep time */}
                        {recipe.prep_time && (
                            <div className="px-3 py-1 bg-transparent text-white rounded-md text-sm inline-flex items-center border border-white">
                                <Clock size={16} className="mr-2 text-white" />
                                <span className="text-amber-400 mr-1">Prep:</span> {recipe.prep_time}
                            </div>
                        )}

                        {/* Cook time */}
                        {recipe.cook_time && (
                            <div className="px-3 py-1 bg-transparent text-white rounded-md text-sm inline-flex items-center border border-white">
                                <Clock size={16} className="mr-2 text-white" />
                                <span className="text-amber-400 mr-1">Cook:</span> {recipe.cook_time}
                            </div>
                        )}

                        {/* Servings */}
                        {formattedServings && (
                            <div className="px-3 py-1 bg-transparent text-white rounded-md text-sm inline-flex items-center border border-white">
                                <Users size={16} className="mr-2 text-white" />
                                {formattedServings}
                            </div>
                        )}

                        {/* Completed status button */}
                        <div
                            className={`ml-auto px-3 py-1 rounded-md text-sm cursor-pointer inline-flex items-center ${
                                recipe.completed ? 'bg-green-500 text-white' : 'bg-amber-500 text-gray-900'
                            }`}
                            onClick={handleToggleCompletion}
                        >
                            <CheckCircle size={16} className="mr-2" />
                            <span>{recipe.completed ? 'Completed' : 'Mark Complete'}</span>
                        </div>
                    </div>
                </div>

                {/* Horizontal rule under the header */}
                <div className="border-b-2 border-amber-500 mx-4 mb-5"></div>

                {/* Display mode - Enhanced recipe card layout with cohesive ingredient lines */}
                <div className="p-8">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-0">
                        {/* Left column - Ingredients */}
                        <div className="md:border-r border-gray-700 md:pr-8">
                            <h2 className="text-xl font-semibold mb-6 text-amber-400 border-b border-gray-700 pb-2">
                                Ingredients
                            </h2>

                            <div className="space-y-5">
                                {recipeIngredients.map(ingredient => (
                                    <IngredientLine key={ingredient.id} ingredient={ingredient} />
                                ))}
                            </div>
                        </div>

                        {/* Right column - Instructions */}
                        <div className="md:pl-8 mt-6 md:mt-0">
                            <h2 className="text-xl font-semibold mb-6 text-amber-400 border-b border-gray-700 pb-2">
                                Instructions
                            </h2>
                            <div className="text-left text-gray-100">
                                <Instructions text={recipe.instructions} />
                            </div>
                        </div>
                    </div>

                    {/* Notes section (full width, below the two columns) */}
                    {recipe.notes && (
                        <div className="mt-8 pt-4 border-t border-gray-800">
                            <h2 className="text-xl font-semibold mb-4 text-amber-400 pb-2">
                                Notes
                            </h2>
                            <div className="text-left whitespace-pre-wrap text-gray-300 italic">
                                {recipe.notes}
                            </div>
                        </div>
                    )}
                </div>
            </div>

            {/* Action buttons at the bottom */}
            <div className="mt-8 text-center">
                <button
                    onClick={handleEditClick}
                    className="inline-flex items-center px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-amber-400 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-500"
                >
                    <Edit size={18} className="mr-1" />
                    Edit Recipe
                </button>
            </div>
        </div>
    );
};

export default React.memo(RecipeViewer);