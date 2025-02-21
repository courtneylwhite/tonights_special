import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import Pantry from '@/components/Pantry';

describe('Pantry', () => {
    const mockGroceries = {
        'Fruits': [
            { id: 1, name: 'Apple', quantity: 5, unit: 'pieces', emoji: 'U+1F34E', display_order: 1 },
            { id: 2, name: 'Banana', quantity: 3, unit: 'pieces', emoji: 'U+1F34C', display_order: 2 }
        ]
    };

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
    });
});