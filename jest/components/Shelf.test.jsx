// Shelf.test.jsx
import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import Shelf from '@/components/Shelf';

// Mock the Lucide icons
jest.mock('lucide-react', () => ({
    ChevronDown: () => <div data-testid="chevron-down">ChevronDown</div>,
    ChevronUp: () => <div data-testid="chevron-up">ChevronUp</div>
}));

// Mock the ShelfItems component
jest.mock('@/components/ShelfItems', () => {
    return function MockShelfItems({ item }) {
        return (
            <div data-testid="shelf-item" className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-4">
                {item.name}
            </div>
        );
    };
});

describe('Shelf', () => {
    const defaultProps = {
        category: 'Fruits',
        items: [
            { id: 1, name: 'Apple', quantity: 5, unit: 'pieces', emoji: 'U+1F34E' },
            { id: 2, name: 'Banana', quantity: 3, unit: 'pieces', emoji: 'U+1F34C' }
        ],
        categoryIndex: 0,
        isOpen: false,
        onToggle: jest.fn(),
        handleGroceryClick: jest.fn(),
        unicodeToEmoji: jest.fn().mockImplementation(() => '🍎')
    };

    beforeEach(() => {
        jest.clearAllMocks();
    });

    it('renders without crashing', () => {
        render(<Shelf {...defaultProps} />);
        expect(screen.getByText('Fruits')).toBeInTheDocument();
    });

    it('shows correct chevron based on isOpen state', () => {
        const { rerender } = render(<Shelf {...defaultProps} />);
        expect(screen.getByTestId('chevron-down')).toBeInTheDocument();

        rerender(<Shelf {...defaultProps} isOpen={true} />);
        expect(screen.getByTestId('chevron-up')).toBeInTheDocument();
    });

    it('calls onToggle when header is clicked', () => {
        render(<Shelf {...defaultProps} />);
        fireEvent.click(screen.getByText('Fruits'));
        expect(defaultProps.onToggle).toHaveBeenCalledWith('Fruits');
    });

    it('renders items when open', () => {
        render(<Shelf {...defaultProps} isOpen={true} />);
        expect(screen.getByText('Apple')).toBeInTheDocument();
        expect(screen.getByText('Banana')).toBeInTheDocument();
    });

    it('hides items when closed', () => {
        const { container } = render(<Shelf {...defaultProps} isOpen={false} />);
        const itemsContainer = container.querySelector('.max-h-0');
        expect(itemsContainer).toBeInTheDocument();
    });

    it('applies animation delay based on categoryIndex', () => {
        const { container } = render(<Shelf {...defaultProps} categoryIndex={2} />);
        const shelf = container.firstChild;
        expect(shelf).toHaveStyle({ animationDelay: '200ms' });
    });
});