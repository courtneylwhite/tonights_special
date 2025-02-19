import React, { useState, useEffect } from 'react';
import { ChevronUp, ChevronDown } from 'lucide-react';

const GroceryShow = ({ grocery = {} }) => {
    const [quantity, setQuantity] = useState(Math.round(grocery.quantity || 0));
    const [showSuccess, setShowSuccess] = useState(false);
    const [showError, setShowError] = useState(false);

    const unicodeToEmoji = (unicodeString) => {
        if (!unicodeString) return '❓';
        try {
            const hex = unicodeString.replace('U+', '');
            return String.fromCodePoint(parseInt(hex, 16));
        } catch (error) {
            console.error('Error converting unicode to emoji:', error);
            return '❓';
        }
    };

    useEffect(() => {
        if (showSuccess) {
            const timer = setTimeout(() => {
                setShowSuccess(false);
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [showSuccess]);

    useEffect(() => {
        if (showError) {
            const timer = setTimeout(() => {
                setShowError(false);
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [showError]);

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
                        quantity: Math.round(quantity + 1)
                    }
                })
            });

            if (response.ok) {
                setQuantity(prev => Math.round(prev + 1));
                setShowSuccess(true);
                setShowError(false);
            } else {
                setShowError(true);
                setShowSuccess(false);
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
            setShowError(true);
            setShowSuccess(false);
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
                        quantity: Math.round(quantity - 1)
                    }
                })
            });

            if (response.ok) {
                setQuantity(prev => Math.round(prev - 1));
                setShowSuccess(true);
                setShowError(false);
            } else {
                setShowError(true);
                setShowSuccess(false);
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
            setShowError(true);
            setShowSuccess(false);
        }
    };

    return (
        <div className="min-h-screen bg-black text-white flex items-center justify-center">
            <div className="max-w-md w-full mx-auto p-8">
                <div className={`bg-gray-900/90 backdrop-blur-sm rounded-2xl p-8 shadow-xl transition-all duration-300 ${
                    showSuccess
                        ? 'border-2 border-green-500 border-opacity-100'
                        : showError
                            ? 'border-2 border-red-500 border-opacity-100'
                            : 'border border-gray-800'
                }`}>
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
                                <span className="text-2xl font-bold">{Math.round(quantity)}</span>
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

                {/* Back Button */}
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