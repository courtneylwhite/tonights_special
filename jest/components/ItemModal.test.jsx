import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import ItemModal from '@/components/ItemModal';

describe('ItemModal', () => {
    const mockProps = {
        isOpen: true,
        onClose: jest.fn()
    };

    beforeEach(() => {
        global.fetch = jest.fn();
        // Mock window.location.reload
        const mockReload = jest.fn();
        Object.defineProperty(window, 'location', {
            value: { reload: mockReload },
            writable: true
        });
    });

    it('renders form fields when open', () => {
        render(<ItemModal {...mockProps} />);
        expect(screen.getByLabelText('Item Name')).toBeInTheDocument();
        expect(screen.getByLabelText('Quantity')).toBeInTheDocument();
        expect(screen.getByLabelText('Unit')).toBeInTheDocument();
        expect(screen.getByLabelText('Section')).toBeInTheDocument();
        expect(screen.getByLabelText('Emoji (Unicode)')).toBeInTheDocument();
    });

    it('handles form submission', async () => {
        global.fetch.mockResolvedValueOnce({ ok: true });
        render(<ItemModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Apple' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '5' } });
        fireEvent.change(screen.getByLabelText('Unit'), { target: { value: 'pieces' } });
        fireEvent.change(screen.getByLabelText('Section'), { target: { value: 'Fruits' } });
        fireEvent.change(screen.getByLabelText('Emoji (Unicode)'), { target: { value: 'U+1F34E' } });

        fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith('/api/groceries', expect.any(Object));
            expect(window.location.reload).toHaveBeenCalled();
        });
    });

    it('closes when close button is clicked', () => {
        render(<ItemModal {...mockProps} />);
        fireEvent.click(screen.getByText('X'));
        expect(mockProps.onClose).toHaveBeenCalled();
    });
});
