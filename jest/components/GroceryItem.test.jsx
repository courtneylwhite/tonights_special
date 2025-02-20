import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import GroceryItem from '@/components/GroceryItem';

describe('GroceryItem', () => {
    const mockGrocery = {
        id: 1,
        name: 'Apple',
        quantity: 5,
        unit: { name: 'piece' },
        emoji: 'U+1F34E'
    };

    beforeEach(() => {
        global.fetch = jest.fn();
    });

    it('renders grocery details correctly', () => {
        render(<GroceryItem grocery={mockGrocery} />);
        expect(screen.getByText('Apple')).toBeInTheDocument();
        expect(screen.getByText('5')).toBeInTheDocument();
    });

    it('handles increment correctly', async () => {
        global.fetch.mockResolvedValueOnce({ ok: true });
        render(<GroceryItem grocery={mockGrocery} />);

        fireEvent.click(screen.getByText('ChevronUp'));

        await waitFor(() => {
            expect(screen.getByText('6')).toBeInTheDocument();
        });
    });

    it('handles decrement correctly', async () => {
        global.fetch.mockResolvedValueOnce({ ok: true });
        render(<GroceryItem grocery={mockGrocery} />);

        fireEvent.click(screen.getByText('ChevronDown'));

        await waitFor(() => {
            expect(screen.getByText('4')).toBeInTheDocument();
        });
    });

    it('shows success state after successful update', async () => {
        global.fetch.mockResolvedValueOnce({ ok: true });
        render(<GroceryItem grocery={mockGrocery} />);

        fireEvent.click(screen.getByText('ChevronUp'));

        await waitFor(() => {
            expect(document.querySelector('.border-green-500')).toBeInTheDocument();
        });
    });

    it('shows error state after failed update', async () => {
        global.fetch.mockRejectedValueOnce(new Error('Failed to update'));
        render(<GroceryItem grocery={mockGrocery} />);

        fireEvent.click(screen.getByText('ChevronUp'));

        await waitFor(() => {
            expect(document.querySelector('.border-red-500')).toBeInTheDocument();
        });
    });
});
