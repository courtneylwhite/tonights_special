import React, { useState, useEffect } from 'react';
import { X, ChevronLeft } from 'lucide-react';

const ErrorAlert = ({ message }) => (
    <div className="bg-red-900/50 border border-red-500 text-red-200 px-4 py-3 rounded-lg mb-4">
        {message}
    </div>
);

const ItemModal = ({
                       isOpen,
                       onClose,
                       grocerySections = [],
                       units = [],
                       onItemAdded = () => {},
                   }) => {
    const initialFormState = {
        name: '',
        quantity: '',
        unit_id: '',
        grocery_section_id: '',
        emoji: 'U+2754',
        new_section_name: ''
    };

    const [formData, setFormData] = useState(initialFormState);
    const [error, setError] = useState(null);
    const [isSubmitting, setIsSubmitting] = useState(false);
    const [isAddingSectionMode, setIsAddingSectionMode] = useState(false);

    useEffect(() => {
        if (!isOpen) {
            setFormData(initialFormState);
            setError(null);
            setIsAddingSectionMode(false);
        }
    }, [isOpen]);

    const handleSubmit = async (e) => {
        e.preventDefault();
        setError(null);
        setIsSubmitting(true);
        const token = document.querySelector('meta[name="csrf-token"]')?.content;

        try {
            // Prepare the request data
            const requestData = {
                grocery: {
                    name: formData.name,
                    quantity: formData.quantity,
                    unit_id: formData.unit_id,
                    emoji: formData.emoji
                }
            };

            // Handle section data based on mode
            if (isAddingSectionMode && formData.new_section_name?.trim()) {
                // Creating a new section
                requestData.new_section = {
                    name: formData.new_section_name,
                    display_order: grocerySections.length + 1
                };
            } else {
                // Using an existing section
                requestData.grocery.grocery_section_id = formData.grocery_section_id;
            }

            const response = await fetch('/groceries', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': token
                },
                body: JSON.stringify(requestData)
            });

            const data = await response.json();

            if (!response.ok) {
                const errorMessage = data.error || (data.errors ?
                    data.errors.join(', ') :
                    'Failed to create item. Please try again.');
                setError(errorMessage);
                return;
            }

            onItemAdded(data);
            onClose();

        } catch (error) {
            console.error('Fetch error details:', error);
            setError('An unexpected error occurred. Please try again.');
        } finally {
            setIsSubmitting(false);
        }
    };

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: name === 'quantity' ? Math.max(0, Number(value)) || '' : value
        }));

        // If they select "Add New Section" option
        if (name === 'grocery_section_id' && value === 'new') {
            setIsAddingSectionMode(true);
        }
    };

    const cancelAddSection = () => {
        setIsAddingSectionMode(false);
        setFormData(prev => ({
            ...prev,
            grocery_section_id: '',
            new_section_name: ''
        }));
    };

    if (!isOpen) return null;

    return (
        <div className="fixed inset-0 bg-black/70 backdrop-blur-sm flex items-center justify-center z-50">
            <div className="bg-gray-900 border border-gray-800 rounded-lg p-6 w-full max-w-md relative">
                <button
                    onClick={onClose}
                    className="absolute right-4 top-4 text-gray-400 hover:text-white transition-colors duration-200"
                    disabled={isSubmitting}
                >
                    <X size={24} />
                </button>

                <h2 className="text-xl font-semibold mb-6 text-white">Add New Item</h2>

                {error && <ErrorAlert message={error} />}

                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label htmlFor="name" className="block text-sm font-medium text-gray-300 mb-1">
                            Item Name
                        </label>
                        <input
                            type="text"
                            id="name"
                            name="name"
                            value={formData.name}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                            required
                            disabled={isSubmitting}
                        />
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label htmlFor="quantity" className="block text-sm font-medium text-gray-300 mb-1">
                                Quantity
                            </label>
                            <input
                                type="number"
                                id="quantity"
                                name="quantity"
                                min="0"
                                value={formData.quantity}
                                onChange={handleChange}
                                className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                required
                                disabled={isSubmitting}
                            />
                        </div>

                        <div>
                            <label htmlFor="unit_id" className="block text-sm font-medium text-gray-300 mb-1">
                                Unit
                            </label>
                            <select
                                id="unit_id"
                                name="unit_id"
                                value={formData.unit_id}
                                onChange={handleChange}
                                className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                required
                                disabled={isSubmitting}
                            >
                                <option value="">Select</option>
                                {units.map((unit) => (
                                    <option key={unit.id} value={unit.id}>
                                        {unit.name}
                                    </option>
                                ))}
                            </select>
                        </div>
                    </div>

                    {!isAddingSectionMode ? (
                        <div>
                            <label htmlFor="grocery_section_id" className="block text-sm font-medium text-gray-300 mb-1">
                                Pantry Section
                            </label>
                            <select
                                id="grocery_section_id"
                                name="grocery_section_id"
                                value={formData.grocery_section_id}
                                onChange={handleChange}
                                className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                required
                                disabled={isSubmitting}
                            >
                                <option value="">Select</option>
                                {grocerySections.map((section) => (
                                    <option key={section.id} value={section.id}>
                                        {section.name}
                                    </option>
                                ))}
                                <option value="new" className="font-medium text-amber-400">
                                    + Add New Section
                                </option>
                            </select>
                        </div>
                    ) : (
                        <div>
                            <label htmlFor="new_section_name" className="block text-sm font-medium text-gray-300 mb-1">
                                New Section Name
                            </label>
                            <div className="relative">
                                <input
                                    type="text"
                                    id="new_section_name"
                                    name="new_section_name"
                                    value={formData.new_section_name}
                                    onChange={handleChange}
                                    className="w-full px-4 py-2 pr-10 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                    placeholder="Enter section name"
                                    required={isAddingSectionMode}
                                    disabled={isSubmitting}
                                />
                                <button
                                    type="button"
                                    onClick={cancelAddSection}
                                    className="absolute inset-y-0 right-0 pr-3 flex items-center text-gray-400 hover:text-gray-200"
                                    disabled={isSubmitting}
                                >
                                    <X size={16} />
                                </button>
                            </div>
                        </div>
                    )}

                    <div>
                        <label htmlFor="emoji" className="block text-sm font-medium text-gray-300 mb-1">
                            Emoji (Unicode)
                        </label>
                        <input
                            type="text"
                            id="emoji"
                            name="emoji"
                            value={formData.emoji}
                            onChange={handleChange}
                            placeholder="U+2754"
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                            required
                            disabled={isSubmitting}
                        />
                    </div>

                    <button
                        type="submit"
                        className="w-full px-6 py-3 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                        disabled={isSubmitting || (isAddingSectionMode && !formData.new_section_name?.trim())}
                    >
                        {isSubmitting ? 'Creating...' : 'Create Item'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default ItemModal;