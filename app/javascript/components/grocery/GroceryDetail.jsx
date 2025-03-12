import React, { useState, useCallback, useMemo } from 'react';
import GroceryViewer from './GroceryViewer';
import GroceryEditor from './GroceryEditor';
import { ChevronLeft } from 'lucide-react';

/**
 * Root component for displaying and editing a grocery item
 * Manages state and API interactions between GroceryViewer and GroceryEditor
 */
const GroceryDetail = ({ grocery = {}, units = [], grocerySections = [] }) => {
    // Component state
    const [isEditing, setIsEditing] = useState(false);
    const [currentGrocery, setCurrentGrocery] = useState(grocery);
    const [feedbackState, setFeedbackState] = useState({
        showSuccess: false,
        showError: false
    });
    const [availableSections, setAvailableSections] = useState(grocerySections);

    // API helper - get CSRF token once
    const csrfToken = useMemo(() =>
            document.querySelector('[name="csrf-token"]')?.content,
        []);

    // Common API request headers for reuse
    const requestHeaders = useMemo(() => ({
        'Content-Type': 'application/json',
        'X-CSRF-Token': csrfToken,
        'Accept': 'application/json'
    }), [csrfToken]);

    // Show temporary feedback (success or error)
    const showFeedback = useCallback((success) => {
        if (success) {
            setFeedbackState({ showSuccess: true, showError: false });
            setTimeout(() => setFeedbackState({ showSuccess: false, showError: false }), 2000);
        } else {
            setFeedbackState({ showSuccess: false, showError: true });
            setTimeout(() => setFeedbackState({ showSuccess: false, showError: false }), 2000);
        }
    }, []);

    // Fetch grocery sections if needed
    const fetchGrocerySections = useCallback(async () => {
        try {
            const response = await fetch('/grocery_sections', {
                method: 'GET',
                headers: { 'Accept': 'application/json' }
            });

            if (response.ok) {
                const data = await response.json();
                setAvailableSections(data);
            } else {
                console.error('Failed to fetch grocery sections');
            }
        } catch (error) {
            console.error('Error fetching grocery sections:', error);
        }
    }, []);

    // Handler for edit button click
    const handleEditClick = useCallback(() => {
        // Only fetch sections if we don't have any yet
        if (availableSections.length === 0) {
            fetchGrocerySections();
        }
        setIsEditing(true);
    }, [availableSections.length, fetchGrocerySections]);

    // Handler for cancel edit button click
    const handleCancelEdit = useCallback(() => {
        setIsEditing(false);
    }, []);

    // Handle back button click
    const handleBackClick = useCallback(() => {
        window.location.href = "/groceries";
    }, []);

    // Handle increment button click
    const handleIncrement = useCallback(async () => {
        try {
            // Calculate the new quantity value, ensuring it's a number
            const newQuantity = Math.round(Number(currentGrocery.quantity) + 1);

            console.log(`Incrementing from ${currentGrocery.quantity} to ${newQuantity}`);

            const response = await fetch(`/groceries/${currentGrocery.id}`, {
                method: 'PATCH',
                headers: requestHeaders,
                body: JSON.stringify({
                    grocery: {
                        quantity: newQuantity
                    }
                })
            });

            if (response.ok) {
                // Parse the response JSON
                const updatedData = await response.json();
                console.log('Increment response:', updatedData);

                // Create a complete grocery object with all the necessary fields
                const completeGrocery = {
                    ...currentGrocery, // Keep all current values as a base
                    ...updatedData,    // Override with any updated fields from the response
                    // Ensure the nested objects are preserved
                    quantity: newQuantity, // Explicitly ensure the quantity is updated
                    unit: updatedData.unit || currentGrocery.unit,
                    grocery_section: updatedData.grocery_section || currentGrocery.grocery_section
                };

                setCurrentGrocery(completeGrocery);
                showFeedback(true);
            } else {
                const errorText = await response.text();
                console.error('Failed to update quantity:', errorText);
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
            showFeedback(false);
        }
    }, [currentGrocery, requestHeaders, showFeedback]);

    // Handle decrement button click
    const handleDecrement = useCallback(async () => {
        if (currentGrocery.quantity <= 0) return;

        try {
            // Calculate the new quantity value, ensuring it's a number
            const newQuantity = Math.round(Number(currentGrocery.quantity) - 1);

            console.log(`Decrementing from ${currentGrocery.quantity} to ${newQuantity}`);

            const response = await fetch(`/groceries/${currentGrocery.id}`, {
                method: 'PATCH',
                headers: requestHeaders,
                body: JSON.stringify({
                    grocery: {
                        quantity: newQuantity
                    }
                })
            });

            if (response.ok) {
                // Parse the response JSON
                const updatedData = await response.json();
                console.log('Decrement response:', updatedData);

                // Create a complete grocery object with all the necessary fields
                const completeGrocery = {
                    ...currentGrocery, // Keep all current values as a base
                    ...updatedData,    // Override with any updated fields from the response
                    // Ensure the nested objects are preserved
                    quantity: newQuantity, // Explicitly ensure the quantity is updated
                    unit: updatedData.unit || currentGrocery.unit,
                    grocery_section: updatedData.grocery_section || currentGrocery.grocery_section
                };

                setCurrentGrocery(completeGrocery);
                showFeedback(true);
            } else {
                const errorText = await response.text();
                console.error('Failed to update quantity:', errorText);
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error updating quantity:', error);
            showFeedback(false);
        }
    }, [currentGrocery, requestHeaders, showFeedback]);

    // Handler for save changes button click
    const handleSaveChanges = useCallback(async (editedGrocery) => {
        try {
            const formData = {
                grocery: {
                    name: editedGrocery.name,
                    quantity: Math.round(editedGrocery.quantity),
                    unit_id: editedGrocery.unit_id,
                    grocery_section_id: editedGrocery.grocery_section_id,
                    emoji: editedGrocery.emoji
                }
            };

            const response = await fetch(`/groceries/${currentGrocery.id}`, {
                method: 'PATCH',
                headers: requestHeaders,
                body: JSON.stringify(formData)
            });

            if (response.ok) {
                const updatedData = await response.json();

                // Find the corresponding section and unit objects to include in the state
                const selectedSection = availableSections.find(
                    section => section.id === parseInt(editedGrocery.grocery_section_id)
                );

                const selectedUnit = units.find(
                    unit => unit.id === parseInt(editedGrocery.unit_id)
                );

                // Create a complete grocery object with nested objects
                const completeGrocery = {
                    ...updatedData,
                    grocery_section: selectedSection,
                    unit: selectedUnit
                };

                setCurrentGrocery(completeGrocery);
                showFeedback(true);
                setIsEditing(false);
            } else {
                console.error('Failed to update grocery');
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error updating grocery:', error);
            showFeedback(false);
        }
    }, [currentGrocery.id, requestHeaders, showFeedback, availableSections, units]);

    // Handler for delete grocery button click
    const handleDeleteGrocery = useCallback(async () => {
        try {
            const response = await fetch(`/groceries/${currentGrocery.id}`, {
                method: 'DELETE',
                headers: requestHeaders
            });

            if (response.ok) {
                window.location.href = '/groceries';
            } else {
                console.error('Failed to delete grocery');
                showFeedback(false);
            }
        } catch (error) {
            console.error('Error deleting grocery:', error);
            showFeedback(false);
        }
    }, [currentGrocery.id, requestHeaders, showFeedback]);

    // Border class that shows feedback when saving/error
    const borderClass = useMemo(() =>
            feedbackState.showSuccess
                ? 'border-2 border-green-500 border-opacity-100'
                : feedbackState.showError
                    ? 'border-2 border-red-500 border-opacity-100'
                    : 'border border-gray-800',
        [feedbackState.showSuccess, feedbackState.showError]);

    return (
        <div className="min-h-screen bg-black text-white flex items-center justify-center">
            <div className="max-w-md w-full mx-auto relative">
                {/* Back Button positioned relative to the content div */}
                <button
                    onClick={handleBackClick}
                    className="absolute -left-16 top-1/2 -translate-y-1/2 p-2 text-white hover:text-amber-500 transition-colors duration-200 focus:outline-none"
                    aria-label="Go back"
                >
                    <ChevronLeft size={40} />
                </button>

                {isEditing ? (
                    <GroceryEditor
                        grocery={currentGrocery}
                        units={units}
                        grocerySections={availableSections}
                        borderClass={borderClass}
                        onSave={handleSaveChanges}
                        onCancel={handleCancelEdit}
                        onDelete={handleDeleteGrocery}
                    />
                ) : (
                    <GroceryViewer
                        grocery={currentGrocery}
                        borderClass={borderClass}
                        onEdit={handleEditClick}
                        onIncrement={handleIncrement}
                        onDecrement={handleDecrement}
                    />
                )}
            </div>
        </div>
    );
};

export default React.memo(GroceryDetail);