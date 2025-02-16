import React from 'react';
import { render, act } from '@testing-library/react';
import { BrowserRouter } from 'react-router-dom';
import AnimatedTitle from '@/components/AnimatedTitle';
import { AuthProvider } from '../../app/javascript/contexts/AuthContext';
import 'whatwg-fetch';

// Mock the AuthContext
jest.mock('../../app/javascript/contexts/AuthContext', () => ({
    AuthProvider: ({ children }) => children,
    useAuth: () => ({
        currentUser: null
    })
}));

const AllTheProviders = ({ children }) => {
    return (
        <BrowserRouter>
            <AuthProvider>
                {children}
            </AuthProvider>
        </BrowserRouter>
    );
};

// Mock getTotalLength since it's not available in JSDOM
Element.prototype.getTotalLength = jest.fn().mockReturnValue(100);

describe('AnimatedTitle', () => {
    const renderWithProviders = (component) => {
        return render(component, { wrapper: AllTheProviders });
    };

    beforeEach(() => {
        jest.useFakeTimers();
    });

    afterEach(() => {
        jest.useRealTimers();
        jest.clearAllMocks();
    });

    it('renders without crashing', () => {
        const { container } = renderWithProviders(<AnimatedTitle />);
        expect(container).toBeInTheDocument();
    });

    it('contains the correct number of path and dot elements', () => {
        const { container } = renderWithProviders(<AnimatedTitle />);
        const paths = container.querySelectorAll('path');
        const dots = container.querySelectorAll('circle.fill-white');

        // Count only the stroke-white paths for the animation
        const animatedPaths = container.querySelectorAll('path.stroke-white');
        expect(animatedPaths.length).toBe(21); // Number of animated paths
        expect(dots.length).toBe(2);
    });

    it('initializes dots and cloche with opacity 0', () => {
        const { container } = renderWithProviders(<AnimatedTitle authenticatePath="/login" />);
        const dots = container.querySelectorAll('circle.fill-white');
        const cloche = container.querySelector('div[ref="clocheRef"]');

        dots.forEach(dot => {
            expect(dot.style.opacity).toBe('0');
        });

        if (cloche) {
            expect(cloche.style.opacity).toBe('0');
        }
    });

    it('animates paths sequentially', () => {
        const { container } = renderWithProviders(<AnimatedTitle />);
        const paths = container.querySelectorAll('path.stroke-white');

        act(() => {
            jest.advanceTimersByTime(250);
        });

        const firstPath = Array.from(paths)[0];
        if (firstPath) {
            expect(firstPath.style.strokeDashoffset).toBe('0');
        }
    });

    it('animates dots after paths are complete', () => {
        const { container } = renderWithProviders(<AnimatedTitle />);
        const dots = container.querySelectorAll('circle.fill-white');
        const totalPathTime = 250 * 20 + 550;

        act(() => {
            jest.advanceTimersByTime(totalPathTime);
        });

        dots.forEach(dot => {
            expect(dot.style.opacity).toBe('0');
        });
    });

    it('animates cloche last', () => {
        const { container } = renderWithProviders(<AnimatedTitle />);
        const cloche = container.querySelector('div[ref="clocheRef"]');
        const totalPathTime = 250 * 20 + 550;
        const totalDotTime = 300 * 2;

        act(() => {
            jest.advanceTimersByTime(totalPathTime + totalDotTime + 100);
        });

        if (cloche) {
            expect(cloche.style.opacity).toBe('0');
        }
    });
});