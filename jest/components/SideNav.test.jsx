import React from 'react';
import { render, fireEvent, screen, waitFor } from '@testing-library/react';
import SideNav from '@/components/SideNav';

jest.mock('lucide-react', () => ({
    Menu: () => <div data-testid="menu-icon" />,
    X: () => <div data-testid="close-icon" />,
    ChefHat: () => <div data-testid="chef-icon" />,
    ShoppingCart: () => <div data-testid="cart-icon" />,
    Archive: () => <div data-testid="archive-icon" />,
    LogOut: () => <div data-testid="logout-icon" />
}));

describe('SideNav', () => {
    const mockLocation = new URL('http://localhost:3000/recipes');

    beforeEach(() => {
        // Mock window.location
        delete window.location;
        window.location = { ...mockLocation };

        // Set up CSRF token
        document.head.innerHTML = '<meta name="csrf-token" content="test-token" />';

        // Mock authentication by adding the meta tag
        document.head.innerHTML += '<meta name="user-authenticated" content="true" />';

        // Alternative: Mock cookies if you're using that authentication method
        Object.defineProperty(document, 'cookie', {
            writable: true,
            value: '_your_app_session=test-session-token',
        });
    });

    it('renders hamburger menu button when authenticated', () => {
        render(<SideNav />);
        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        expect(menuButton).toBeInTheDocument();
    });

    it('opens navigation when hamburger menu is clicked', () => {
        render(<SideNav />);
        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        fireEvent.click(menuButton);

        const nav = screen.getByRole('navigation');
        expect(nav).toBeInTheDocument();
    });

    it('closes navigation when close button is clicked', () => {
        render(<SideNav />);

        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        fireEvent.click(menuButton);

        const closeButton = screen.getByRole('button', { name: 'Close menu' });
        fireEvent.click(closeButton);

        const nav = screen.getByRole('navigation').parentElement.parentElement;
        expect(nav).toHaveClass('-translate-x-full');
    });

    it('closes navigation when overlay is clicked', () => {
        render(<SideNav />);

        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        fireEvent.click(menuButton);

        const overlay = screen.getByRole('navigation').parentElement.parentElement.previousSibling;
        fireEvent.click(overlay);

        const nav = screen.getByRole('navigation').parentElement.parentElement;
        expect(nav).toHaveClass('-translate-x-full');
    });

    it('does not render on home page even when authenticated', () => {
        window.location.pathname = '/';
        const { container } = render(<SideNav />);
        expect(container).toBeEmptyDOMElement();
    });

    it('does not render on sign-in page when authenticated', () => {
        window.location.pathname = '/users/sign_in';
        const { container } = render(<SideNav />);
        expect(container).toBeEmptyDOMElement();
    });

    it('shows correct navigation links based on current path', () => {
        window.location.pathname = '/recipes';
        render(<SideNav />);

        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        fireEvent.click(menuButton);

        expect(screen.queryByText('Recipes')).not.toBeInTheDocument();
        expect(screen.getByText('Groceries')).toBeInTheDocument();
        expect(screen.getByText('Sign Out')).toBeInTheDocument();
    });

    it('handles sign out successfully', async () => {
        global.fetch = jest.fn(() =>
            Promise.resolve({
                ok: true
            })
        );

        render(<SideNav />);

        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        fireEvent.click(menuButton);

        const signOutLink = screen.getByText('Sign Out');
        fireEvent.click(signOutLink);

        await waitFor(() => {
            expect(fetch).toHaveBeenCalledWith('/users/sign_out', {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': 'test-token'
                },
                credentials: 'same-origin'
            });
        });

        expect(window.location.href).toBe('/');
    });

    it('handles sign out failure', async () => {
        const consoleSpy = jest.spyOn(console, 'error').mockImplementation(() => {});
        global.fetch = jest.fn(() =>
            Promise.reject(new Error('Network error'))
        );

        render(<SideNav />);

        const menuButton = screen.getByRole('button', { name: 'Open menu' });
        fireEvent.click(menuButton);

        const signOutLink = screen.getByText('Sign Out');
        fireEvent.click(signOutLink);

        await waitFor(() => {
            expect(consoleSpy).toHaveBeenCalledWith('Sign out failed:', expect.any(Error));
        });

        consoleSpy.mockRestore();
    });

    it('renders nothing when not authenticated', () => {
        // Remove authentication
        document.head.innerHTML = '<meta name="csrf-token" content="test-token" />';
        document.cookie = '';

        const { container } = render(<SideNav />);
        expect(container).toBeEmptyDOMElement();
    });
});