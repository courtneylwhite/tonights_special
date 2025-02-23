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
        const shelfHeader = screen.getByText('Fruits');
        fireEvent.click(shelfHeader);
        // You might need to check for a class or attribute that indicates collapsed state
    });

    it('toggles all shelves', () => {
        render(<Pantry groceries={mockGroceries} />);
        const toggleAllButton = screen.getByRole('button', { name: /expand all|collapse all/i });
        fireEvent.click(toggleAllButton);
        // Add assertions for collapsed state
        fireEvent.click(toggleAllButton);
        // Add assertions for expanded state
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

    // it('refreshes data when sections are added', async () => {
    //     // Mock successful fetch response
    //     global.fetch.mockResolvedValueOnce({
    //         ok: true,
    //         json: () => Promise.resolve(mockGroceries)
    //     });
    //
    //     render(<Pantry groceries={mockGroceries} />);
    //
    //     // Find and render the SectionModal
    //     fireEvent.click(screen.getByText('Section'));
    //
    //     // Get the SectionModal component and call its onSuccess prop directly
    //     const modal = screen.getByText('Add New Section').closest('div');
    //     const form = modal.querySelector('form');
    //     fireEvent.submit(form);
    //
    //     // Check if fetch was called correctly
    //     await waitFor(() => {
    //         expect(global.fetch).toHaveBeenCalledWith('/groceries', {
    //             headers: { 'Accept': 'application/json' }
    //         });
    //     });
    // });

    // it('handles refresh data error', async () => {
    //     const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
    //     global.fetch.mockRejectedValueOnce(new Error('Failed to fetch'));
    //
    //     render(<Pantry groceries={mockGroceries} />);
    //
    //     // Find and render the SectionModal
    //     fireEvent.click(screen.getByText('Section'));
    //
    //     // Get the SectionModal component and call its onSuccess prop directly
    //     const modal = screen.getByText('Add New Section').closest('div');
    //     const form = modal.querySelector('form');
    //     fireEvent.submit(form);
    //
    //     // Check if error was logged correctly
    //     await waitFor(() => {
    //         expect(consoleSpy).toHaveBeenCalledWith(
    //             'Failed to refresh groceries:',
    //             expect.any(Error)
    //         );
    //     });
    //
    //     consoleSpy.mockRestore();
    // });
});