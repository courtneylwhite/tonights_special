import React, { useState } from 'react';
import { X } from 'lucide-react';

const ErrorAlert = ({ message }) => (
    <div className="bg-red-900/50 border border-red-500 text-red-200 px-4 py-3 rounded-lg mb-4">
        {message}
    </div>
);

const SectionModal = ({ isOpen, onClose, onSuccess, sections = 0 }) => {
    const [formData, setFormData] = useState({
        name: ''
    });
    const [error, setError] = useState(null);
    const [isSubmitting, setIsSubmitting] = useState(false);

    // Reset form data when modal is opened
    React.useEffect(() => {
        if (isOpen) {
            setFormData({ name: '' });
            setError(null);
        }
    }, [isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        e.stopPropagation();

        setError(null);
        setIsSubmitting(true);

        try {
            const csrf = document.querySelector('[name="csrf-token"]')?.content;
            if (!csrf) {
                throw new Error('CSRF token not found');
            }

            const submitData = {
                ...formData,
                display_order: sections + 1
            };

            const response = await fetch('/grocery_sections', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'Accept': 'application/json',
                    'X-CSRF-Token': csrf,
                    'Turbo-Frame': 'false'
                },
                body: JSON.stringify({ grocery_section: submitData })
            });

            const responseText = await response.text();
            let data;
            try {
                data = JSON.parse(responseText);
            } catch (e) {
                console.log('Raw response:', responseText);
                setError('Server returned an invalid response. You might need to log in again.');
                return;
            }

            if (!response.ok) {
                const errorMessage = data.errors ?
                    data.errors.join(', ') :
                    'Failed to create section. Please try again.';
                setError(errorMessage);
                return;
            }

            // Reset form data after successful submission
            setFormData({ name: '' });

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
                    disabled={isSubmitting}
                >
                    <X size={20} />
                </button>

                <h2 className="text-xl font-semibold mb-6 text-white">Add New Section</h2>

                {error && <ErrorAlert message={error} />}

                <form
                    onSubmit={handleSubmit}
                    className="space-y-4"
                    data-turbo="false"
                >
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