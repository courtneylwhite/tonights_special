import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import React from 'react'
import { createRoot } from 'react-dom/client'
import * as Components from './components'

// Stimulus setup
const application = Application.start()
window.Stimulus = application

document.addEventListener('DOMContentLoaded', () => {
    const componentElements = document.querySelectorAll('[data-react-component]')

    componentElements.forEach(element => {
        const componentName = element.dataset.reactComponent
        const props = JSON.parse(element.dataset.props || '{}')
        const root = createRoot(element)

        if (Components[componentName]) {
            const Component = Components[componentName]
            root.render(<Component {...props} />)
        } else {
            console.warn(`Component not found: ${componentName}`)
        }
    })
})
