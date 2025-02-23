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

    it('opens modals when add buttons are clicked', () => {
        render(<Pantry groceries={mockGroceries} />);
        fireEvent.click(screen.getByText('Section'));
        expect(screen.getByText('Add New Section')).toBeInTheDocument();

        // Test Item modal
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

    it('refreshes data when sections are added', async () => {
        global.fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve(mockGroceries)
        });

        render(<Pantry groceries={mockGroceries} />);
        fireEvent.click(screen.getByText('Section'));

        const submitButton = screen.getByText('Create Section');
        const form = submitButton.closest('form');
        fireEvent.submit(form);

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith('/groceries', {
                headers: { 'Accept': 'application/json' }
            });
        });
    });

    it('handles refresh data error', async () => {
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});

        // Mock the two fetch calls that will happen
        const error = new Error('Failed to fetch');
        global.fetch
            .mockResolvedValueOnce({ // First call succeeds (for the modal)
                ok: true,
                json: () => Promise.resolve({ id: 1, name: 'Test Section' })
            })
            .mockRejectedValueOnce(error); // Second call fails (for the refresh)

        render(<Pantry groceries={mockGroceries} />);

        // Open modal and fill form
        fireEvent.click(screen.getByText('Section'));
        const nameInput = screen.getByLabelText('Section Name');
        fireEvent.change(nameInput, { target: { value: 'Test Section' } });

        // Submit form
        const submitButton = screen.getByText('Create Section');
        fireEvent.click(submitButton);

        // Wait for the error to be logged
        await waitFor(() => {
            expect(consoleSpy).toHaveBeenCalledWith(
                'Failed to refresh groceries:',
                expect.any(Error)
            );
        }, { timeout: 3000 });

        consoleSpy.mockRestore();
    });
});