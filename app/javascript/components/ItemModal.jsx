import React, { useState } from 'react';
import { X } from 'lucide-react';

const ItemModal = ({ isOpen, onClose }) => {
    const [formData, setFormData] = useState({
        name: '',
        quantity: '',
        unit: '',
        section: '',
        emoji: ''
    });

    const handleSubmit = async (e) => {
        e.preventDefault();

        try {
            const response = await fetch('/api/groceries', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                onClose();
                // Optionally refresh the page or update the parent component
                window.location.reload();
            } else {
                console.error('Failed to create item');
            }
        } catch (error) {
            console.error('Error creating item:', error);
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
            <div className="bg-gray-900 border border-gray-800 rounded-lg p-6 w-full max-w-md relative">
                <button
                    onClick={onClose}
                    className="absolute right-4 top-4 text-gray-400 hover:text-white transition-colors duration-200"
                >
                    <X size={24} />
                </button>

                <h2 className="text-xl font-semibold mb-6 text-white">Add New Item</h2>

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
                                value={formData.quantity}
                                onChange={handleChange}
                                className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                required
                            />
                        </div>

                        <div>
                            <label htmlFor="unit" className="block text-sm font-medium text-gray-300 mb-1">
                                Unit
                            </label>
                            <input
                                type="text"
                                id="unit"
                                name="unit"
                                value={formData.unit}
                                onChange={handleChange}
                                className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                                required
                            />
                        </div>
                    </div>

                    <div>
                        <label htmlFor="section" className="block text-sm font-medium text-gray-300 mb-1">
                            Section
                        </label>
                        <input
                            type="text"
                            id="section"
                            name="section"
                            value={formData.section}
                            onChange={handleChange}
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                            required
                        />
                    </div>

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
                            placeholder="U+1F34E"
                            className="w-full px-4 py-2 bg-gray-800 border border-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-amber-500 focus:border-amber-500 text-white"
                            required
                        />
                    </div>

                    <button
                        type="submit"
                        className="w-full px-6 py-3 bg-amber-500 hover:bg-amber-600 text-black rounded-lg transition-colors duration-200 font-medium"
                    >
                        Create Item
                    </button>
                </form>
            </div>
        </div>
    );
};

export default ItemModal;