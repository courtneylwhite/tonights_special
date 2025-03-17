import React from 'react';
import ItemInventory from '../ItemInventory';
import GroceryModal from './GroceryModal';

const GroceryIndex = ({ groceries = {}, units = [] }) => {
    return (
        <ItemInventory
            items={groceries}
            itemType="grocery"
            apiEndpoint="/groceries"
            routePath="groceries"
            title="Grocery Inventory"
            searchPlaceholder="Search your groceries..."
            addButtonText="Grocery"
            noItemsText="No groceries in here yet."
            units={units}
            ModalComponent={GroceryModal}
        />
    );
};

export default GroceryIndex;