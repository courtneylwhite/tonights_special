import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import RecipeModal from '@/components/RecipeModal';

describe('RecipeModal', () => {
    const mockProps = {
        isOpen: true,
        onClose: jest.fn(),
        onRecipeAdded: jest.fn(),
        recipeCategories: [
            { id: 1, name: 'Breakfast' },
            { id: 2, name: 'Lunch' }
        ]
    };

    beforeEach(() => {
        global.fetch = jest.fn();
        document.body.innerHTML = '<meta name="csrf-token" content="test-token" />';
        jest.clearAllMocks();
        console.error = jest.fn(); // Mock console.error to prevent cluttering test output
    });

    it('renders form fields when open', () => {
        render(<RecipeModal {...mockProps} />);
        expect(screen.getByLabelText('Recipe Name')).toBeInTheDocument();
        expect(screen.getByLabelText('Recipe Category')).toBeInTheDocument();
        expect(screen.getByLabelText('Ingredients')).toBeInTheDocument();
        expect(screen.getByLabelText('Instructions')).toBeInTheDocument();
        expect(screen.getByLabelText('Notes (Optional)')).toBeInTheDocument();
    });

    it('handles form submission successfully', async () => {
        // Mock successful API response
        const mockResponse = { id: 1, name: 'Chocolate Chip Cookies' };
        global.fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve(mockResponse)
        });

        render(<RecipeModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Recipe Name'), {
            target: { value: 'Chocolate Chip Cookies' }
        });
        fireEvent.change(screen.getByLabelText('Recipe Category'), {
            target: { value: '1' }
        });
        fireEvent.change(screen.getByLabelText('Ingredients'), {
            target: { value: '2 cups flour\n1 cup sugar' }
        });
        fireEvent.change(screen.getByLabelText('Instructions'), {
            target: { value: '1. Mix dry ingredients\n2. Bake' }
        });
        fireEvent.change(screen.getByLabelText('Notes (Optional)'), {
            target: { value: 'Family favorite' }
        });

        fireEvent.submit(screen.getByRole('button', { name: /create recipe/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith('/recipes', expect.any(Object));
            expect(mockProps.onRecipeAdded).toHaveBeenCalled();
            expect(mockProps.onClose).toHaveBeenCalled();
        });
    });

    it('handles form submission error', async () => {
        // Mock failed API response
        global.fetch.mockResolvedValueOnce({
            ok: false,
            json: () => Promise.resolve({ message: 'Something went wrong' })
        });

        render(<RecipeModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Recipe Name'), {
            target: { value: 'Chocolate Chip Cookies' }
        });
        fireEvent.change(screen.getByLabelText('Recipe Category'), {
            target: { value: '1' }
        });
        fireEvent.change(screen.getByLabelText('Ingredients'), {
            target: { value: '2 cups flour\n1 cup sugar' }
        });
        fireEvent.change(screen.getByLabelText('Instructions'), {
            target: { value: '1. Mix dry ingredients\n2. Bake' }
        });

        fireEvent.submit(screen.getByRole('button', { name: /create recipe/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalled();
            expect(mockProps.onRecipeAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });
    });

    it('closes when close button is clicked', () => {
        render(<RecipeModal {...mockProps} />);
        fireEvent.click(screen.getByRole('button', { name: /x/i }));
        expect(mockProps.onClose).toHaveBeenCalled();
    });

    it('resets form state when modal is reopened', () => {
        const { rerender } = render(<RecipeModal {...mockProps} isOpen={false} />);

        // Reopen the modal
        rerender(<RecipeModal {...mockProps} isOpen={true} />);

        // Check that form fields are reset to initial state
        expect(screen.getByLabelText('Recipe Name')).toHaveValue('');
        expect(screen.getByLabelText('Ingredients')).toHaveValue('');
        expect(screen.getByLabelText('Instructions')).toHaveValue('');
        expect(screen.getByLabelText('Notes (Optional)')).toHaveValue('');
    });

    it('toggles ingredients preview when button is clicked', async () => {
        render(<RecipeModal {...mockProps} />);

        // Enter ingredients to trigger preview option
        fireEvent.change(screen.getByLabelText('Ingredients'), {
            target: { value: '2 cups flour\n1 cup sugar' }
        });

        // Wait for the preview button to appear
        await waitFor(() => {
            expect(screen.getByText('Show Ingredients Preview')).toBeInTheDocument();
        });

        // Click the preview button
        fireEvent.click(screen.getByText('Show Ingredients Preview'));

        // Check if preview content is shown
        expect(screen.getByText('Preview (How your ingredients will be parsed)')).toBeInTheDocument();
        expect(screen.getByText('flour')).toBeInTheDocument();
        expect(screen.getByText('sugar')).toBeInTheDocument();

        // Click again to hide preview
        fireEvent.click(screen.getByText('Hide Ingredients Preview'));

        // Preview should be hidden
        expect(screen.queryByText('Preview (How your ingredients will be parsed)')).not.toBeInTheDocument();
    });

    describe('New Category Mode', () => {
        it('switches to add new category mode when "Add New Category" is selected', () => {
            render(<RecipeModal {...mockProps} />);

            const categorySelect = screen.getByLabelText('Recipe Category');
            fireEvent.change(categorySelect, { target: { value: 'new' } });

            // Should show the new category input
            expect(screen.getByLabelText('New Category Name')).toBeInTheDocument();
        });

        it('cancels new category mode when X button is clicked', () => {
            render(<RecipeModal {...mockProps} />);

            // First enter new category mode
            const categorySelect = screen.getByLabelText('Recipe Category');
            fireEvent.change(categorySelect, { target: { value: 'new' } });

            // Now find and click the cancel button (X)
            // Using a more specific approach to find the cancel button next to the New Category Name input
            const cancelButton = screen.getByLabelText('New Category Name')
                .parentElement.querySelector('button[type="button"]');
            fireEvent.click(cancelButton);

            // Should switch back to category select
            expect(screen.getByLabelText('Recipe Category')).toBeInTheDocument();
            expect(screen.queryByLabelText('New Category Name')).not.toBeInTheDocument();
        });
    });

    describe('Error Handling Tests', () => {
        const fillFormWithValidData = () => {
            fireEvent.change(screen.getByLabelText('Recipe Name'), {
                target: { value: 'Chocolate Chip Cookies' }
            });
            fireEvent.change(screen.getByLabelText('Recipe Category'), {
                target: { value: '1' }
            });
            fireEvent.change(screen.getByLabelText('Ingredients'), {
                target: { value: '2 cups flour\n1 cup sugar' }
            });
            fireEvent.change(screen.getByLabelText('Instructions'), {
                target: { value: '1. Mix dry ingredients\n2. Bake' }
            });
        };

        it('displays error when server returns specific error message', async () => {
            // Mock error response with a specific error message
            global.fetch.mockResolvedValueOnce({
                ok: false,
                json: () => Promise.resolve({ message: 'Recipe name already exists' })
            });

            render(<RecipeModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create recipe/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('Recipe name already exists');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onRecipeAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });

        it('displays error when server returns multiple error messages', async () => {
            // Mock error response with multiple errors
            global.fetch.mockResolvedValueOnce({
                ok: false,
                json: () => Promise.resolve({
                    errors: [
                        'Recipe name is too short',
                        'Instructions are required'
                    ]
                })
            });

            render(<RecipeModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create recipe/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('Recipe name is too short, Instructions are required');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onRecipeAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });

        it('displays generic error message when no specific error is provided', async () => {
            // Mock error response without a specific error
            global.fetch.mockResolvedValueOnce({
                ok: false,
                json: () => Promise.resolve({})
            });

            render(<RecipeModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create recipe/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('Failed to create recipe. Please try again.');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onRecipeAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });

        it('handles network errors gracefully', async () => {
            // Simulate a network error
            global.fetch.mockRejectedValueOnce(new Error('Network failure'));

            render(<RecipeModal {...mockProps} />);

            fillFormWithValidData();
            fireEvent.submit(screen.getByRole('button', { name: /create recipe/i }));

            await waitFor(() => {
                const errorMessage = screen.getByText('An unexpected error occurred. Please try again.');
                expect(errorMessage).toBeInTheDocument();
            });

            // Verify other interactions didn't occur
            expect(mockProps.onRecipeAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });
    });
});