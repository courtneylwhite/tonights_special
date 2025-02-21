import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import ShelfItems from '@/components/ShelfItems';

describe('ShelfItems', () => {
    const mockProps = {
        item: {
            id: 1,
            name: 'Apple',
            quantity: 5,
            unit: 'pieces',
            emoji: 'U+1F34E'
        },
        categoryIndex: 0,
        itemIndex: 0,
        onItemClick: jest.fn(),
        unicodeToEmoji: (unicode) => '🍎'
    };

    it('renders item details correctly', () => {
        render(<ShelfItems {...mockProps} />);
        expect(screen.getByText('Apple')).toBeInTheDocument();
        expect(screen.getByText('5 pieces')).toBeInTheDocument();
    });

    it('calls onItemClick with correct id when clicked', () => {
        render(<ShelfItems {...mockProps} />);
        fireEvent.click(screen.getByText('Apple'));
        expect(mockProps.onItemClick).toHaveBeenCalledWith(1);
    });
});