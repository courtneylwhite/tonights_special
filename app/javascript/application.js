import React from 'react'
import { createRoot } from 'react-dom/client'
import Hello from './components/Hello'

document.addEventListener('DOMContentLoaded', () => {
    const components = document.querySelectorAll('[data-react-component]')

    components.forEach(component => {
        const name = component.dataset.reactComponent
        const props = JSON.parse(component.dataset.props || '{}')
        const root = createRoot(component)

        // Add more components to this switch statement as needed
        switch (name) {
            case 'Hello':
                root.render(<Hello {...props} />)
                break
            default:
                console.warn(`Unknown component: ${name}`)
        }
    })
})