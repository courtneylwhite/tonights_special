import React, { useState } from 'react';
import { ChevronUp, ChevronDown } from 'lucide-react';

const GroceryShow = ({ grocery = {} }) => {
    const [quantity, setQuantity] = useState(grocery.quantity || 0);

    const unicodeToEmoji = (unicodeString) => {
        if (!unicodeString) return '❓'; // Return a question mark emoji if no unicode string is provided
        try {
            const hex = unicodeString.replace('U+', '');
            return String.fromCodePoint(parseInt(hex, 16));
        } catch (error) {
            console.error('Error converting unicode to emoji:', error);
            return '❓'; // Return a question mark emoji if conversion fails
        }
    };

    const handleIncrement = async () => {
        try {
            const response = await fetch(`/groceries/${grocery.id}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
                },
                body: JSON.stringify({
                    grocery: {
                        quantity: quantity + 1
                    }
                })
            });

            if (response.ok) {
                setQuantity(prev => prev + 1);
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
        }
    };

    const handleDecrement = async () => {
        if (quantity <= 0) return;

        try {
            const response = await fetch(`/groceries/${grocery.id}`, {
                method: 'PATCH',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-Token': document.querySelector('[name="csrf-token"]')?.content
                },
                body: JSON.stringify({
                    grocery: {
                        quantity: quantity - 1
                    }
                })
            });

            if (response.ok) {
                setQuantity(prev => prev - 1);
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
        }
    };

    return (
        <div className="min-h-screen bg-black text-white flex items-center justify-center">
            <div className="max-w-md w-full mx-auto p-8">
                <div className="bg-gray-900/90 backdrop-blur-sm border border-gray-800 rounded-2xl p-8 shadow-xl">
                    {/* Name */}
                    <h1 className="text-2xl font-bold text-center mb-8 text-amber-400">
                        {grocery.name}
                    </h1>

                    {/* Emoji */}
                    <div className="text-center mb-8">
                        <span className="text-8xl inline-block transform hover:scale-110 transition-transform duration-200">
                            {unicodeToEmoji(grocery.emoji)}
                        </span>
                    </div>

                    {/* Quantity Controls */}
                    <div className="flex flex-col items-center">
                        <div className="flex items-center gap-4 mb-2">
                            <button
                                onClick={handleDecrement}
                                className="p-2 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-700 hover:border-amber-500 transition-colors duration-200 disabled:opacity-50 disabled:cursor-not-allowed"
                                disabled={quantity <= 0}
                            >
                                <ChevronDown className="text-amber-400" size={24} />
                            </button>

                            <div className="bg-gray-800 px-6 py-3 rounded-lg border border-gray-700 min-w-[100px] text-center">
                                <span className="text-2xl font-bold">{quantity}</span>
                            </div>

                            <button
                                onClick={handleIncrement}
                                className="p-2 bg-gray-800 hover:bg-gray-700 rounded-lg border border-gray-700 hover:border-amber-500 transition-colors duration-200"
                            >
                                <ChevronUp className="text-amber-400" size={24} />
                            </button>
                        </div>

                        {/* Unit */}
                        <div className="text-gray-400 text-sm">
                            {grocery.unit}
                        </div>
                    </div>
                </div>

                {/* Back Button - Now outside the main container */}
                <div className="mt-8 text-center">
                    <a
                        href="/groceries"
                        className="inline-block px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-amber-400 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-amber-500"
                    >
                        Back to Inventory
                    </a>
                </div>
            </div>
        </div>
    );
};

export default GroceryShow;