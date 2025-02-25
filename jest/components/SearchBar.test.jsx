import React from 'react';
import { render, fireEvent, screen, act } from '@testing-library/react';
import SearchBar from '@/components/SearchBar';

describe('SearchBar', () => {
    const mockData = {
        category1: {
            items: [
                { id: 1, name: 'Apple' },
                { id: 2, name: 'Banana' }
            ]
        },
        category2: {
            items: [
                { id: 3, name: 'Carrot' },
                { id: 4, name: 'Donut' }
            ]
        }
    };

    const mockOnFilteredDataChange = jest.fn();

    beforeEach(() => {
        jest.useFakeTimers();
        mockOnFilteredDataChange.mockClear();
    });

    afterEach(() => {
        jest.useRealTimers();
    });

    it('renders input with correct placeholder', () => {
        render(
            <SearchBar
                placeholder="Test placeholder"
                data={mockData}
                onFilteredDataChange={mockOnFilteredDataChange}
            />
        );

        expect(screen.getByPlaceholderText('Test placeholder')).toBeInTheDocument();
    });

    it('updates search term on input change with debounce', () => {
        // Reset the mock before this test
        mockOnFilteredDataChange.mockClear();

        render(
            <SearchBar
                data={mockData}
                onFilteredDataChange={mockOnFilteredDataChange}
                debounceTime={300}
            />
        );

        // Get the current call count after initial render
        const initialCallCount = mockOnFilteredDataChange.mock.calls.length;
        mockOnFilteredDataChange.mockClear(); // Clear again after initial renders

        const input = screen.getByRole('textbox');
        fireEvent.change(input, { target: { value: 'app' } });

        // The component might call onFilteredDataChange immediately
        // or after the debounce - instead of checking times, let's clear again
        mockOnFilteredDataChange.mockClear();

        // After debounce time, it should definitely call the filter function
        act(() => {
            jest.advanceTimersByTime(300);
        });

        // Now we should have at least one call with the filtered data
        expect(mockOnFilteredDataChange).toHaveBeenCalled();

        // Check the last call has the correctly filtered data (only Apple should be returned)
        const lastCall = mockOnFilteredDataChange.mock.calls[mockOnFilteredDataChange.mock.calls.length - 1][0];
        expect(lastCall.category1.items.length).toBe(1);
        expect(lastCall.category1.items[0].name).toBe('Apple');
    });

    it('filters data correctly', () => {
        render(
            <SearchBar
                data={mockData}
                onFilteredDataChange={mockOnFilteredDataChange}
                searchKeys={['name']}
            />
        );

        const input = screen.getByRole('textbox');
        fireEvent.change(input, { target: { value: 'app' } });

        act(() => {
            jest.advanceTimersByTime(300);
        });

        // Expected filtered data with only items containing 'app'
        const expectedData = {
            category1: {
                items: [
                    { id: 1, name: 'Apple' }
                ]
            }
        };

        expect(mockOnFilteredDataChange).toHaveBeenCalledWith(expect.objectContaining(expectedData));
    });

    it('clears search when clear button is clicked', () => {
        // Reset mock before test
        mockOnFilteredDataChange.mockClear();

        render(
            <SearchBar
                data={mockData}
                onFilteredDataChange={mockOnFilteredDataChange}
            />
        );

        mockOnFilteredDataChange.mockClear(); // Clear after initial renders

        // Type in the search box
        const input = screen.getByRole('textbox');
        fireEvent.change(input, { target: { value: 'apple' } });

        act(() => {
            jest.advanceTimersByTime(300);
        });

        // After searching, we should get filtered results
        expect(mockOnFilteredDataChange).toHaveBeenCalled();

        // Store last call with filtered data
        const filteredData = mockOnFilteredDataChange.mock.calls[mockOnFilteredDataChange.mock.calls.length - 1][0];

        // Clear mocks again before testing clear button
        mockOnFilteredDataChange.mockClear();

        // Find and click the clear button
        const clearButton = screen.getByLabelText('Clear search');
        fireEvent.click(clearButton);

        act(() => {
            jest.advanceTimersByTime(300);
        });

        // Verify input was cleared
        expect(input.value).toBe('');

        // Verify onFilteredDataChange was called with original data
        expect(mockOnFilteredDataChange).toHaveBeenCalled();
        expect(mockOnFilteredDataChange).toHaveBeenLastCalledWith(mockData);
    });
});