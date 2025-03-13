import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';
import GroceryDetail from '../../../app/javascript/components/grocery/GroceryDetail';

// Mock lucide-react components
jest.mock('lucide-react', () => ({
    ChevronLeft: () => <div data-testid="mock-chevron-left">Back</div>
}));

// Mock child components
jest.mock('../../../app/javascript/components/grocery/GroceryViewer', () => {
    return jest.fn(props => (
        <div data-testid="grocery-viewer">
            <div data-testid="grocery-name">{props.grocery.name}</div>
            <div data-testid="grocery-section">{props.grocery.grocery_section?.name || 'Uncategorized'}</div>
            <button data-testid="edit-button" onClick={props.onEdit}>Edit</button>
            <button data-testid="increment-button" onClick={props.onIncrement}>+</button>
            <button data-testid="decrement-button" onClick={props.onDecrement}>-</button>
            <input
                data-testid="quantity-input"
                value={props.grocery.quantity}
                onChange={(e) => props.onQuantityChange(parseFloat(e.target.value))}
            />
        </div>
    ));
});

jest.mock('../../../app/javascript/components/grocery/GroceryEditor', () => {
    return jest.fn(props => (
        <div data-testid="grocery-editor">
            <div data-testid="edit-grocery-name">{props.grocery.name}</div>
            <button data-testid="save-button" onClick={() => props.onSave(props.grocery)}>Save</button>
            <button data-testid="cancel-button" onClick={props.onCancel}>Cancel</button>
            <button data-testid="delete-button" onClick={props.onDelete}>Delete</button>
        </div>
    ));
});

// Mock fetch API
global.fetch = jest.fn();

// Mock document.querySelector for CSRF token
document.querySelector = jest.fn(() => ({ content: 'fake-csrf-token' }));

// Mock window.location
const originalLocation = window.location;

