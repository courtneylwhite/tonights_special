import React, { useState, useEffect } from 'react';
import { X } from 'lucide-react';

const ErrorAlert = ({ message }) => (
    <div className="bg-red-900/50 border border-red-500 text-red-200 px-4 py-3 rounded-lg mb-4">
        {message}
    </div>
);

const SectionModal = ({ isOpen, onClose, onSuccess, sections = 0 }) => {
    const initialFormState = {
        name: ''
    }
    const [formData, setFormData] = useState(initialFormState);
    const [error, setError] = useState(null);
    const [isSubmitting, setIsSubmitting] = useState(false);

    useEffect(() => {
        if (isOpen) {
            setFormData(initialFormState);
            setError(null);
        }
    }, [isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setIsSubmitting(true);
        const token = document.querySelector('meta[name="csrf-token"]')?.content;

        try {
            const submitData = {
                ...formData,
                display_order: sections + 1
            };

            const response = await fetch('/grocery_sections', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': token,
                },
                body: JSON.stringify({ grocery_section: submitData })
            });

            const data = await response.json();

            if (!response.ok) {
                const errorMessage = data.errors ?
                    data.errors.join(', ') :
                    'Failed to create section.';
                setError(errorMessage);
                return;
            }

            setFormData(initialFormState);
            if (onSuccess) {
                onSuccess(data);
            }
            onClose();

        } catch (error) {
            setError('An unexpected error occurred. Please try again.');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-gray-900 border border-gray-800 rounded-lg w-full max-w-md p-6 relative">
                <button
                    onClick={onClose}
                    className="absolute top-4 right-4 text-gray-400 hover:text-white transition-colors duration-200"
                    disabled={isSubmitting}
                >
                    <X size={20}/>
                </button>

                <h2 className="text-xl font-semibold mb-6 text-white">Add New Section</h2>

                {error && <ErrorAlert message={error}/>}

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
                            disabled={isSubmitting}
                        />
                    </div>

                    <button
                        type="submit"
                        className="w-full px-4 py-2 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                        disabled={isSubmitting}
                    >
                        {isSubmitting ? 'Creating...' : 'Create Section'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default SectionModal;