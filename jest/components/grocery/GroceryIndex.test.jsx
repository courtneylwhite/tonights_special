import React from 'react';
import { render } from '@testing-library/react';
import '@testing-library/jest-dom';
import GroceryIndex from '../../../app/javascript/components/grocery/GroceryIndex';
import ItemInventory from '../../../app/javascript/components/ItemInventory';
import GroceryModal from '../../../app/javascript/components/grocery/GroceryModal';

// Mock the ItemInventory component to verify props
jest.mock('../../../app/javascript/components/ItemInventory', () => {
    return jest.fn(() => <div data-testid="mock-item-inventory">Mocked ItemInventory</div>);
});

// Mock the GroceryModal component
jest.mock('../../../app/javascript/components/grocery/GroceryModal', () => {
    return jest.fn(() => <div data-testid="mock-grocery-modal">Mocked GroceryModal</div>);
});

describe('GroceryIndex Component', () => {
    beforeEach(() => {
        // Clear all mocks before each test
        jest.clearAllMocks();
        ItemInventory.mockClear();
    });

    // Test 1: Basic rendering test
    test('renders without crashing', () => {
        const { getByTestId } = render(<GroceryIndex />);
        expect(getByTestId('mock-item-inventory')).toBeInTheDocument();
    });

    // Test 2: Default props test
    test('passes default props to ItemInventory when no props provided', () => {
        render(<GroceryIndex />);

        // Check that ItemInventory was called with the correct default props
        expect(ItemInventory).toHaveBeenCalledWith({
            items: {},
            itemType: 'grocery',
            apiEndpoint: '/groceries',
            routePath: 'groceries',
            title: 'Grocery Inventory',
            searchPlaceholder: 'Search your groceries...',
            addButtonText: 'Grocery',
            noItemsText: 'No groceries in here yet.',
            units: [],
            ModalComponent: GroceryModal
        }, expect.anything());
    });

    // Test 3: Test with provided props
    test('passes provided groceries and units to ItemInventory', () => {
        // Sample data
        const mockGroceries = {
            'Dairy': {
                id: 1,
                items: [
                    { id: 1, name: 'Milk' },
                    { id: 2, name: 'Cheese' }
                ]
            }
        };

        const mockUnits = ['oz', 'lb', 'cup'];

        render(<GroceryIndex groceries={mockGroceries} units={mockUnits} />);

        // Check that ItemInventory was called with the provided props
        expect(ItemInventory).toHaveBeenCalledWith({
            items: mockGroceries,
            itemType: 'grocery',
            apiEndpoint: '/groceries',
            routePath: 'groceries',
            title: 'Grocery Inventory',
            searchPlaceholder: 'Search your groceries...',
            addButtonText: 'Grocery',
            noItemsText: 'No groceries in here yet.',
            units: mockUnits,
            ModalComponent: GroceryModal
        }, expect.anything());
    });

    // Test 4: Verify correct modal component is passed
    test('passes GroceryModal as the ModalComponent', () => {
        render(<GroceryIndex />);

        // Check that the correct modal component was passed
        expect(ItemInventory).toHaveBeenCalledWith(
            expect.objectContaining({
                ModalComponent: GroceryModal
            }),
            expect.anything()
        );
    });

    // Test 5: Verify grocery-specific props are set correctly
    test('sets grocery-specific props correctly', () => {
        render(<GroceryIndex />);

        // Check that grocery-specific props are set correctly
        expect(ItemInventory).toHaveBeenCalledWith(
            expect.objectContaining({
                itemType: 'grocery',
                routePath: 'groceries',
                title: 'Grocery Inventory',
                searchPlaceholder: 'Search your groceries...',
                addButtonText: 'Grocery',
                noItemsText: 'No groceries in here yet.'
            }),
            expect.anything()
        );
    });
});