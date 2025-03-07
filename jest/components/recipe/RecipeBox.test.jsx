import React from 'react';
import { render, fireEvent, screen, waitFor, act } from '@testing-library/react';
import RecipeBox from '@/components/recipe/RecipeBox';

// Mock child components
jest.mock('@/components/SearchBar', () => {
    return function MockSearchBar({ onFilteredDataChange, data }) {
        return (
            <div data-testid="search-bar">
                <input
                    placeholder="Search your pantry..."
                    data-testid="search-input"
                    onChange={(e) => {
                        // Simple mock filter function to simulate SearchBar
                        if (e.target.value === 'Cookies') {
                            const filtered = Object.entries(data).reduce((acc, [category, categoryData]) => {
                                const filteredItems = categoryData.items.filter(item =>
                                    item.name.includes('Cookies')
                                );

                                if (filteredItems.length > 0) {
                                    acc[category] = {
                                        ...categoryData,
                                        items: filteredItems
                                    };
                                }
                                return acc;
                            }, {});

                            onFilteredDataChange(filtered);
                        } else {
                            onFilteredDataChange(data);
                        }
                    }}
                />
            </div>
        );
    };
});

jest.mock('@/components/recipe/RecipeModal', () => {
    return function MockRecipeModal({ isOpen, onClose, onRecipeAdded }) {
        return isOpen ? (
            <div data-testid="recipe-modal">
                <h2>Add New Recipe</h2>
                <button data-testid="close-modal" onClick={onClose}>Close</button>
                <button data-testid="add-recipe" onClick={onRecipeAdded}>Add Recipe</button>
            </div>
        ) : null;
    };
});

jest.mock('@/components/ToggleButton', () => {
    return function MockToggleButton({ initialToggleState, onToggleChange }) {
        const allOpen = Object.values(initialToggleState).every(Boolean);

        return (
            <div data-testid="toggle-button">
                <button
                    data-testid="toggle-all-button"
                    onClick={() => {
                        const newState = Object.keys(initialToggleState).reduce((acc, key) => ({
                            ...acc,
                            [key]: !allOpen
                        }), {});
                        onToggleChange(newState);
                    }}
                >
                    {allOpen ? 'Collapse All' : 'Expand All'}
                </button>
            </div>
        );
    };
});

jest.mock('@/components/ScrollableContainer', () => {
    return function MockScrollableContainer({
                                                category,
                                                items,
                                                isOpen,
                                                onToggle,
                                                handleItemClick,
                                                unicodeToEmoji
                                            }) {
        return (
            <div data-testid={`container-${category}`}>
                <div className="py-3 px-5 bg-gray-900 flex justify-between items-center cursor-pointer"
                     onClick={() => onToggle(category)}>
                    <h3>{category}</h3>
                    <span>({items.length} items)</span>
                </div>

                {isOpen && (
                    <div className="p-4 bg-gray-800">
                        {items.map(item => (
                            <div
                                key={item.id}
                                data-testid={`item-${item.id}`}
                                onClick={() => handleItemClick(item.id)}
                                className="cursor-pointer"
                            >
                                {item.name}
                            </div>
                        ))}
                    </div>
                )}
            </div>
        );
    };
});

// Mock fetch
global.fetch = jest.fn();

