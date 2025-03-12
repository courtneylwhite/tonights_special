import React from 'react';
import { render, screen, fireEvent } from '@testing-library/react';
import '@testing-library/jest-dom';
import GroceryViewer from '../../../app/javascript/components/grocery/GroceryViewer';
import { ChevronUp, ChevronDown, Edit } from 'lucide-react';

// Mock Lucide React icons
jest.mock('lucide-react', () => ({
    ChevronUp: () => <div data-testid="chevron-up-icon" />,
    ChevronDown: () => <div data-testid="chevron-down-icon" />,
    Edit: () => <div data-testid="edit-icon" />
}));

describe('GroceryViewer', () => {
    const mockGrocery = {
        id: 1,
        name: 'Apple',
        quantity: 5,
        emoji: 'U+1F34E',
        unit: { id: 1, name: 'piece' },
        grocery_section: { id: 1, name: 'Produce' }
    };

    const mockBorderClass = 'test-border-class';
    const mockOnEdit = jest.fn();
    const mockOnIncrement = jest.fn();
    const mockOnDecrement = jest.fn();

    beforeEach(() => {
        jest.clearAllMocks();
    });

    test('renders grocery information correctly', () => {
        render(
            <GroceryViewer
                grocery={mockGrocery}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Check name is displayed
        expect(screen.getByText('Apple')).toBeInTheDocument();

        // Check section is displayed
        expect(screen.getByText(/Section: Produce/i)).toBeInTheDocument();

        // Check quantity is displayed
        expect(screen.getByText('5')).toBeInTheDocument();

        // Check unit is displayed (plural form since quantity > 1)
        expect(screen.getByText('pieces')).toBeInTheDocument();
    });

    test('shows singular unit name when quantity is 1', () => {
        const groceryWithQuantityOne = {
            ...mockGrocery,
            quantity: 1
        };

        render(
            <GroceryViewer
                grocery={groceryWithQuantityOne}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        expect(screen.getByText('piece')).toBeInTheDocument();
    });

    test('shows "Uncategorized" when grocery section is missing', () => {
        const groceryWithoutSection = {
            ...mockGrocery,
            grocery_section: null
        };

        render(
            <GroceryViewer
                grocery={groceryWithoutSection}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        expect(screen.getByText('Section: Uncategorized')).toBeInTheDocument();
    });

    test('applies the correct border class', () => {
        render(
            <GroceryViewer
                grocery={mockGrocery}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Find an element that should have the border class
        const elements = document.getElementsByClassName(mockBorderClass);
        expect(elements.length).toBeGreaterThan(0);
    });

    test('calls onEdit when edit button is clicked', () => {
        render(
            <GroceryViewer
                grocery={mockGrocery}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        const editButton = screen.getByText('Edit Grocery');
        fireEvent.click(editButton);

        expect(mockOnEdit).toHaveBeenCalledTimes(1);
    });

    test('calls onIncrement when increment button is clicked', () => {
        render(
            <GroceryViewer
                grocery={mockGrocery}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Find the increment button (with the up chevron)
        const incrementButton = screen.getByLabelText('Increase quantity');
        fireEvent.click(incrementButton);

        expect(mockOnIncrement).toHaveBeenCalledTimes(1);
    });

    test('calls onDecrement when decrement button is clicked', () => {
        render(
            <GroceryViewer
                grocery={mockGrocery}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Find the decrement button (with the down chevron)
        const decrementButton = screen.getByLabelText('Decrease quantity');
        fireEvent.click(decrementButton);

        expect(mockOnDecrement).toHaveBeenCalledTimes(1);
    });

    test('disables decrement button when quantity is 0', () => {
        const groceryWithZeroQuantity = {
            ...mockGrocery,
            quantity: 0
        };

        render(
            <GroceryViewer
                grocery={groceryWithZeroQuantity}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        const decrementButton = screen.getByLabelText('Decrease quantity');
        expect(decrementButton).toBeDisabled();

        fireEvent.click(decrementButton);
        expect(mockOnDecrement).not.toHaveBeenCalled();
    });

    test('handles missing emoji gracefully', () => {
        const groceryWithoutEmoji = {
            ...mockGrocery,
            emoji: null
        };

        render(
            <GroceryViewer
                grocery={groceryWithoutEmoji}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Should render something in the emoji place (the exact content depends on implementation)
        const container = screen.getByText('❓');
        expect(container).toBeInTheDocument();
    });

    test('handles invalid emoji unicode gracefully', () => {
        console.error = jest.fn(); // Mock console.error

        const groceryWithInvalidEmoji = {
            ...mockGrocery,
            emoji: 'Invalid-Unicode'
        };

        render(
            <GroceryViewer
                grocery={groceryWithInvalidEmoji}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Verify fallback emoji is shown
        const container = screen.getByText('❓');
        expect(container).toBeInTheDocument();

        // Verify error was logged
        expect(console.error).toHaveBeenCalledWith(
            'Error converting unicode to emoji:',
            expect.any(Error)
        );
    });

    test('renders correct number of icons', () => {
        render(
            <GroceryViewer
                grocery={mockGrocery}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Check for presence of specific icons
        expect(screen.getByTestId('chevron-up-icon')).toBeInTheDocument();
        expect(screen.getByTestId('chevron-down-icon')).toBeInTheDocument();
        expect(screen.getByTestId('edit-icon')).toBeInTheDocument();
    });

    test('correctly handles emoji with unicode prefix', () => {
        render(
            <GroceryViewer
                grocery={{...mockGrocery, emoji: 'U+1F34E'}}
                borderClass={mockBorderClass}
                onEdit={mockOnEdit}
                onIncrement={mockOnIncrement}
                onDecrement={mockOnDecrement}
            />
        );

        // Check that the specific emoji is rendered
        const emojiElement = screen.getByText('🍎');
        expect(emojiElement).toBeInTheDocument();
    });
});