import React from 'react';
import { render, act, fireEvent } from '@testing-library/react';
import AnimatedTitle from '@/components/AnimatedTitle';

// Mock window.location
const mockLocation = {
    href: ''
};
Object.defineProperty(window, 'location', {
    value: mockLocation,
    writable: true
});

// Mock getTotalLength since it's not available in JSDOM
Element.prototype.getTotalLength = jest.fn().mockReturnValue(100);

describe('AnimatedTitle', () => {
    beforeEach(() => {
        jest.useFakeTimers();
        window.location.href = '';
    });

    afterEach(() => {
        jest.useRealTimers();
        jest.clearAllMocks();
    });

    it('renders without crashing', () => {
        const { container } = render(<AnimatedTitle />);
        expect(container).toBeInTheDocument();
    });

    it('contains the correct number of path and dot elements', () => {
        const { container } = render(<AnimatedTitle />);
        const paths = container.querySelectorAll('path');
        const dots = container.querySelectorAll('circle');
        const button = container.querySelector('button');

        expect(paths.length).toBe(26);
        expect(dots.length).toBe(2);
        expect(button).toBeInTheDocument();
    });

    it('initializes paths with correct stroke properties', () => {
        const { container } = render(<AnimatedTitle />);
        const paths = container.querySelectorAll('path.stroke-amber-400');

        // Check that all paths have the correct dasharray
        paths.forEach(path => {
            expect(path.style.strokeDasharray).toBe('100');
        });

        // Convert paths to array to access by index
        const pathsArray = Array.from(paths);

        // First path has offset 0
        expect(pathsArray[0].style.strokeDashoffset).toBe('0');

        // All other paths have offset 100
        pathsArray.slice(1).forEach(path => {
            expect(path.style.strokeDashoffset).toBe('100');
        });
    });

    it('initializes dots and cloche with opacity 0', () => {
        const { container } = render(<AnimatedTitle />);
        const dots = container.querySelectorAll('circle');
        const cloche = container.querySelector('.w-32.h-32');
        const button = container.querySelector('button').parentElement;

        dots.forEach(dot => {
            expect(dot.style.opacity).toBe('0');
        });
        expect(cloche.style.opacity).toBe('0');
        expect(button.style.opacity).toBe('0');
    });

    it('animates paths sequentially', () => {
        const { container } = render(<AnimatedTitle />);
        const paths = container.querySelectorAll('path.stroke-amber-400');

        paths.forEach((_, index) => {
            act(() => {
                jest.advanceTimersByTime(index === 12 ? 800 : 250);
            });

            // Check that current path has been animated
            if (paths[index]) {
                expect(paths[index].style.strokeDashoffset).toBe('0');
            }
        });
    });

    it('keeps dots at opacity 0 after path animations', () => {
        const { container } = render(<AnimatedTitle />);
        const dots = container.querySelectorAll('circle');
        const totalPathTime = 250 * 20 + 550;

        act(() => {
            jest.advanceTimersByTime(totalPathTime);
        });

        dots.forEach(dot => {
            expect(dot.style.opacity).toBe('0');
        });
    });

    it('keeps cloche and button opacity at 0 until final animation', () => {
        const { container } = render(<AnimatedTitle />);
        const cloche = container.querySelector('.w-32.h-32');
        const button = container.querySelector('button').parentElement;
        const totalPathTime = 250 * 20 + 550;
        const totalDotTime = 300 * 2;

        act(() => {
            jest.advanceTimersByTime(totalPathTime + totalDotTime + 100);
        });

        expect(cloche.style.transition).toBe('');
        expect(cloche.style.opacity).toBe('0');
        expect(button.style.opacity).toBe('0');
    });

    it('handles window resize appropriately', () => {
        const { container, rerender } = render(<AnimatedTitle />);

        act(() => {
            window.dispatchEvent(new Event('resize'));
        });

        rerender(<AnimatedTitle />);

        const paths = container.querySelectorAll('path.stroke-amber-400');
        const pathsArray = Array.from(paths);

        paths.forEach(path => {
            expect(path.style.strokeDasharray).toBe('100');
        });

        expect(pathsArray[0].style.strokeDashoffset).toBe('0');

        pathsArray.slice(1).forEach(path => {
            expect(path.style.strokeDashoffset).toBe('100');
        });
    });

    it('handles null refs gracefully', () => {
        const originalError = console.error;
        console.error = jest.fn();

        const { container } = render(<AnimatedTitle />);

        const paths = container.querySelectorAll('path.stroke-amber-400');
        paths[0].remove();

        act(() => {
            jest.runAllTimers();
        });

        expect(container).toBeInTheDocument();
        console.error = originalError;
    });

    it('redirects to sign in page when button is clicked', () => {
        const { container } = render(<AnimatedTitle />);
        const button = container.querySelector('button');

        act(() => {
            jest.runAllTimers();
            fireEvent.click(button);
        });

        expect(window.location.href).toBe('/users/sign_in');
    });
});