require 'rails_helper'

RSpec.describe GroceriesController, type: :controller do
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section, name: 'Produce', user: user) }
  let(:unit) { create(:unit, name: 'pieces', abbreviation: 'pcs') }
  let!(:grocery) {
    create(:grocery,
           user: user,
           grocery_section: grocery_section,
           unit: unit,
           name: 'Apple',
           quantity: 5,
           emoji: 'U+1F34E'
    )
  }

  before do
    sign_in user
  end

  # Existing tests...

  describe 'error handling' do
    # Add test for record_not_found method (line 40)
    context 'when accessing a non-existent grocery' do
      it 'returns a not found response for JSON' do
        get :show, params: { id: 999999 }, format: :json
        expect(response).to have_http_status(:not_found)
        expect(JSON.parse(response.body)['error']).to eq('Grocery not found')
      end

      it 'redirects with an alert for HTML' do
        get :show, params: { id: 999999 }
        expect(response).to redirect_to(groceries_path)
        expect(flash[:alert]).to eq('Grocery not found')
      end
    end

    # Add test for handle_unexpected_error method
    context 'when an unexpected error occurs' do
      before do
        allow_any_instance_of(GroceriesController).to receive(:set_grocery).and_raise(StandardError.new('Unexpected error'))
      end

      it 'logs the unexpected error' do
        expect(Rails.logger).to receive(:error).with(/Unexpected error/)

        get :show, params: { id: grocery.id }, format: :json

        expect(response).to have_http_status(:internal_server_error)
        expect(JSON.parse(response.body)['error']).to eq('An unexpected error occurred')
      end
    end
  end

  describe 'input validation' do
    context 'with invalid create parameters' do
      let(:invalid_attributes) {
        {
          grocery: {
            name: '', # Empty name should fail validation
            quantity: -1, # Negative quantity
            unit_id: nil,
            grocery_section_id: nil
          }
        }
      }

      it 'returns validation errors' do
        post :create, params: invalid_attributes, format: :json

        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response['error']).to be_present
        expect(json_response['details']).to be_present
      end
    end
  end
end
