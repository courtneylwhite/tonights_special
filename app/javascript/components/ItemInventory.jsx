import React, { useState } from 'react';
import { Plus } from 'lucide-react';
import SearchBar from './SearchBar';
import ToggleButton from './ToggleButton';
import ScrollableContainer from './ScrollableContainer';

const ItemInventory = ({
                           // Required props
                           items = {},                      // The data to display
                           itemType = 'item',               // 'recipe' or 'grocery' or any other type
                           apiEndpoint = '',                // API endpoint to fetch data from

                           // Component customization props
                           title = 'Inventory',             // Page title
                           searchPlaceholder = 'Search...',  // Placeholder for search box
                           addButtonText = 'Add',           // Text for add button
                           noItemsText = 'No items yet',    // Text when no items exist

                           // Optional props
                           units = [],                      // Units for groceries
                           sections = [],                   // Pre-loaded sections/categories
                           routePath = null,                // Explicit route path (e.g., 'groceries')

                           // Custom components
                           ModalComponent,                  // Modal component for adding items

                           // Custom attributes
                           frameId = 'content',             // ID for the turbo-frame

                           // Optional callback to be called when new item is added
                           onItemAdded = null
                       }) => {
    const [itemData, setItemData] = useState(items);
    const [filteredItemData, setFilteredItemData] = useState(items);
    const [isModalOpen, setIsModalOpen] = useState(false);

    // Create initial toggle state for containers
    const initialToggleState = Object.keys(items || {}).reduce((acc, category) => ({
        ...acc,
        [category]: true
    }), {});

    // State to track which containers are open
    const [containerToggleState, setContainerToggleState] = useState(initialToggleState);

    const refreshData = async (categoryToKeepOpen = null) => {
        try {
            const response = await fetch(apiEndpoint, {
                headers: { 'Accept': 'application/json' }
            });
            const data = await response.json();
            setItemData(data);
            setFilteredItemData(data); // Reset filtered data when new data is loaded

            // If a category to keep open was provided, make sure it stays open in the toggle state
            if (categoryToKeepOpen) {
                setContainerToggleState(prev => ({
                    ...prev,
                    [categoryToKeepOpen]: true
                }));
            }
        } catch (error) {
            console.error(`Failed to refresh ${itemType}s:`, error);
        }
    };

    const handleItemAdded = (newItem) => {
        // Extract category name based on item type and data structure
        let categoryName;

        // Handle different response structures
        if (newItem.category) {
            // For recipes or simple structure
            categoryName = newItem.category;
        } else if (newItem.grocery_section && newItem.grocery_section.name) {
            // For groceries
            categoryName = newItem.grocery_section.name;
        } else if (newItem.recipe && newItem.recipe.category) {
            // For nested recipe structures
            categoryName = newItem.recipe.category;
        } else if (typeof newItem === 'object' && newItem !== null) {
            // Attempt to find category in any property
            for (const key in newItem) {
                if (key.includes('category') || key.includes('section')) {
                    if (typeof newItem[key] === 'string') {
                        categoryName = newItem[key];
                        break;
                    } else if (typeof newItem[key] === 'object' && newItem[key] !== null && newItem[key].name) {
                        categoryName = newItem[key].name;
                        break;
                    }
                }
            }
        }

        // Refresh data, keeping the appropriate category open
        refreshData(categoryName);

        // Call external callback if provided
        if (onItemAdded) {
            onItemAdded(newItem);
        }
    };

    const handleAddItem = () => setIsModalOpen(true);

    const handleItemClick = (itemId) => {
        // If a specific route path is provided, use it
        if (routePath) {
            window.location.href = `/${routePath}/${itemId}`;
            return;
        }

        // Otherwise handle irregular plurals through our mapping
        const pluralRoutes = {
            'grocery': 'groceries',
            'category': 'categories',
            'entry': 'entries',
            // Add other irregular plurals as needed
        };

        let urlPath;
        if (pluralRoutes[itemType]) {
            // Use the irregular plural form
            urlPath = `/${pluralRoutes[itemType]}/${itemId}`;
        } else {
            // Default plural approach: just add 's'
            urlPath = `/${itemType}s/${itemId}`;
        }
        window.location.href = urlPath;
    };

    // Process the sections/categories for the Modal
    const itemSections = Object.entries(itemData || {}).map(([name, data]) => ({
        id: data.id,
        name: name
    }));

    // Sort categories by display order
    const sortedFilteredItems = Object.entries(filteredItemData || {})
        .sort(([, a], [, b]) => a[0]?.display_order - b[0]?.display_order)
        .reduce((acc, [category, data]) => {
            acc[category] = data;
            return acc;
        }, {});

    const hasItems = Object.keys(itemData || {}).length > 0;

    // Define a simple emoji rendering function that will be passed to ScrollableContainer
    const renderEmoji = (emojiInput) => {
        // Default to shopping cart emoji if the input is empty
        if (!emojiInput) return '🛒';

        // Case 1: If it's already an emoji character (not starting with U+)
        if (!emojiInput.startsWith('U+')) {
            return emojiInput;
        }

        // Case 2: If it's a Unicode format (U+XXXX)
        try {
            const hex = emojiInput.replace('U+', '');
            return String.fromCodePoint(parseInt(hex, 16));
        } catch (error) {
            console.error('Error converting emoji:', error);
            return '🛒'; // Default to shopping cart emoji on error
        }
    };

    // Handler for when a container needs to be toggled
    const handleContainerToggle = (category) => {
        setContainerToggleState(prev => ({
            ...prev,
            [category]: !prev[category]
        }));
    };

    // Prepare the correct props for the modal based on item type
    let modalProps = {
        isOpen: isModalOpen,
        onClose: () => setIsModalOpen(false),
        units: units
    };

    // Add item type specific props
    if (itemType === 'recipe') {
        modalProps = {
            ...modalProps,
            recipeCategories: itemSections,
            onRecipeAdded: handleItemAdded
        };
    } else if (itemType === 'grocery') {
        modalProps = {
            ...modalProps,
            grocerySections: itemSections,
            onGroceryAdded: handleItemAdded
        };
    } else {
        // Generic handler for other types
        modalProps[`${itemType}Sections`] = itemSections;
        modalProps[`on${itemType.charAt(0).toUpperCase() + itemType.slice(1)}Added`] = handleItemAdded;
    }

    return (
        <turbo-frame id={routePath ? `${routePath}_${frameId}` : `${itemType}s_${frameId}`}>
            <div className="min-h-screen bg-black text-white relative">
                <div className="bg-black/80 backdrop-blur-sm border-b border-gray-800 p-8 sticky top-0 z-10">
                    <h1 className="text-center mb-8">
                        {title}
                    </h1>
                    <div className="flex items-center gap-4 max-w-3xl mx-auto">
                        <SearchBar
                            placeholder={searchPlaceholder}
                            data={itemData}
                            searchKeys={['name']}
                            onFilteredDataChange={setFilteredItemData}
                        />
                        <button
                            onClick={handleAddItem}
                            className="flex items-center gap-2 px-6 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 border border-amber-400 hover:border-amber-300"
                        >
                            <Plus size={18}/>
                            <span className="text-sm font-medium">{addButtonText}</span>
                        </button>
                        <ToggleButton
                            initialToggleState={containerToggleState}
                            onToggleChange={setContainerToggleState}
                        />
                    </div>
                </div>

                <div className="max-w-5xl mx-auto p-6 relative z-0">
                    {!hasItems ? (
                        <div className="text-center text-gray-400 py-12">
                            <p>{noItemsText}</p>
                        </div>
                    ) : (
                        <div className="space-y-4">
                            {Object.entries(sortedFilteredItems).map(([category, sectionData], categoryIndex) => (
                                <ScrollableContainer
                                    key={category}
                                    category={category}
                                    items={sectionData.items}
                                    categoryIndex={categoryIndex}
                                    isOpen={containerToggleState[category]}
                                    onToggle={handleContainerToggle}
                                    handleItemClick={handleItemClick}
                                    renderEmoji={renderEmoji}
                                />
                            ))}
                        </div>
                    )}
                </div>

                {/* Render the modal with the appropriate props */}
                {ModalComponent && <ModalComponent {...modalProps} />}
            </div>
        </turbo-frame>
    );
};

export default ItemInventory;