describe('GroceryDetail', () => {
    const mockGrocery = {
        id: 1,
        name: 'Apple',
        quantity: 5,
        emoji: 'U+1F34E',
        unit: { id: 1, name: 'piece' },
        grocery_section: { id: 1, name: 'Produce' }
    };

    const mockUnits = [
        { id: 1, name: 'piece' },
        { id: 2, name: 'pound' }
    ];

    const mockGrocerySections = [
        { id: 1, name: 'Produce' },
        { id: 2, name: 'Dairy' }
    ];

    beforeEach(() => {
        // Reset all mocks
        jest.clearAllMocks();

        // Mock CSRF token
        document.querySelector.mockReturnValue({ content: 'test-csrf-token' });

        // Default fetch mock implementation
        global.fetch.mockResolvedValue({
            ok: true,
            json: async () => mockGrocery
        });

        // Mock window.location
        delete window.location;
        window.location = { href: '' };
    });

    afterEach(() => {
        // Restore window.location
        window.location = originalLocation;
    });

    test('renders GroceryViewer by default', () => {
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        expect(screen.getByTestId('grocery-viewer')).toBeInTheDocument();
        expect(screen.queryByTestId('grocery-editor')).not.toBeInTheDocument();
    });

    test('renders back button', () => {
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        expect(screen.getByTestId('mock-chevron-left')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /go back/i })).toBeInTheDocument();
    });

    test('switches to edit mode when edit button is clicked', () => {
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        fireEvent.click(screen.getByTestId('edit-button'));

        expect(screen.getByTestId('grocery-editor')).toBeInTheDocument();
        expect(screen.queryByTestId('grocery-viewer')).not.toBeInTheDocument();
    });

    test('switches back to view mode when cancel button is clicked', () => {
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));
        // Then cancel
        fireEvent.click(screen.getByTestId('cancel-button'));

        expect(screen.getByTestId('grocery-viewer')).toBeInTheDocument();
        expect(screen.queryByTestId('grocery-editor')).not.toBeInTheDocument();
    });

    test('back button navigates to groceries index', () => {
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Click back button
        fireEvent.click(screen.getByRole('button', { name: /go back/i }));

        // Check if navigation occurred
        expect(window.location.href).toBe('/groceries');
    });

    test('updates quantity when increment button is clicked', async () => {
        const updatedGrocery = { ...mockGrocery, quantity: 6 };

        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: true,
                json: () => Promise.resolve(updatedGrocery)
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        fireEvent.click(screen.getByTestId('increment-button'));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith(
                `/groceries/${mockGrocery.id}`,
                expect.objectContaining({
                    method: 'PATCH',
                    body: JSON.stringify({
                        grocery: { quantity: 6 }
                    })
                })
            );
        });
    });

    test('updates quantity when decrement button is clicked', async () => {
        const updatedGrocery = { ...mockGrocery, quantity: 4 };

        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: true,
                json: () => Promise.resolve(updatedGrocery)
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        fireEvent.click(screen.getByTestId('decrement-button'));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith(
                `/groceries/${mockGrocery.id}`,
                expect.objectContaining({
                    method: 'PATCH',
                    body: JSON.stringify({
                        grocery: { quantity: 4 }
                    })
                })
            );
        });
    });

    test('prevents decrement when quantity is already 0', async () => {
        const zeroQuantityGrocery = { ...mockGrocery, quantity: 0 };

        render(
            <GroceryDetail
                grocery={zeroQuantityGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        fireEvent.click(screen.getByTestId('decrement-button'));

        // Ensure fetch was not called
        expect(global.fetch).not.toHaveBeenCalled();
    });

    test('saves changes when save button is clicked', async () => {
        const updatedGrocery = {
            ...mockGrocery,
            name: 'Green Apple',
            grocery_section: { id: 2, name: 'Dairy' }
        };

        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: true,
                json: () => Promise.resolve(updatedGrocery)
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Save changes
        fireEvent.click(screen.getByTestId('save-button'));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith(
                `/groceries/${mockGrocery.id}`,
                expect.objectContaining({
                    method: 'PATCH'
                })
            );
        });

        // Should switch back to view mode
        await waitFor(() => {
            expect(screen.getByTestId('grocery-viewer')).toBeInTheDocument();
        });
    });

    test('deletes grocery when delete button is clicked', async () => {
        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: true
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));
        // Delete grocery
        fireEvent.click(screen.getByTestId('delete-button'));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith(
                `/groceries/${mockGrocery.id}`,
                expect.objectContaining({
                    method: 'DELETE'
                })
            );
        });

        // Should redirect
        expect(window.location.href).toBe('/groceries');
    });

    test('handles network error during increment', async () => {
        console.error = jest.fn(); // Mock console.error

        // Mock fetch to throw a network error
        global.fetch.mockImplementationOnce(() =>
            Promise.reject(new Error('Network error'))
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        fireEvent.click(screen.getByTestId('increment-button'));

        // Verify the error handling
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Error updating quantity:', expect.any(Error));
        });
    });

    test('handles unsuccessful API response during increment', async () => {
        console.error = jest.fn(); // Mock console.error

        // Mock fetch to return an unsuccessful response
        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: false,
                text: () => Promise.resolve('Update failed')
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        fireEvent.click(screen.getByTestId('increment-button'));

        // Verify the error handling
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Failed to update quantity:', expect.any(String));
        });
    });

    // New test for direct quantity input
    test('does not update when quantity is the same', async () => {
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Call onQuantityChange with the same value that's already set
        fireEvent.change(screen.getByTestId('quantity-input'), { target: { value: '5' } });

        // Wait a bit to ensure any async operations would have occurred
        await waitFor(() => {
            // Fetch should not have been called since quantity didn't change
            expect(global.fetch).not.toHaveBeenCalled();
        });
    });

    test('updates local state immediately before API call completes', async () => {
        // Mock a delayed API response
        global.fetch.mockImplementationOnce(() =>
            new Promise(resolve => {
                setTimeout(() => {
                    resolve({
                        ok: true,
                        json: () => Promise.resolve({ ...mockGrocery, quantity: 10 })
                    });
                }, 100);
            })
        );

        const { rerender } = render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Change quantity in input field
        fireEvent.change(screen.getByTestId('quantity-input'), { target: { value: '10' } });

        // Check that the component updates state immediately, before API call completes
        await waitFor(() => {
            expect(screen.getByTestId('quantity-input').value).toBe('10');
        });

        // API call should still be happening but local state is already updated
        expect(global.fetch).toHaveBeenCalledWith(
            `/groceries/${mockGrocery.id}`,
            expect.objectContaining({
                method: 'PATCH',
                body: JSON.stringify({
                    grocery: { quantity: 10 }
                })
            })
        );
    });

    test('reverts to original value when API call fails', async () => {
        console.error = jest.fn(); // Mock console.error

        // Mock fetch to return an unsuccessful response
        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: false,
                text: () => Promise.resolve('Update failed')
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Change quantity in input field - this should trigger the API call
        fireEvent.change(screen.getByTestId('quantity-input'), { target: { value: '10' } });

        // Wait for API call to fail
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Failed to update quantity:', expect.any(String));
        });

        // After error handling, value should be reverted to original
        expect(screen.getByTestId('quantity-input').value).toBe('5');
    });

    test('handles network error during quantity change', async () => {
        console.error = jest.fn(); // Mock console.error

        // Mock fetch to throw a network error
        global.fetch.mockImplementationOnce(() =>
            Promise.reject(new Error('Network error'))
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Change quantity in input field
        fireEvent.change(screen.getByTestId('quantity-input'), { target: { value: '7.5' } });

        // Verify the error handling
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Error updating quantity:', expect.any(Error));
        });
    });

    test('handles network error during delete', async () => {
        console.error = jest.fn(); // Mock console.error

        // Mock fetch to throw a network error
        global.fetch.mockImplementationOnce(() =>
            Promise.reject(new Error('Network error'))
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Try to delete
        fireEvent.click(screen.getByTestId('delete-button'));

        // Verify the error handling
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Error deleting grocery:', expect.any(Error));
        });
    });

    test('fetches grocery sections when editing with empty sections', async () => {
        const fetchedSections = [
            { id: 1, name: 'Produce' },
            { id: 2, name: 'Dairy' }
        ];

        global.fetch.mockImplementationOnce(() =>
            Promise.resolve({
                ok: true,
                json: () => Promise.resolve(fetchedSections)
            })
        );

        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={[]} // Empty sections to trigger fetch
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Verify the fetch
        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith(
                '/grocery_sections',
                expect.objectContaining({
                    method: 'GET'
                })
            );
        });
    });

    test('handles CSRF token not found', () => {
        // Mock document.querySelector to return null
        document.querySelector.mockReturnValue(null);

        // Render should not throw an error
        render(
            <GroceryDetail
                grocery={mockGrocery}
                units={mockUnits}
                grocerySections={mockGrocerySections}
            />
        );

        // Ensure the component renders
        expect(screen.getByTestId('grocery-viewer')).toBeInTheDocument();
    });
});