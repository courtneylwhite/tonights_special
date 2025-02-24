import React, { useState, useMemo } from 'react';
import { Plus } from "lucide-react";
// import RecipeModal from '.RecipeModal';
import SearchBar from "./SearchBar";
import ToggleButton from "./ToggleButton";
import Shelf from "./Shelf";

const Recipes = ({ recipes = {}}) => {
    const [recipeData, setRecipeData] = useState([recipes]);
    const [searchTerm, setSearchTerm] = useState('');
    const [isRecipeModalOpen, setIsRecipeModalOpen] = useState(false);
    const [openShelves, setOpenShelves] = useState(
        Object.keys(recipes || {}).reduce((acc, category) => ({
            ...acc,
            [category]: true
        }), {})
    );

    const refreshData = async () => {
        try {
            const response = await fetch('/recipes', {
                headers: { 'Accept': 'application/json' }
            });
            const data = await response.json();
            setRecipeData(data);
            setOpenShelves(
                Object.keys(data || {}).reduce((acc, category) => ({
                    ...acc,
                    [category]: true
                }), {})
            );
        } catch (error) {
            console.error('Failed to refresh recipes:', error);
        }
    };

    const handleRecipeAdded = () => refreshData();
    const handleAddRecipe = () => setIsRecipeModalOpen(true);
    const handleRecipeClick = (recipeId) => {
        window.location.href = `/recipes/${recipeId}`;
    };

}