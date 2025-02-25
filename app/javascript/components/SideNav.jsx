import React, { useState, useEffect } from 'react';
import { Menu, X, ChefHat, ShoppingCart, Archive, LogOut } from 'lucide-react';

const SideNav = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [currentPath, setCurrentPath] = useState('');

    useEffect(() => {
        setCurrentPath(window.location.pathname);
    }, []);

    const handleSignOut = async (e) => {
        e.preventDefault();

        const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

        try {
            const response = await fetch('/users/sign_out', {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': csrfToken,
                },
                credentials: 'same-origin'
            });

            if (response.ok) {
                window.location.href = '/';
            }
        } catch (error) {
            console.error('Sign out failed:', error);
        }
    };

    if (currentPath === '/') return null;

    return (
        <>
            {/* Hamburger button */}
            <button
                onClick={() => setIsOpen(true)}
                className="fixed top-4 left-4 z-30 p-2 bg-gray-800 hover:bg-amber-500 text-white hover:text-black rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-400"
                aria-label="Open menu"
            >
                <Menu size={24} />
            </button>

            {/* Overlay */}
            {isOpen && (
                <div
                    className="fixed inset-0 bg-black/40 backdrop-blur-[2px] z-40"
                    onClick={() => setIsOpen(false)}
                />
            )}

            {/* Side Navigation */}
            <div
                className={`fixed top-0 left-0 h-full w-64 bg-black border-r border-gray-800 z-50 transform transition-transform duration-300 ease-in-out ${
                    isOpen ? 'translate-x-0' : '-translate-x-full'
                }`}
            >
                <div className="p-4">
                    <button
                        onClick={() => setIsOpen(false)}
                        className="absolute top-4 right-4 text-amber-500 hover:text-amber-400"
                        aria-label="Close menu"
                    >
                        <X size={24} />
                    </button>

                    <nav className="mt-12 space-y-4">
                        {currentPath !== '/recipes' && (
                            <a
                                href="/Users/courtney/dev/tonights_special/app/javascript/components/RecipeBox"
                                className="flex items-center gap-3 text-white hover:bg-amber-500 hover:text-black p-3 rounded-lg transition-colors duration-200"
                            >
                                <ChefHat size={20}/>
                                <span>Recipes</span>
                            </a>
                        )}

                        {currentPath !== '/grocery_lists' && (
                            <a
                                href="/grocery_lists"
                                className="flex items-center gap-3 text-white hover:bg-amber-500 hover:text-black p-3 rounded-lg transition-colors duration-200"
                            >
                                <ShoppingCart size={20}/>
                                <span>Grocery Lists</span>
                            </a>
                        )}

                        {currentPath !== '/groceries' && (
                            <a
                                href="/pantry"
                                className="flex items-center gap-3 text-white hover:bg-amber-500 hover:text-black p-3 rounded-lg transition-colors duration-200"
                            >
                                <Archive size={20}/>
                                <span>Pantry</span>
                            </a>
                        )}

                        <div className="border-t border-gray-800 my-4"/>

                        <a
                            href="/users/sign_out"
                            onClick={handleSignOut}
                            className="flex items-center gap-3 text-white hover:bg-amber-500 hover:text-black p-3 rounded-lg transition-colors duration-200"
                        >
                            <LogOut size={20} />
                            <span>Sign Out</span>
                        </a>
                    </nav>
                </div>
            </div>
        </>
    );
};

export default SideNav;
