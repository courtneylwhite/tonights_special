import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import ToggleButton from '@/components/ToggleButton';

describe('ToggleButton', () => {
    const mockProps = {
        areAllOpen: false,
        toggleAll: jest.fn()
    };

    it('shows correct text based on areAllOpen prop', () => {
        const { rerender } = render(<ToggleButton {...mockProps} />);
        expect(screen.getByText('Expand All')).toBeInTheDocument();

        rerender(<ToggleButton {...mockProps} areAllOpen={true} />);
        expect(screen.getByText('Collapse All')).toBeInTheDocument();
    });

    it('calls toggleAll when clicked', () => {
        render(<ToggleButton {...mockProps} />);
        fireEvent.click(screen.getByRole('button'));
        expect(mockProps.toggleAll).toHaveBeenCalled();
    });
});