import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import ItemModal from '@/components/GroceryModal';

describe('ItemModal', () => {
    const mockProps = {
        isOpen: true,
        onClose: jest.fn(),
        onItemAdded: jest.fn(),
        grocerySections: [
            { id: 1, name: 'Produce' },
            { id: 2, name: 'Dairy' }
        ],
        units: [
            { id: 1, name: 'each' },
            { id: 2, name: 'lbs' }
        ]
    };

    beforeEach(() => {
        global.fetch = jest.fn();
        document.body.innerHTML = '<meta name="csrf-token" content="test-token" />';
        jest.clearAllMocks();
        console.error = jest.fn(); // Mock console.error to prevent cluttering test output
    });

    it('renders form fields when open', () => {
        render(<ItemModal {...mockProps} />);
        expect(screen.getByLabelText('Item Name')).toBeInTheDocument();
        expect(screen.getByLabelText('Quantity')).toBeInTheDocument();
        expect(screen.getByLabelText('Unit')).toBeInTheDocument();
        expect(screen.getByLabelText('Pantry Section')).toBeInTheDocument();
        expect(screen.getByLabelText('Emoji (Unicode)')).toBeInTheDocument();
    });

    it('handles form submission successfully', async () => {
        // Mock successful API response
        const mockResponse = { id: 1, name: 'Apple' };
        global.fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve(mockResponse)
        });

        render(<ItemModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Apple' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '5' } });
        fireEvent.change(screen.getByLabelText('Unit'), { target: { value: '1' } });
        fireEvent.change(screen.getByLabelText('Pantry Section'), { target: { value: '1' } });
        fireEvent.change(screen.getByLabelText('Emoji (Unicode)'), { target: { value: 'U+1F34E' } });

        fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith('/groceries', expect.any(Object));
            expect(mockProps.onItemAdded).toHaveBeenCalled();
            expect(mockProps.onClose).toHaveBeenCalled();
        });
    });

    it('handles form submission error', async () => {
        // Mock failed API response
        global.fetch.mockResolvedValueOnce({
            ok: false,
            json: () => Promise.resolve({ error: 'Something went wrong' })
        });

        render(<ItemModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Apple' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '5' } });
        fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalled();
            expect(mockProps.onItemAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });
    });

    it('closes when close button is clicked', () => {
        render(<ItemModal {...mockProps} />);
        fireEvent.click(screen.getByRole('button', { name: /x/i }));
        expect(mockProps.onClose).toHaveBeenCalled();
    });

    it('resets form state when modal is reopened', () => {
        const { rerender } = render(<ItemModal {...mockProps} isOpen={false} />);

        // Reopen the modal
        rerender(<ItemModal {...mockProps} isOpen={true} />);

        // Check that form fields are reset to initial state
        expect(screen.getByLabelText('Item Name')).toHaveValue('');

        // Fix for number inputs - can be empty string or zero
        const quantityInput = screen.getByLabelText('Quantity');
        expect(quantityInput.value === '' || quantityInput.value === '0').toBeTruthy();

        // Check emoji field has default value
        expect(screen.getByLabelText('Emoji (Unicode)')).toHaveValue('U+2754');
    });

    describe('Additional Error Handling Tests', () => {
        const fillFormWithValidData = (container) => {
            fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Apple' } });
            fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '5' } });
            fireEvent.change(screen.getByLabelText('Unit'), { target: { value: '1' } });
            fireEvent.change(screen.getByLabelText('Pantry Section'), { target: { value: '1' } });
        };

        it('displays error when server returns specific error message', async () => {
            // Mock error response with a specific error message
            global.fetch.mockResolvedValueOnce({
                ok: false,
                json: () => Promise.resolve({ error: 'Name already exists' })
            });

            render(<ItemModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('Name already exists');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onItemAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });

        it('displays error when server returns multiple error messages', async () => {
            // Mock error response with multiple errors
            global.fetch.mockResolvedValueOnce({
                ok: false,
                json: () => Promise.resolve({
                    errors: [
                        'Name is too short',
                        'Quantity must be positive'
                    ]
                })
            });

            render(<ItemModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('Name is too short, Quantity must be positive');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onItemAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });

        it('displays generic error message when no specific error is provided', async () => {
            // Mock error response without a specific error
            global.fetch.mockResolvedValueOnce({
                ok: false,
                json: () => Promise.resolve({})
            });

            render(<ItemModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('Failed to create item. Please try again.');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onItemAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });

        it('handles network errors gracefully', async () => {
            // Simulate a network error
            global.fetch.mockRejectedValueOnce(new Error('Network failure'));

            render(<ItemModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('An unexpected error occurred. Please try again.');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onItemAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });
    });
});