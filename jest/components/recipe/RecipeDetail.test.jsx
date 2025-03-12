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
            <button data-testid="save-button" onClick={() => props.onSave(props.recipe, props.recipeIngredients)}>Save</button>
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
});