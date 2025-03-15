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

  # Original tests from the previous spec file
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

    # New test for grouped groceries
    it 'returns groceries grouped by sections' do
      get :index, format: :json
      response_body = JSON.parse(response.body)

      expect(response_body).to be_a(Hash)
      expect(response_body[grocery_section.name]).to be_a(Hash)
      expect(response_body[grocery_section.name]['items']).to be_an(Array)
      expect(response_body[grocery_section.name]['items'].first['name']).to eq('Apple')
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

    # New test for comprehensive details
    it 'returns full grocery details with associated objects' do
      get :show, params: { id: grocery.id }, format: :json

      response_body = JSON.parse(response.body)
      expect(response_body['grocery']['name']).to eq('Apple')
      expect(response_body['grocery']['unit']['name']).to eq('pieces')
      expect(response_body['grocery']['grocery_section']['name']).to eq('Produce')
      expect(response_body['grocery_sections']).to be_an(Array)
      expect(response_body['units']).to be_an(Array)
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
      let(:mock_creator) { instance_double(::GroceryServices::Creator, call: true, grocery: Grocery.new, error_messages: '') }

      before do
        allow(::GroceryServices::Creator).to receive(:new).and_return(mock_creator)
      end

      it 'creates a ::GroceryServices::Creator service with the right params' do
        expect(::GroceryServices::Creator).to receive(:new).with(
          user,
          hash_including(name: 'New Grocery'),
          nil
        )

        post :create, params: valid_params
      end

      it 'creates a ::GroceryServices::Creator with section params when provided' do
        expect(::GroceryServices::Creator).to receive(:new).with(
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
          ::GroceryServices::Creator,
          call: false,
          grocery: nil,
          error_messages: 'Error message'
        )
      }

      before do
        allow(::GroceryServices::Creator).to receive(:new).and_return(mock_creator)
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

    # New tests for boundary and edge cases
    context 'with boundary values' do
      it 'handles zero quantity' do
        zero_quantity_attributes = {
          name: 'Zero Quantity Item',
          quantity: 0,
          unit_id: unit.id,
          grocery_section_id: grocery_section.id
        }

        expect {
          post :create, params: { grocery: zero_quantity_attributes }
        }.to change(Grocery, :count).by(1)

        expect(response).to have_http_status(:created)
        created_grocery = JSON.parse(response.body)
        expect(created_grocery['name'].downcase).to eq('zero quantity item')
      end

      it 'allows creating a grocery with emoji' do
        emoji_attributes = {
          name: 'Emoji Grocery',
          quantity: 1,
          unit_id: unit.id,
          grocery_section_id: grocery_section.id,
          emoji: 'U+1F34F'
        }

        expect {
          post :create, params: { grocery: emoji_attributes }
        }.to change(Grocery, :count).by(1)

        created_grocery = Grocery.last
        expect(created_grocery.emoji).to eq('U+1F34F')
      end
    end

    context 'with duplicate validation' do
      it 'prevents creating a grocery with duplicate name for the same user (case-insensitive)' do
        # Create the first grocery using factory
        first_grocery = create(:grocery,
                               name: 'duplicate apple',
                               user: user,
                               grocery_section: grocery_section,
                               unit: unit
        )

        # Prepare duplicate attributes with different casing
        duplicate_attributes = {
          grocery: {
            name: 'DUPLICATE APPLE',  # Different casing
            quantity: 3,
            unit_id: unit.id,
            grocery_section_id: grocery_section.id
          }
        }

        # Try to create the duplicate via controller
        expect {
          post :create, params: duplicate_attributes
        }.not_to change(Grocery, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        error_response = JSON.parse(response.body)
        expect(error_response['error']).to include('Name has already been taken')
      end

      it 'allows creating a grocery with the same name for a different user' do
        # Create a grocery for the first user
        first_grocery = create(:grocery,
                               name: 'duplicate apple',
                               user: user,
                               grocery_section: grocery_section,
                               unit: unit
        )

        # Create another user and their associated objects
        other_user = create(:user)
        other_grocery_section = create(:grocery_section, user: other_user)
        other_unit = create(:unit)

        # Prepare duplicate attributes for other user
        duplicate_attributes = {
          grocery: {
            name: 'Duplicate Apple',
            quantity: 3,
            unit_id: other_unit.id,
            grocery_section_id: other_grocery_section.id
          }
        }

        # Sign in the other user
        sign_out user
        sign_in other_user

        # Try to create the duplicate for other user
        expect {
          post :create, params: duplicate_attributes
        }.to change(Grocery, :count).by(1)

        expect(response).to have_http_status(:created)
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

      # New comprehensive update test
      it 'updates all attributes of a grocery' do
        new_section = create(:grocery_section, name: 'Fruits', user: user)
        new_unit = create(:unit, name: 'kilograms', abbreviation: 'kg')

        update_attributes = {
          grocery: {
            name: 'Updated Apple',
            quantity: 10,
            grocery_section_id: new_section.id,
            unit_id: new_unit.id,
            emoji: 'U+1F34F'
          }
        }

        put :update, params: { id: grocery.id, **update_attributes }

        grocery.reload
        expect(response).to have_http_status(:ok)
        expect(grocery.name).to eq('Updated Apple')
        expect(grocery.quantity).to eq(10)
        expect(grocery.grocery_section).to eq(new_section)
        expect(grocery.unit).to eq(new_unit)
        expect(grocery.emoji).to eq('U+1F34F')
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

    # New authentication tests
    describe 'Authentication' do
      before { sign_out user }

      it 'requires authentication for index' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'requires authentication for show' do
        get :show, params: { id: grocery.id }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'requires authentication for create' do
        post :create, params: { grocery: { name: 'Test Grocery' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'requires authentication for update' do
        put :update, params: { id: grocery.id, grocery: { name: 'Updated' } }
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'requires authentication for destroy' do
        delete :destroy, params: { id: grocery.id }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
