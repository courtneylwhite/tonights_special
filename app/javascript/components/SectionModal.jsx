import React, { useState } from 'react';
import { X } from 'lucide-react';

const SectionModal = ({ isOpen, onClose }) => {
    const [formData, setFormData] = useState({
        name: '',
        display_order: ''
    });

    const handleSubmit = async (e) => {
        e.preventDefault();

        try {
            const response = await fetch('/grocery_sections', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
                },
                body: JSON.stringify({ grocery_section: formData })
            });

            if (response.ok) {
                onClose();
                window.location.reload(); // Refresh to show new section
            } else {
                console.error('Failed to create section');
            }
        } catch (error) {
            console.error('Error creating section:', error);
        }
    };

    const handleChange = (e) => {
        setFormData(prev => ({
            ...prev,
            [e.target.name]: e.target.value
        }));
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-gray-900 border border-gray-800 rounded-lg w-full max-w-md p-6 relative">
                <button
                    onClick={onClose}
                    className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors duration-200"
                >
                    <X size={20} />
                </button>

                <h2 className="text-xl font-semibold mb-6 text-white">Add New Section</h2>

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label htmlFor="name" className="block text-sm font-medium text-gray-300 mb-2">
                            Section Name
                        </label>
                        <input
                            type="text"
                            id="name"
                            name="name"
                            value={formData.name}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white placeholder-gray-400"
                            required
                        />
                    </div>

                    <div>
                        <label htmlFor="display_order" className="block text-sm font-medium text-gray-300 mb-2">
                            Display Order
                        </label>
                        <input
                            type="number"
                            id="display_order"
                            name="display_order"
                            value={formData.display_order}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white placeholder-gray-400"
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        className="w-full px-4 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 font-medium"
                    >
                        Create Section
                    </button>
                </form>
            </div>
        </div>
    );
};

export default SectionModal;