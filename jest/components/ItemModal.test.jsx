import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import ItemModal from '@/components/ItemModal';

describe('ItemModal', () => {
    const mockProps = {
        isOpen: true,
        onClose: jest.fn(),
        onItemAdded: jest.fn(),
        grocerySections: [],
        units: []
    };

    beforeEach(() => {
        global.fetch = jest.fn();
        jest.clearAllMocks();
    });

    it('renders form fields when open', () => {
        render(<ItemModal {...mockProps} />);
        expect(screen.getByLabelText('Item Name')).toBeInTheDocument();
        expect(screen.getByLabelText('Quantity')).toBeInTheDocument();
        expect(screen.getByLabelText('Unit')).toBeInTheDocument();
        expect(screen.getByLabelText('Section')).toBeInTheDocument();
        expect(screen.getByLabelText('Emoji (Unicode)')).toBeInTheDocument();
    });

    it('handles form submission successfully', async () => {
        // Mock successful API response
        const mockResponse = { id: 1, name: 'Apple' };
        global.fetch.mockResolvedValueOnce({
            ok: true,
            json: () => Promise.resolve(mockResponse)
        });

        render(<ItemModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Apple' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '5' } });
        fireEvent.change(screen.getByLabelText('Unit'), { target: { value: '1' } });
        fireEvent.change(screen.getByLabelText('Section'), { target: { value: '1' } });
        fireEvent.change(screen.getByLabelText('Emoji (Unicode)'), { target: { value: 'U+1F34E' } });

        fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith('/groceries', expect.any(Object));
            expect(mockProps.onItemAdded).toHaveBeenCalled();
            expect(mockProps.onClose).toHaveBeenCalled();
        });
    });

    it('handles form submission error', async () => {
        // Mock failed API response
        global.fetch.mockResolvedValueOnce({
            ok: false,
            json: () => Promise.resolve({ errors: ['Something went wrong'] })
        });

        render(<ItemModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Item Name'), { target: { value: 'Apple' } });
        fireEvent.change(screen.getByLabelText('Quantity'), { target: { value: '5' } });
        fireEvent.submit(screen.getByRole('button', { name: /create item/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalled();
            expect(mockProps.onItemAdded).not.toHaveBeenCalled();
            expect(mockProps.onClose).not.toHaveBeenCalled();
        });
    });

    it('closes when close button is clicked', () => {
        render(<ItemModal {...mockProps} />);
        fireEvent.click(screen.getByRole('button', { name: /x/i }));
        expect(mockProps.onClose).toHaveBeenCalled();
    });
});