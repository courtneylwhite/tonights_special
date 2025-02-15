// src/contexts/AuthContext.js
import React, { createContext, useContext, useState, useEffect } from 'react';

const AuthContext = createContext(null);

export const AuthProvider = ({ children }) => {
    const [currentUser, setCurrentUser] = useState(null);
    const [loading, setLoading] = useState(true);

    useEffect(() => {
        // Check session on mount
        checkAuthStatus();
    }, []);

    const checkAuthStatus = async () => {
        try {
            const response = await fetch('/api/auth/status');
            if (response.ok) {
                const data = await response.json();
                setCurrentUser(data.user);
            }
        } catch (error) {
            console.error('Auth status check failed:', error);
        } finally {
            setLoading(false);
        }
    };

    const signIn = async (email, password) => {
        try {
            const response = await fetch('/users/sign_in', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    user: { email, password }
                })
            });

            if (!response.ok) throw new Error('Sign in failed');

            const data = await response.json();
            setCurrentUser(data.user);
            return data;
        } catch (error) {
            throw error;
        }
    };

    const signUp = async (email, password, passwordConfirmation) => {
        try {
            const response = await fetch('/users', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    user: {
                        email,
                        password,
                        password_confirmation: passwordConfirmation
                    }
                })
            });

            if (!response.ok) throw new Error('Sign up failed');

            const data = await response.json();
            setCurrentUser(data.user);
            return data;
        } catch (error) {
            throw error;
        }
    };

    const signOut = async () => {
        try {
            const response = await fetch('/users/sign_out', {
                method: 'DELETE'
            });

            if (!response.ok) throw new Error('Sign out failed');

            setCurrentUser(null);
        } catch (error) {
            throw error;
        }
    };

    const value = {
        currentUser,
        loading,
        signIn,
        signUp,
        signOut
    };

    return (
        <AuthContext.Provider value={value}>
            {!loading && children}
        </AuthContext.Provider>
    );
};

export const useAuth = () => {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within an AuthProvider');
    }
    return context;
};