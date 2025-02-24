import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import Pantry from '@/components/Pantry';

describe('Pantry', () => {
    const mockGroceries = {
        'Fruits': {
            id: 1,
            items: [
                { id: 1, name: 'Apple', quantity: 5, unit: 'pieces', emoji: 'U+1F34E' },
                { id: 2, name: 'Banana', quantity: 3, unit: 'pieces', emoji: 'U+1F34C' }
            ],
            display_order: 1
        }
    };

    const mockUnits = [
        { id: 1, name: 'pieces' }
    ];

    beforeEach(() => {
        global.fetch = jest.fn();
    });

    it('renders empty state when no groceries', () => {
        render(<Pantry groceries={{}} />);
        expect(screen.getByText('No groceries in your pantry yet.')).toBeInTheDocument();
    });

    it('renders groceries when provided', () => {
        render(<Pantry groceries={mockGroceries} />);
        expect(screen.getByText('Fruits')).toBeInTheDocument();
        expect(screen.getByText('Apple')).toBeInTheDocument();
        expect(screen.getByText('Banana')).toBeInTheDocument();
    });

    it('filters groceries based on search term', () => {
        render(<Pantry groceries={mockGroceries} />);
        const searchInput = screen.getByPlaceholderText('Search your collection...');
        fireEvent.change(searchInput, { target: { value: 'Apple' } });
        expect(screen.getByText('Apple')).toBeInTheDocument();
        expect(screen.queryByText('Banana')).not.toBeInTheDocument();
    });

    it('opens item modal when grocery button is clicked', () => {
        render(<Pantry groceries={mockGroceries} />);
        // Use the actual button text from your component
        fireEvent.click(screen.getByText('Grocery'));
        expect(screen.getByText('Add New Item')).toBeInTheDocument();
    });

    it('handles shelf toggling', () => {
        render(<Pantry groceries={mockGroceries} />);
        const shelfHeader = screen.getByText('Fruits').closest('button');
        const shelfContent = screen.getByText('Fruits')
            .closest('.bg-gray-900\\/90')
            .querySelector('.transition-all');

        // Check initial expanded state
        expect(shelfContent).toHaveClass('max-h-[500px]');
        expect(shelfContent).toHaveClass('opacity-100');

        // Toggle closed
        fireEvent.click(shelfHeader);
        expect(shelfContent).toHaveClass('max-h-0');
        expect(shelfContent).toHaveClass('opacity-0');

        // Toggle open again
        fireEvent.click(shelfHeader);
        expect(shelfContent).toHaveClass('max-h-[500px]');
        expect(shelfContent).toHaveClass('opacity-100');
    });

    it('toggles all shelves', () => {
        render(<Pantry groceries={mockGroceries} />);
        const toggleAllButton = screen.getByText(/collapse all/i);
        const shelfContent = screen.getByText('Fruits')
            .closest('.bg-gray-900\\/90')
            .querySelector('.transition-all');

        // Initial state should be expanded
        expect(shelfContent).toHaveClass('max-h-[500px]');
        expect(shelfContent).toHaveClass('opacity-100');
        expect(toggleAllButton).toHaveTextContent(/collapse all/i);

        // Click to collapse all
        fireEvent.click(toggleAllButton);
        expect(shelfContent).toHaveClass('max-h-0');
        expect(shelfContent).toHaveClass('opacity-0');
        expect(screen.getByText(/expand all/i)).toBeInTheDocument();

        // Click to expand all
        fireEvent.click(screen.getByText(/expand all/i));
        expect(shelfContent).toHaveClass('max-h-[500px]');
        expect(shelfContent).toHaveClass('opacity-100');
        expect(screen.getByText(/collapse all/i)).toBeInTheDocument();
    });

    it('handles grocery item clicks', () => {
        const mockLocation = { href: '' };
        Object.defineProperty(window, 'location', {
            value: mockLocation,
            writable: true
        });

        render(<Pantry groceries={mockGroceries} />);
        fireEvent.click(screen.getByText('Apple'));
        expect(window.location.href).toBe('/groceries/1');
    });

    it('refreshes data when items are added', async () => {
        // Mock successful fetch responses
        global.fetch
            .mockResolvedValueOnce({ // First call succeeds for item creation
                ok: true,
                json: () => Promise.resolve({ id: 3, name: 'Orange' })
            })
            .mockResolvedValueOnce({ // Second call succeeds for data refresh
                ok: true,
                json: () => Promise.resolve(mockGroceries)
            });

        // Mock CSRF token
        document.body.innerHTML = '<meta name="csrf-token" content="test-token" />';

        render(<Pantry groceries={mockGroceries} units={mockUnits} />);

        // Open the ItemModal
        fireEvent.click(screen.getByText('Grocery'));

        // Fill in form data
        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Orange' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '3' } });

        // Fill required unit field
        fireEvent.change(screen.getByLabelText('Unit'), { target: { value: '1' } });

        // Fill required section field
        fireEvent.change(screen.getByLabelText('Pantry Section'), { target: { value: '1' } });

        // Form submission
        const form = screen.getByRole('button', { name: /create item/i }).closest('form');
        fireEvent.submit(form);

        // Wait for the fetch calls
        await waitFor(() => {
            // First fetch call should be for creating the item
            expect(global.fetch).toHaveBeenCalledWith('/groceries', expect.objectContaining({
                method: 'POST',
                headers: expect.objectContaining({
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': 'test-token'
                })
            }));

            // Second fetch call should be for refreshing data
            expect(global.fetch).toHaveBeenCalledWith('/groceries', {
                headers: { 'Accept': 'application/json' }
            });
        });
    });

    it('handles refresh data error', async () => {
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

        // Mock the two fetch calls that will happen
        global.fetch
            .mockResolvedValueOnce({ // First call succeeds (for the item creation)
                ok: true,
                json: () => Promise.resolve({ id: 1, name: 'Orange' })
            })
            .mockRejectedValueOnce(new Error('Failed to fetch')); // Second call fails (for the refresh)

        // Mock CSRF token
        document.body.innerHTML = '<meta name="csrf-token" content="test-token" />';

        render(<Pantry groceries={mockGroceries} units={mockUnits} />);

        // Open modal and fill form using the correct button text
        fireEvent.click(screen.getByText('Grocery'));

        // Fill out all required form fields
        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Orange' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '3' } });
        fireEvent.change(screen.getByLabelText('Unit'), { target: { value: '1' } });
        fireEvent.change(screen.getByLabelText('Pantry Section'), { target: { value: '1' } });

        // Form submission
        const form = screen.getByRole('button', { name: /create item/i }).closest('form');
        fireEvent.submit(form);

        // Wait for the error to be logged
        await waitFor(() => {
            // First check that the POST fetch was called
            expect(global.fetch).toHaveBeenCalledWith('/groceries', expect.objectContaining({
                method: 'POST'
            }));

            // Then check that the refresh fetch was called and caught the error
            expect(consoleSpy).toHaveBeenCalledWith(
                'Failed to refresh groceries:',
                expect.any(Error)
            );
        }, { timeout: 3000 });

        consoleSpy.mockRestore();
    });
});