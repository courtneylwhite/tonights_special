import React from 'react';
import { render, fireEvent, screen, act } from '@testing-library/react';
import ScrollableContainer from '@/components/ScrollableContainer';

// Mock the Lucide icons
jest.mock('lucide-react', () => ({
    ChevronDown: () => <div data-testid="chevron-down">ChevronDown</div>,
    ChevronUp: () => <div data-testid="chevron-up">ChevronUp</div>,
    ChevronLeft: () => <div data-testid="chevron-left">ChevronLeft</div>,
    ChevronRight: () => <div data-testid="chevron-right">ChevronRight</div>
}));

describe('ScrollableContainer', () => {
    const mockProps = {
        category: 'Fruits',
        items: [
            { id: 1, name: 'Apple', quantity: 5, unit: 'piece', emoji: 'U+1F34E' },
            { id: 2, name: 'Banana', quantity: 3, unit: 'piece', emoji: 'U+1F34C' },
            { id: 3, name: 'Orange', quantity: 2, unit: 'piece', emoji: 'U+1F34A' }
        ],
        categoryIndex: 0,
        isOpen: true,
        onToggle: jest.fn(),
        handleItemClick: jest.fn(),
        unicodeToEmoji: (str) => str ? '🍎' : '❓' // Mock function to convert unicode to emoji
    };

    beforeEach(() => {
        // Mock the scrollContainer functions and properties
        Element.prototype.scrollBy = jest.fn();
        Object.defineProperty(Element.prototype, 'scrollLeft', {
            configurable: true,
            get: jest.fn(() => 0)
        });
        Object.defineProperty(Element.prototype, 'scrollWidth', {
            configurable: true,
            get: jest.fn(() => 1000)
        });
        Object.defineProperty(Element.prototype, 'clientWidth', {
            configurable: true,
            get: jest.fn(() => 500)
        });
    });

    it('renders the category header correctly', () => {
        render(<ScrollableContainer {...mockProps} />);
        expect(screen.getByText('Fruits')).toBeInTheDocument();
        expect(screen.getByText('(3 items)')).toBeInTheDocument();
    });

    it('shows content when isOpen is true', () => {
        render(<ScrollableContainer {...mockProps} />);
        expect(screen.getByText('Apple')).toBeInTheDocument();
        expect(screen.getByText('Banana')).toBeInTheDocument();
        expect(screen.getByText('Orange')).toBeInTheDocument();
    });

    it('hides content when isOpen is false', () => {
        render(<ScrollableContainer {...mockProps} isOpen={false} />);
        expect(screen.queryByText('Apple')).not.toBeInTheDocument();
    });

    it('calls onToggle with the correct category when header is clicked', () => {
        render(<ScrollableContainer {...mockProps} />);
        fireEvent.click(screen.getByText('Fruits'));
        expect(mockProps.onToggle).toHaveBeenCalledWith('Fruits');
    });

    it('calls handleItemClick when an item is clicked', () => {
        render(<ScrollableContainer {...mockProps} />);
        // Find the Apple item container and click it
        const items = screen.getAllByText(/Apple|Banana|Orange/);
        fireEvent.click(items[0].closest('div'));
        expect(mockProps.handleItemClick).toHaveBeenCalledWith(1);
    });

    it('shows correct chevron icon based on isOpen state', () => {
        const { rerender } = render(<ScrollableContainer {...mockProps} />);
        expect(screen.getByTestId('chevron-up')).toBeInTheDocument();

        rerender(<ScrollableContainer {...mockProps} isOpen={false} />);
        expect(screen.getByTestId('chevron-down')).toBeInTheDocument();
    });

    it('displays right scroll arrow when content overflows', () => {
        render(<ScrollableContainer {...mockProps} />);

        // Simulate scroll check
        act(() => {
            const scrollEvent = new Event('scroll');
            screen.getByText('Apple').closest('.overflow-x-auto').dispatchEvent(scrollEvent);
        });

        expect(screen.getByTestId('chevron-right')).toBeInTheDocument();
    });

    it('scrolls right when right arrow is clicked', () => {
        render(<ScrollableContainer {...mockProps} />);

        // Simulate scroll check to make arrows appear
        act(() => {
            const scrollEvent = new Event('scroll');
            screen.getByText('Apple').closest('.overflow-x-auto').dispatchEvent(scrollEvent);
        });

        fireEvent.click(screen.getByTestId('chevron-right'));
        expect(Element.prototype.scrollBy).toHaveBeenCalledWith({
            left: 300,
            behavior: 'smooth'
        });
    });

    it('displays left scroll arrow when scrolled', () => {
        render(<ScrollableContainer {...mockProps} />);

        // Mock scrollLeft to simulate being scrolled
        Object.defineProperty(Element.prototype, 'scrollLeft', {
            configurable: true,
            get: jest.fn(() => 100)
        });

        // Simulate scroll check
        act(() => {
            const scrollEvent = new Event('scroll');
            screen.getByText('Apple').closest('.overflow-x-auto').dispatchEvent(scrollEvent);
        });

        expect(screen.getByTestId('chevron-left')).toBeInTheDocument();
    });

    it('scrolls left when left arrow is clicked', () => {
        // Mock scrollLeft to simulate being scrolled
        Object.defineProperty(Element.prototype, 'scrollLeft', {
            configurable: true,
            get: jest.fn(() => 100)
        });

        render(<ScrollableContainer {...mockProps} />);

        // Simulate scroll check to make arrows appear
        act(() => {
            const scrollEvent = new Event('scroll');
            screen.getByText('Apple').closest('.overflow-x-auto').dispatchEvent(scrollEvent);
        });

        fireEvent.click(screen.getByTestId('chevron-left'));
        expect(Element.prototype.scrollBy).toHaveBeenCalledWith({
            left: -300,
            behavior: 'smooth'
        });
    });

    it('shows "No items in this category" when items array is empty', () => {
        render(<ScrollableContainer {...mockProps} items={[]} />);
        expect(screen.getByText('No items in this category')).toBeInTheDocument();
    });
});