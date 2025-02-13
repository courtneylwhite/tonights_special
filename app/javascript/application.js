import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import React from 'react'
import { createRoot } from 'react-dom/client'
import Hello from './components/Hello'

// Stimulus setup
const application = Application.start()
window.Stimulus = application

// React setup
document.addEventListener('DOMContentLoaded', () => {
    const components = document.querySelectorAll('[data-react-component]')

    components.forEach(component => {
        const name = component.dataset.reactComponent  // Changed from reactComponent to dataset.reactComponent
        const props = JSON.parse(component.dataset.props || '{}')
        const root = createRoot(component)

        switch (name) {
            case 'Hello':
                root.render(<Hello {...props} />)
                break
            default:
                console.warn(`Unknown component: ${name}`)
        }
    })
})