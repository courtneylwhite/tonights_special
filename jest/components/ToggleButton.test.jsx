import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import ToggleButton from '@/components/ToggleButton';
import { Maximize2, Minimize2 } from 'lucide-react';

// Mock Lucide icons
jest.mock('lucide-react', () => ({
    Maximize2: () => <div data-testid="expand-icon">Expand Icon</div>,
    Minimize2: () => <div data-testid="collapse-icon">Collapse Icon</div>
}));

describe('ToggleButton', () => {
    it('renders correctly with object toggle state - all open', () => {
        const initialToggleState = { category1: true, category2: true };
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        // When all are open, should show collapse icon
        expect(screen.getByTestId('collapse-icon')).toBeInTheDocument();
    });

    it('renders correctly with object toggle state - all closed', () => {
        const initialToggleState = { category1: false, category2: false };
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        // When all are closed, should show expand icon
        expect(screen.getByTestId('expand-icon')).toBeInTheDocument();
    });

    it('renders correctly with object toggle state - mixed state', () => {
        const initialToggleState = { category1: true, category2: false };
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        // When in mixed state, should show expand icon
        expect(screen.getByTestId('expand-icon')).toBeInTheDocument();
    });

    it('updates toggle state when clicked - from all open', () => {
        const initialToggleState = { category1: true, category2: true };
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        fireEvent.click(screen.getByRole('button'));

        // Should call with all values set to false
        expect(mockOnToggleChange).toHaveBeenCalledWith({ category1: false, category2: false });
    });

    it('updates toggle state when clicked - from all closed', () => {
        const initialToggleState = { category1: false, category2: false };
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        fireEvent.click(screen.getByRole('button'));

        // Should call with all values set to true
        expect(mockOnToggleChange).toHaveBeenCalledWith({ category1: true, category2: true });
    });

    it('applies custom className when provided', () => {
        const initialToggleState = { category1: true };
        const customClassName = "custom-class";

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                buttonClassName={customClassName}
            />
        );

        const button = screen.getByRole('button');
        expect(button).toHaveClass(customClassName);
    });

    it('handles array toggle state correctly', () => {
        const initialToggleState = [true, false, true];
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        fireEvent.click(screen.getByRole('button'));

        // Since not all values are open/true, toggling should set all to true
        expect(mockOnToggleChange).toHaveBeenCalledWith([true, true, true]);
    });

    it('handles single boolean toggle state correctly', () => {
        const initialToggleState = true;
        const mockOnToggleChange = jest.fn();

        render(
            <ToggleButton
                initialToggleState={initialToggleState}
                onToggleChange={mockOnToggleChange}
            />
        );

        fireEvent.click(screen.getByRole('button'));

        // Should call with value toggled to false
        expect(mockOnToggleChange).toHaveBeenCalledWith(false);
    });
});