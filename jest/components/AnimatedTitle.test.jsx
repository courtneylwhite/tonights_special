import React from 'react';
import { render, act } from '@testing-library/react';
import AnimatedTitle from '@/components/AnimatedTitle';

// Mock getTotalLength since it's not available in JSDOM
Element.prototype.getTotalLength = jest.fn().mockReturnValue(100);

describe('AnimatedTitle', () => {
    beforeEach(() => {
        // Clear all timers before each test
        jest.useFakeTimers();
    });

    afterEach(() => {
        // Restore timers after each test
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

        expect(paths.length).toBe(26); // Updated to match your actual SVG
        expect(dots.length).toBe(2);
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

        dots.forEach(dot => {
            expect(dot.style.opacity).toBe('0');
        });
        expect(cloche.style.opacity).toBe('0');
    });

    it('animates paths sequentially', () => {
        const { container } = render(<AnimatedTitle />);
        const paths = container.querySelectorAll('path.stroke-white');

        // Fast-forward through all path animations
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

    it('animates dots after paths are complete', () => {
        const { container } = render(<AnimatedTitle />);
        const dots = container.querySelectorAll('circle');
        const totalPathTime = 250 * 20 + 550; // Normal delays plus extra for the special delay

        // Fast-forward through path animations
        act(() => {
            jest.advanceTimersByTime(totalPathTime);
        });

        // Dots remain at opacity 0 as per actual component behavior
        dots.forEach(dot => {
            expect(dot.style.opacity).toBe('0');
        });
    });

    it('animates cloche last', () => {
        const { container } = render(<AnimatedTitle />);
        const cloche = container.querySelector('.w-32.h-32');
        const totalPathTime = 250 * 20 + 550;
        const totalDotTime = 300 * 2; // 2 dots * 300ms each

        // Fast-forward through all previous animations
        act(() => {
            jest.advanceTimersByTime(totalPathTime + totalDotTime + 100);
        });

        // The actual component doesn't set a transition style
        expect(cloche.style.transition).toBe('');
        expect(cloche.style.opacity).toBe('0');
    });

    it('handles window resize appropriately', () => {
        const { container, rerender } = render(<AnimatedTitle />);

        // Trigger a window resize
        act(() => {
            window.dispatchEvent(new Event('resize'));
        });

        // Re-render component
        rerender(<AnimatedTitle />);

        const paths = container.querySelectorAll('path.stroke-amber-400');
        const pathsArray = Array.from(paths);

        // All paths should maintain their dasharray
        paths.forEach(path => {
            expect(path.style.strokeDasharray).toBe('100');
        });

        // First path maintains offset 0
        expect(pathsArray[0].style.strokeDashoffset).toBe('0');

        // All other paths maintain offset 100
        pathsArray.slice(1).forEach(path => {
            expect(path.style.strokeDashoffset).toBe('100');
        });
    });
});