import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import SectionModal from '@/components/SectionModal';

describe('SectionModal', () => {
    const mockProps = {
        isOpen: true,
        onClose: jest.fn(),
        onSuccess: jest.fn()
    };

    beforeEach(() => {
        document.head.innerHTML = '<meta name="csrf-token" content="test-token" />';
        global.fetch = jest.fn();
    });

    it('renders form fields when open', () => {
        render(<SectionModal {...mockProps} />);
        expect(screen.getByLabelText('Section Name')).toBeInTheDocument();
        expect(screen.getByLabelText('Display Order')).toBeInTheDocument();
    });

    it('handles form submission', async () => {
        global.fetch.mockResolvedValueOnce({
            ok: true,
            text: () => Promise.resolve('{"success":true}')
        });

        render(<SectionModal {...mockProps} />);

        fireEvent.change(screen.getByLabelText('Section Name'), { target: { value: 'Fruits' } });
        fireEvent.change(screen.getByLabelText('Display Order'), { target: { value: '1' } });

        fireEvent.submit(screen.getByRole('button', { name: /create section/i }));

        await waitFor(() => {
            expect(global.fetch).toHaveBeenCalledWith('/grocery_sections', expect.any(Object));
        });
    });

    it('displays error message on failed submission', async () => {
        global.fetch.mockRejectedValueOnce(new Error('Failed to create section'));

        render(<SectionModal {...mockProps} />);

        fireEvent.submit(screen.getByRole('button', { name: /create section/i }));

        await waitFor(() => {
            expect(screen.getByText(/an unexpected error occurred/i)).toBeInTheDocument();
        });
    });
});
