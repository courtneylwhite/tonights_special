import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';
import RecipeIndex from '../../../app/javascript/components/recipe/RecipeIndex';
import ItemInventory from '../../../app/javascript/components/ItemInventory';
import RecipeModal from '../../../app/javascript/components/recipe/RecipeModal';

// Mock the ItemInventory component to verify props
jest.mock('../../../app/javascript/components/ItemInventory', () => {
    return jest.fn(() => <div data-testid="mock-item-inventory">Mocked ItemInventory</div>);
});

// Mock the RecipeModal component
jest.mock('../../../app/javascript/components/recipe/RecipeModal', () => {
    return jest.fn(() => <div data-testid="mock-recipe-modal">Mocked RecipeModal</div>);
});

describe('RecipeIndex Component', () => {
    beforeEach(() => {
        // Clear all mocks before each test
        jest.clearAllMocks();
        ItemInventory.mockClear();
    });

    // Test 1: Basic rendering test
    test('renders without crashing', () => {
        const { getByTestId } = render(<RecipeIndex />);
        expect(getByTestId('mock-item-inventory')).toBeInTheDocument();
    });

    // Test 2: Default props test
    test('passes default props to ItemInventory when no props provided', () => {
        render(<RecipeIndex />);

        // Check that ItemInventory was called with the correct default props
        expect(ItemInventory).toHaveBeenCalledWith({
            items: {},
            itemType: 'recipe',
            apiEndpoint: '/recipes',
            routePath: 'recipes',
            title: 'Recipe Inventory',
            searchPlaceholder: 'Search your recipes...',
            addButtonText: 'Recipe',
            noItemsText: 'No recipes in here yet.',
            units: [],
            ModalComponent: RecipeModal
        }, expect.anything());
    });

    // Test 3: Test with provided props
    test('passes provided recipes and units to ItemInventory', () => {
        // Sample data
        const mockRecipes = {
            'Main Dishes': {
                id: 1,
                items: [
                    { id: 1, name: 'Spaghetti Carbonara' },
                    { id: 2, name: 'Chicken Piccata' }
                ]
            }
        };

        const mockUnits = ['g', 'kg', 'tbsp'];

        render(<RecipeIndex recipes={mockRecipes} units={mockUnits} />);

        // Check that ItemInventory was called with the provided props
        expect(ItemInventory).toHaveBeenCalledWith({
            items: mockRecipes,
            itemType: 'recipe',
            apiEndpoint: '/recipes',
            routePath: 'recipes',
            title: 'Recipe Inventory',
            searchPlaceholder: 'Search your recipes...',
            addButtonText: 'Recipe',
            noItemsText: 'No recipes in here yet.',
            units: mockUnits,
            ModalComponent: RecipeModal
        }, expect.anything());
    });

    // Test 4: Verify correct modal component is passed
    test('passes RecipeModal as the ModalComponent', () => {
        render(<RecipeIndex />);

        // Check that the correct modal component was passed
        expect(ItemInventory).toHaveBeenCalledWith(
            expect.objectContaining({
                ModalComponent: RecipeModal
            }),
            expect.anything()
        );
    });

    // Test 5: Verify recipe-specific props are set correctly
    test('sets recipe-specific props correctly', () => {
        render(<RecipeIndex />);

        // Check that recipe-specific props are set correctly
        expect(ItemInventory).toHaveBeenCalledWith(
            expect.objectContaining({
                itemType: 'recipe',
                routePath: 'recipes',
                title: 'Recipe Inventory',
                searchPlaceholder: 'Search your recipes...',
                addButtonText: 'Recipe',
                noItemsText: 'No recipes in here yet.'
            }),
            expect.anything()
        );
    });
});