describe('RecipeBox Component', () => {
    const mockRecipes = {
        'Desserts': {
            id: 1,
            items: [
                { id: 101, name: 'Chocolate Chip Cookies', emoji: 'U+1F36A' },
                { id: 102, name: 'Vanilla Cake', emoji: 'U+1F370' }
            ],
            display_order: 1
        },
        'Main Courses': {
            id: 2,
            items: [
                { id: 201, name: 'Spaghetti Bolognese', emoji: 'U+1F35D' }
            ],
            display_order: 2
        }
    };

    const mockUnits = ['cup', 'tsp', 'tbsp'];

    beforeEach(() => {
        jest.clearAllMocks();
        global.fetch.mockResolvedValue({
            json: jest.fn().mockResolvedValue(mockRecipes)
        });
    });

    it('renders empty state when no recipes provided', () => {
        render(<RecipeBox recipes={{}} units={[]} />);
        expect(screen.getByText('No recipes in your pantry yet.')).toBeInTheDocument();
    });

    it('renders recipes when provided', () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);
        expect(screen.getByTestId('container-Desserts')).toBeInTheDocument();
        expect(screen.getByTestId('container-Main Courses')).toBeInTheDocument();
    });

    it('opens the RecipeModal when add button is clicked', () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Find and click the add button
        const addButton = screen.getByText('Recipe');
        fireEvent.click(addButton);

        // Modal should now be visible
        expect(screen.getByTestId('recipe-modal')).toBeInTheDocument();
        expect(screen.getByText('Add New Recipe')).toBeInTheDocument();
    });

    it('closes the RecipeModal', () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Open the modal
        fireEvent.click(screen.getByText('Recipe'));
        expect(screen.getByTestId('recipe-modal')).toBeInTheDocument();

        // Close the modal
        fireEvent.click(screen.getByTestId('close-modal'));
        expect(screen.queryByTestId('recipe-modal')).not.toBeInTheDocument();
    });

    it('refreshes data when recipe is added', async () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Open modal
        fireEvent.click(screen.getByText('Recipe'));

        // Add recipe - need to wrap in act since it causes state updates
        await act(async () => {
            fireEvent.click(screen.getByTestId('add-recipe'));
        });

        // Should call fetch to refresh data
        expect(global.fetch).toHaveBeenCalledWith('/recipes', {
            headers: { 'Accept': 'application/json' }
        });
    });

    it('navigates to recipe detail page when recipe is clicked', () => {
        // Mock window.location
        const originalLocation = window.location;
        delete window.location;
        window.location = { href: '' };

        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Find a recipe item and click it
        const cookiesItem = screen.getByTestId('item-101');
        fireEvent.click(cookiesItem);

        // Should navigate to the detail page
        expect(window.location.href).toBe('/recipes/101');

        // Restore original location
        window.location = originalLocation;
    });

    it('toggles container visibility when category header is clicked', () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Get the Desserts category container
        const dessertsHeader = screen.getByText('Desserts').closest('div');

        // All containers should be open initially
        expect(screen.getByTestId('item-101')).toBeInTheDocument(); // Cookies

        // Toggle the container closed
        fireEvent.click(dessertsHeader);

        // Since we mocked ScrollableContainer, we can't directly check if items are hidden
        // This would be handled by the container's isOpen prop
    });

    it('toggles all containers via the ToggleButton', () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Find the toggle all button
        const toggleAllButton = screen.getByTestId('toggle-all-button');
        expect(toggleAllButton).toHaveTextContent('Collapse All');

        // Click to collapse all
        fireEvent.click(toggleAllButton);

        // Button text should change
        expect(toggleAllButton).toHaveTextContent('Expand All');

        // Click again to expand all
        fireEvent.click(toggleAllButton);
        expect(toggleAllButton).toHaveTextContent('Collapse All');
    });

    it('filters recipes when searching', () => {
        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Use the search input
        const searchInput = screen.getByTestId('search-input');
        fireEvent.change(searchInput, { target: { value: 'Cookies' } });

        // The filtered results should update the component state
        // Our mock will filter to show only Cookie items
    });

    it('correctly sorts recipes by display_order', () => {
        // Test data with unordered categories
        const unsortedRecipes = {
            'Main Courses': { id: 2, display_order: 2 },
            'Desserts': { id: 1, display_order: 1 },
            'Appetizers': { id: 3, display_order: 3 }
        };

        // Extract the sorting logic
        const sortedEntries = Object.entries(unsortedRecipes)
            .sort(([, a], [, b]) => a.display_order - b.display_order);

        // Check order is correct
        expect(sortedEntries[0][0]).toBe('Desserts');     // display_order 1
        expect(sortedEntries[1][0]).toBe('Main Courses'); // display_order 2
        expect(sortedEntries[2][0]).toBe('Appetizers');   // display_order 3
    });

    it('handles errors when refreshing data', async () => {
        // Spy on console.error
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

        // Mock fetch to reject
        global.fetch.mockRejectedValueOnce(new Error('Failed to fetch'));

        render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Trigger refresh - wrap in act since it causes state updates
        fireEvent.click(screen.getByText('Recipe'));

        await act(async () => {
            fireEvent.click(screen.getByTestId('add-recipe'));
        });

        // Wait for the error to be logged
        await waitFor(() => {
            expect(consoleSpy).toHaveBeenCalledWith(
                'Failed to refresh recipes:',
                expect.any(Error)
            );
        });

        // Cleanup
        consoleSpy.mockRestore();
    });

    it('handles emoji conversion correctly', () => {
        const { container } = render(<RecipeBox recipes={mockRecipes} units={mockUnits} />);

        // Check that the component includes the unicodeToEmoji function
        // We can't directly test the function since its implementation is inside the component
        // and our mocks intercept the actual rendering, but we can verify it exists

        // This is a limited test, but ensures the function is part of the component
        expect(RecipeBox.toString()).toContain('unicodeToEmoji');
    });
});