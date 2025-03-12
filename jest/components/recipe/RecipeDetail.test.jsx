import React from 'react';
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import '@testing-library/jest-dom';

// We need to mock Lucide and the RecipeViewer/Editor BEFORE importing RecipeDetail
// Mock lucide-react icons
jest.mock('lucide-react', () => ({
    ChevronLeft: () => <div data-testid="mock-chevron-left">Back</div>
}));

// Mock the RecipeViewer and RecipeEditor components
jest.mock('../../../app/javascript/components/recipe/RecipeViewer', () => {
    const MockRecipeViewer = jest.fn(props => (
        <div data-testid="recipe-viewer">
            <h1>{props.recipe.name}</h1>
            <button data-testid="edit-button" onClick={props.onEdit}>Edit</button>
            <button data-testid="toggle-completion" onClick={props.onToggleCompletion}>
                {props.recipe.completed ? 'Completed' : 'Mark Complete'}
            </button>
            <div data-testid="ingredients-count">{props.recipeIngredients.length}</div>
        </div>
    ));
    return MockRecipeViewer;
});

jest.mock('../../../app/javascript/components/recipe/RecipeEditor', () => {
    const MockRecipeEditor = jest.fn(props => (
        <div data-testid="recipe-editor">
            <h1>{props.recipe.name}</h1>
            <button data-testid="save-button" onClick={() => props.onSave({
                ...props.recipe,
                name: 'Updated Recipe Name',
                instructions: 'Updated Instructions',
                notes: 'Updated Notes',
                recipe_category_id: 2
            }, props.recipeIngredients)}>Save</button>
            <button data-testid="cancel-button" onClick={props.onCancel}>Cancel</button>
            <button data-testid="delete-button" onClick={props.onDelete}>Delete</button>
        </div>
    ));
    return MockRecipeEditor;
});

// Now import RecipeDetail AFTER the mocks are set up
import RecipeDetail from '../../../app/javascript/components/recipe/RecipeDetail';

// Mock fetch
global.fetch = jest.fn();

// Mock document.querySelector for CSRF token
document.querySelector = jest.fn(() => ({ content: 'fake-csrf-token' }));

