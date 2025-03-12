import React, { useState, useCallback } from 'react';
import { Save, X, Trash2 } from 'lucide-react';

/**
 * Delete confirmation dialog component
 */
const DeleteConfirmationDialog = React.memo(({ onConfirm, onCancel }) => {
    return (
        <div className="fixed inset-0 bg-black bg-opacity-70 flex items-center justify-center z-50">
            <div className="bg-gray-800 p-6 rounded-lg shadow-xl max-w-md w-full">
                <h3 className="text-xl font-bold text-white mb-4">Delete Grocery</h3>
                <p className="text-gray-300 mb-6">
                    Are you sure you want to delete this grocery item? This action cannot be undone.
                </p>
                <div className="flex justify-end space-x-4">
                    <button
                        onClick={onCancel}
                        className="px-4 py-2 bg-gray-700 text-white rounded hover:bg-gray-600 transition-colors"
                    >
                        Cancel
                    </button>
                    <button
                        onClick={onConfirm}
                        className="px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700 transition-colors flex items-center"
                    >
                        <Trash2 size={16} className="mr-2" />
                        Delete
                    </button>
                </div>
            </div>
        </div>
    );
});

/**
 * GroceryEditor component - handles the editing of a grocery item
 */
const GroceryEditor = ({
                           grocery,
                           units = [],
                           grocerySections = [],
                           borderClass,
                           onSave,
                           onCancel,
                           onDelete
                       }) => {
    const [editedGrocery, setEditedGrocery] = useState(grocery);
    const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);

    // Handle grocery field changes
    const handleGroceryChange = useCallback((field, value) => {
        setEditedGrocery(prev => ({
            ...prev,
            [field]: value
        }));
    }, []);

    // Check if form is valid
    const isFormValid = editedGrocery.name?.trim() &&
        editedGrocery.unit_id &&
        editedGrocery.grocery_section_id;

    // Handle save button click
    const handleSaveClick = useCallback(() => {
        if (isFormValid) {
            // Preserve the current quantity from the original grocery
            onSave({
                ...editedGrocery,
                quantity: grocery.quantity // Keep the original quantity
            });
        } else {
            alert("Please fill in all required fields before saving");
        }
    }, [isFormValid, editedGrocery, grocery.quantity, onSave]);

    // Handle delete confirmation
    const handleDeleteConfirm = useCallback(() => {
        setShowDeleteConfirm(false);
        onDelete();
    }, [onDelete]);

    // Handle cancel delete confirmation
    const handleCancelDelete = useCallback(() => {
        setShowDeleteConfirm(false);
    }, []);

    // Open delete confirmation dialog
    const handleDeleteClick = useCallback(() => {
        setShowDeleteConfirm(true);
    }, []);

    return (
        <div className="relative p-8">
            {/* Header section with delete button */}
            <div className="mb-8 flex justify-end items-center">
                <button
                    onClick={handleDeleteClick}
                    className="inline-flex items-center px-4 py-2 bg-gray-900/90 backdrop-blur-sm text-red-500 rounded-lg transition-colors duration-200 border border-gray-700 hover:border-red-500 hover:bg-red-500/10"
                >
                    <Trash2 size={18} className="mr-1" />
                    Delete Grocery
                </button>
            </div>

            {/* Delete confirmation popup */}
            {showDeleteConfirm && (
                <DeleteConfirmationDialog
                    onConfirm={handleDeleteConfirm}
                    onCancel={handleCancelDelete}
                />
            )}

            {/* Main Grocery Card */}
            <div className={`bg-gray-900/90 backdrop-blur-sm rounded-2xl p-8 shadow-xl transition-all duration-300 ${borderClass}`}>
                <div className="space-y-6">
                    {/* Name */}
                    <div className="flex flex-col">
                        <label className="text-amber-400 mb-1 font-medium">Name</label>
                        <input
                            type="text"
                            value={editedGrocery.name || ''}
                            onChange={(e) => handleGroceryChange('name', e.target.value)}
                            className={`px-4 py-2 bg-gray-800 border ${
                                !editedGrocery.name ? 'border-red-500' : 'border-amber-500'
                            } rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent`}
                            placeholder="Grocery name"
                        />
                        {!editedGrocery.name && (
                            <span className="text-red-500 text-xs mt-1">Required</span>
                        )}
                    </div>

                    {/* Emoji */}
                    <div className="flex flex-col">
                        <label className="text-amber-400 mb-1 font-medium">Emoji (Unicode)</label>
                        <input
                            type="text"
                            value={editedGrocery.emoji || ''}
                            onChange={(e) => handleGroceryChange('emoji', e.target.value)}
                            className="px-4 py-2 bg-gray-800 border border-amber-500 rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent"
                            placeholder="U+1F34E (for 🍎)"
                        />
                        <span className="text-gray-400 text-xs mt-1">
                            Tip: You can find emoji codes at <a href="https://emojipedia.org/" className="text-amber-400" target="_blank" rel="noopener noreferrer">Emojipedia</a>
                        </span>
                    </div>

                    {/* Section */}
                    <div className="flex flex-col">
                        <label className="text-amber-400 mb-1 font-medium">Section</label>
                        <select
                            value={editedGrocery.grocery_section_id || ''}
                            onChange={(e) => handleGroceryChange('grocery_section_id', e.target.value)}
                            className={`px-4 py-2 bg-gray-800 border ${
                                !editedGrocery.grocery_section_id ? 'border-red-500' : 'border-amber-500'
                            } rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent`}
                        >
                            <option value="">Select a section</option>
                            {grocerySections.map(section => (
                                <option key={section.id} value={section.id}>
                                    {section.name}
                                </option>
                            ))}
                        </select>
                        {!editedGrocery.grocery_section_id && (
                            <span className="text-red-500 text-xs mt-1">Required</span>
                        )}
                    </div>

                    {/* Unit (without Quantity) */}
                    <div className="flex flex-col">
                        <label className="text-amber-400 mb-1 font-medium">Unit</label>
                        <select
                            value={editedGrocery.unit_id || ''}
                            onChange={(e) => handleGroceryChange('unit_id', e.target.value)}
                            className={`px-4 py-2 bg-gray-800 border ${
                                !editedGrocery.unit_id ? 'border-red-500' : 'border-amber-500'
                            } rounded-lg text-white focus:ring-2 focus:ring-amber-500 focus:border-transparent`}
                        >
                            <option value="">Select a unit</option>
                            {units.map(unit => (
                                <option key={unit.id} value={unit.id}>
                                    {unit.name}
                                </option>
                            ))}
                        </select>
                        {!editedGrocery.unit_id && (
                            <span className="text-red-500 text-xs mt-1">Required</span>
                        )}
                    </div>
                </div>
            </div>

            {/* Action buttons */}
            <div className="mt-8 flex justify-center space-x-4">
                <button
                    onClick={handleSaveClick}
                    disabled={!isFormValid}
                    className={`inline-flex items-center px-4 py-2 ${
                        isFormValid
                            ? 'bg-amber-500 hover:bg-amber-600 text-black'
                            : 'bg-gray-500 text-gray-300 cursor-not-allowed'
                    } rounded-lg transition-colors duration-200 border ${
                        isFormValid ? 'border-amber-400' : 'border-gray-600'
                    }`}
                >
                    <Save size={18} className="mr-1" />
                    Save
                </button>
                <button
                    onClick={onCancel}
                    className="inline-flex items-center px-4 py-2 bg-gray-800 hover:bg-gray-700 text-white rounded-lg transition-colors duration-200 border border-gray-700"
                >
                    <X size={18} className="mr-1" />
                    Cancel
                </button>
            </div>
        </div>
    );
};

export default React.memo(GroceryEditor);