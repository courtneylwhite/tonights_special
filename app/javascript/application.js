import "@hotwired/turbo-rails"
import { Application } from "@hotwired/stimulus"
import React from 'react'
import { createRoot } from 'react-dom/client'
import * as Components from './components'
import SideNav from './components/SideNav'

const application = Application.start()
window.Stimulus = application

document.addEventListener('DOMContentLoaded', () => {
    const sideNavContainer = document.createElement('div')
    sideNavContainer.id = 'side-nav-container'
    document.body.appendChild(sideNavContainer)
    const sideNavRoot = createRoot(sideNavContainer)
    sideNavRoot.render(<SideNav />)

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
