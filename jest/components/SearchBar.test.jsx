import React from 'react';
import { render, fireEvent, screen } from '@testing-library/react';
import SearchBar from '@/components/SearchBar';

describe('SearchBar', () => {
    const mockProps = {
        searchTerm: '',
        setSearchTerm: jest.fn()
    };

    it('renders input with correct placeholder', () => {
        render(<SearchBar {...mockProps} />);
        expect(screen.getByPlaceholderText('Search your collection...')).toBeInTheDocument();
    });

    it('calls setSearchTerm on input change', () => {
        render(<SearchBar {...mockProps} />);
        const input = screen.getByPlaceholderText('Search your collection...');
        fireEvent.change(input, { target: { value: 'apple' } });
        expect(mockProps.setSearchTerm).toHaveBeenCalledWith('apple');
    });

    it('displays the current searchTerm', () => {
        render(<SearchBar {...mockProps} searchTerm="banana" />);
        const input = screen.getByPlaceholderText('Search your collection...');
        expect(input.value).toBe('banana');
    });
});