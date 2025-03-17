import React from 'react';
import ItemInventory from '../ItemInventory';
import RecipeModal from './RecipeModal';

const RecipeIndex = ({ recipes = {}, units = [] }) => {
    return (
        <ItemInventory
            items={recipes}
            itemType="recipe"
            apiEndpoint="/recipes"
            routePath="recipes"
            title="Recipe Inventory"
            searchPlaceholder="Search your recipes..."
            addButtonText="Recipe"
            noItemsText="No recipes in here yet."
            units={units} // Pass units in case they're needed
            ModalComponent={RecipeModal}
        />
    );
};

export default RecipeIndex;