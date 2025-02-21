require 'rails_helper'
# spec/controllers/grocery_sections_controller_spec.rb
RSpec.describe GrocerySectionsController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) { { grocery_section: attributes_for(:grocery_section) } }

      it 'creates a new grocery section' do
        expect {
          post :create, params: valid_params
        }.to change(GrocerySection, :count).by(1)
      end

      it 'returns a created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { grocery_section: attributes_for(:grocery_section, name: nil) } }

      it 'does not create a new grocery section' do
        expect {
          post :create, params: invalid_params
        }.not_to change(GrocerySection, :count)
      end

      it 'returns unprocessable entity status' do
        post :create, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end
end