describe('RecipeDetail Component', () => {
    const mockRecipe = {
        id: 1,
        name: 'Pancakes',
        instructions: 'Mix and cook',
        notes: 'Serve with maple syrup',
        completed: false,
        recipe_category_id: 1,
        recipe_category: { name: 'Breakfast' }
    };

    const mockIngredients = [
        { id: 1, name: 'Flour', quantity: 2, unit_id: 1, unit_name: 'cup', grocery_id: 101 },
        { id: 2, name: 'Milk', quantity: 1, unit_id: 2, unit_name: 'cup', grocery_id: 102 }
    ];

    const mockUnits = [
        { id: 1, name: 'cup', abbreviation: 'c' },
        { id: 2, name: 'tablespoon', abbreviation: 'tbsp' }
    ];

    const mockCategories = [
        { id: 1, name: 'Breakfast' },
        { id: 2, name: 'Dinner' }
    ];

    beforeEach(() => {
        fetch.mockClear();
        document.querySelector.mockClear();
        jest.clearAllMocks();

        // Default fetch response
        fetch.mockImplementation(() => Promise.resolve({
            ok: true,
            json: () => Promise.resolve({})
        }));

        // Reset window.location
        delete window.location;
        window.location = { href: '' };
    });

    afterEach(() => {
        // Restore original window.location
        if (typeof window.location.href === 'string') {
            window.location.href = '';
        }
    });

    test('renders back button', () => {
        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        expect(screen.getByTestId('mock-chevron-left')).toBeInTheDocument();
        expect(screen.getByRole('button', { name: /go back/i })).toBeInTheDocument();
    });

    test('back button navigates to recipes index', () => {
        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Click back button
        fireEvent.click(screen.getByRole('button', { name: /go back/i }));

        // Check if navigation occurred
        expect(window.location.href).toBe('/recipes');
    });

    test('renders RecipeViewer by default', () => {
        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Check that the viewer is displayed
        expect(screen.getByTestId('recipe-viewer')).toBeInTheDocument();
    });

    test('switches to edit mode when clicking the edit button', () => {
        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Click the edit button
        fireEvent.click(screen.getByTestId('edit-button'));

        // Check that the editor is displayed
        expect(screen.getByTestId('recipe-editor')).toBeInTheDocument();
    });

    test('fetches recipe categories when they are empty and edit is clicked', async () => {
        // Mock the fetch response for categories
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: true,
            json: () => Promise.resolve([
                { id: 1, name: 'Breakfast' },
                { id: 2, name: 'Dinner' },
                { id: 3, name: 'Dessert' }
            ])
        }));

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={[]} // Empty categories to trigger fetch
            />
        );

        // Click the edit button
        fireEvent.click(screen.getByTestId('edit-button'));

        // Check that categories were fetched
        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/recipe_categories', expect.any(Object));
        });
    });

    test('returns to view mode when clicking the cancel button', () => {
        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Then click cancel
        fireEvent.click(screen.getByTestId('cancel-button'));

        // Check that we're back to viewer mode
        expect(screen.getByTestId('recipe-viewer')).toBeInTheDocument();
    });

    test('saves changes when clicking the save button', async () => {
        // Mock the successful save
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
                recipe: {
                    ...mockRecipe,
                    name: 'Updated Recipe Name',
                    instructions: 'Updated Instructions',
                    notes: 'Updated Notes',
                    recipe_category_id: 2
                },
                recipe_ingredients: mockIngredients
            })
        }));

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Save the changes
        fireEvent.click(screen.getByTestId('save-button'));

        // Check that the fetch was called with correct params
        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/recipes/1', expect.objectContaining({
                method: 'PATCH',
                headers: expect.objectContaining({
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': 'fake-csrf-token'
                })
            }));
        });

        // Check that we're back to viewer mode
        await waitFor(() => {
            expect(screen.getByTestId('recipe-viewer')).toBeInTheDocument();
        });
    });

    test('handles save error correctly', async () => {
        // Mock a failed save
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: false,
            status: 422,
            statusText: 'Unprocessable Entity'
        }));

        // Mock console.error to prevent test output noise
        jest.spyOn(console, 'error').mockImplementation(() => {});

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Try to save
        fireEvent.click(screen.getByTestId('save-button'));

        // Check that error handling occurred
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Failed to update recipe');
        });

        // We should still be in edit mode
        expect(screen.getByTestId('recipe-editor')).toBeInTheDocument();
    });

    test('toggles completion status', async () => {
        // Mock the completion toggle response
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
                recipe: {
                    ...mockRecipe,
                    completed: true,
                    completed_at: '2023-04-01T12:00:00Z'
                }
            })
        }));

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Click the toggle completion button
        fireEvent.click(screen.getByTestId('toggle-completion'));

        // Check that the API was called correctly
        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/recipes/1/mark_completed', expect.objectContaining({
                method: 'POST'
            }));
        });
    });

    test('toggles completion status for already completed recipe', async () => {
        const completedRecipe = {
            ...mockRecipe,
            completed: true,
            completed_at: '2023-04-01T12:00:00Z'
        };

        // Mock the completion toggle response
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
                recipe: {
                    ...completedRecipe,
                    completed: false,
                    completed_at: null
                }
            })
        }));

        render(
            <RecipeDetail
                recipe={completedRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Click the toggle completion button
        fireEvent.click(screen.getByTestId('toggle-completion'));

        // Check that the API was called correctly
        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/recipes/1/mark_incomplete', expect.objectContaining({
                method: 'POST'
            }));
        });
    });

    test('handles completion toggle error', async () => {
        // Mock a failed toggle
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: false,
            status: 500,
            statusText: 'Internal Server Error'
        }));

        // Mock console.error to prevent test output noise
        jest.spyOn(console, 'error').mockImplementation(() => {});

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Click the toggle completion button
        fireEvent.click(screen.getByTestId('toggle-completion'));

        // Check that error handling occurred
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Failed to update recipe');
        });
    });

    test('deletes recipe when delete button is clicked', async () => {
        // Mock the successful delete
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: true
        }));

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Click delete
        fireEvent.click(screen.getByTestId('delete-button'));

        // Check that the API was called correctly
        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/recipes/1', expect.objectContaining({
                method: 'DELETE'
            }));
        });

        // Check that we're redirected
        expect(window.location.href).toBe('/recipes');
    });

    test('handles delete error correctly', async () => {
        // Mock a failed delete
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: false,
            status: 500,
            statusText: 'Internal Server Error'
        }));

        // Mock console.error to prevent test output noise
        jest.spyOn(console, 'error').mockImplementation(() => {});

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Try to delete
        fireEvent.click(screen.getByTestId('delete-button'));

        // Check that error handling occurred
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Failed to delete recipe');
        });

        // We should not be redirected
        expect(window.location.href).not.toBe('/recipes');
    });

    test('handles successful API calls with appropriate feedback', async () => {
        // Mock a successful save
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: true,
            json: () => Promise.resolve({
                recipe: {
                    ...mockRecipe,
                    name: 'Updated Recipe Name'
                },
                recipe_ingredients: mockIngredients
            })
        }));

        // Spy on setTimeout to verify it gets called
        jest.useFakeTimers();
        jest.spyOn(global, 'setTimeout');

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Save the changes
        fireEvent.click(screen.getByTestId('save-button'));

        // Verify the API call happened
        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/recipes/1', expect.objectContaining({
                method: 'PATCH'
            }));
        });

        // Verify setTimeout was called (for feedback timeout)
        expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 2000);

        // Fast-forward timer
        jest.advanceTimersByTime(2000);

        // Cleanup
        jest.useRealTimers();
    });

    test('handles API errors with appropriate feedback', async () => {
        // Mock a failed save
        fetch.mockImplementationOnce(() => Promise.resolve({
            ok: false,
            status: 422,
            statusText: 'Unprocessable Entity'
        }));

        // Spy on console.error
        jest.spyOn(console, 'error').mockImplementation(() => {});

        // Spy on setTimeout
        jest.useFakeTimers();
        jest.spyOn(global, 'setTimeout');

        render(
            <RecipeDetail
                recipe={mockRecipe}
                recipeIngredients={mockIngredients}
                units={mockUnits}
                recipeCategories={mockCategories}
            />
        );

        // Go to edit mode
        fireEvent.click(screen.getByTestId('edit-button'));

        // Try to save
        fireEvent.click(screen.getByTestId('save-button'));

        // Verify error was logged
        await waitFor(() => {
            expect(console.error).toHaveBeenCalledWith('Failed to update recipe');
        });

        // Verify setTimeout was called (for feedback timeout)
        expect(setTimeout).toHaveBeenCalledWith(expect.any(Function), 2000);

        // Fast-forward timer
        jest.advanceTimersByTime(2000);

        // Cleanup
        jest.useRealTimers();
    });
});