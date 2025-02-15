import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import React from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom'
import { AuthProvider, useAuth } from './contexts/AuthContext'
import AnimatedTitle from "./components/AnimatedTitle";

// Stimulus setup
const application = Application.start()
window.Stimulus = application

// Protected Route component
const ProtectedRoute = ({ children }) => {
    const { currentUser, loading } = useAuth();

    if (loading) return <div>Loading...</div>;

    if (!currentUser) {
        return <Navigate to="/signin" />;
    }

    return children;
};

// React setup
document.addEventListener('DOMContentLoaded', () => {
    const components = document.querySelectorAll('[data-react-component]')

    components.forEach(component => {
        const name = component.dataset.reactComponent
        const props = JSON.parse(component.dataset.props || '{}')
        const root = createRoot(component)

        switch (name) {
            case 'AnimatedTitle':
                root.render(
                    <Router>
                        <AuthProvider>
                            <AnimatedTitle {...props} />
                        </AuthProvider>
                    </Router>
                )
                break
            default:
                console.warn(`Unknown component: ${name}`)
        }
    })
})