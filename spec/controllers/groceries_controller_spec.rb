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

  describe 'GET #index' do
    it 'returns a success response' do
      get :index
      expect(response).to be_successful
    end

    it 'returns JSON when requested' do
      get :index, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'GET #show' do
    it 'returns a success response for existing grocery' do
      get :show, params: { id: grocery.id }
      expect(response).to be_successful
    end

    it 'returns JSON when requested' do
      get :show, params: { id: grocery.id }, format: :json
      expect(response).to be_successful
      expect(response.content_type).to include('application/json')
    end
  end

  describe 'POST #create' do
    let(:grocery_attributes) {
      {
        name: 'New Grocery',
        quantity: 3,
        unit_id: unit.id,
        grocery_section_id: grocery_section.id,
        emoji: 'U+1F34F'
      }
    }

    let(:valid_params) {
      { grocery: grocery_attributes }
    }

    let(:params_with_section) {
      {
        grocery: {
          name: 'New Grocery With Section',
          quantity: 3,
          unit_id: unit.id,
          emoji: 'U+1F34F'
        },
        new_section: {
          name: 'New Section',
          display_order: 1
        }
      }
    }

    context 'when the service succeeds' do
      let(:mock_creator) { instance_double(GroceryCreator, call: true, grocery: Grocery.new, error_messages: '') }

      before do
        allow(GroceryCreator).to receive(:new).and_return(mock_creator)
      end

      it 'creates a GroceryCreator service with the right params' do
        expect(GroceryCreator).to receive(:new).with(
          user,
          hash_including(name: 'New Grocery'),
          nil
        )

        post :create, params: valid_params
      end

      it 'creates a GroceryCreator with section params when provided' do
        expect(GroceryCreator).to receive(:new).with(
          user,
          hash_including(name: 'New Grocery With Section'),
          hash_including(name: 'New Section')
        )

        post :create, params: params_with_section
      end

      it 'returns created status when the service succeeds' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end
    end

    context 'when the service fails' do
      let(:mock_creator) {
        instance_double(
          GroceryCreator,
          call: false,
          grocery: nil,
          error_messages: 'Error message'
        )
      }

      before do
        allow(GroceryCreator).to receive(:new).and_return(mock_creator)
      end

      it 'returns unprocessable entity with error message' do
        post :create, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)['error']).to eq('Error message')
      end
    end

    context 'with real service interaction' do
      it 'successfully creates a grocery' do
        expect {
          post :create, params: valid_params
        }.to change(Grocery, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it 'successfully creates both a section and grocery' do
        expect {
          post :create, params: params_with_section
        }.to change(Grocery, :count).by(1)
                                    .and change(GrocerySection, :count).by(1)

        expect(response).to have_http_status(:created)

        # Verify the grocery is associated with the new section
        new_grocery = Grocery.last
        new_section = GrocerySection.find_by(name: 'New Section')
        expect(new_grocery.grocery_section).to eq(new_section)
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid parameters' do
      let(:new_attributes) {
        {
          grocery: {
            name: 'Updated Grocery'
          }
        }
      }

      it 'updates the requested grocery' do
        put :update, params: { id: grocery.id, **new_attributes }
        grocery.reload
        expect(grocery.name).to eq('Updated Grocery')
      end

      it 'renders a JSON response with the grocery' do
        put :update, params: { id: grocery.id, **new_attributes }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to include('application/json')
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) {
        {
          grocery: {
            name: ''
          }
        }
      }

      it 'renders a JSON response with errors' do
        put :update, params: { id: grocery.id, **invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include('application/json')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested grocery' do
      expect {
        delete :destroy, params: { id: grocery.id }
      }.to change(Grocery, :count).by(-1)
    end

    it 'returns a no content response' do
      delete :destroy, params: { id: grocery.id }
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'error handling' do
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
end