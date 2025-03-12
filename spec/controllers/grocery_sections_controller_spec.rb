require 'rails_helper'

RSpec.describe GrocerySectionsController, type: :controller do
  let(:user) { create(:user) }

  before { sign_in user }

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) {
        {
          grocery_section: attributes_for(:grocery_section, name: 'New Pantry')
        }
      }

      it 'creates a new grocery section' do
        expect {
          post :create, params: valid_params
        }.to change(GrocerySection, :count).by(1)
      end

      it 'returns a created status' do
        post :create, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it 'creates a section associated with the current user' do
        post :create, params: valid_params
        created_section = GrocerySection.last
        expect(created_section.user).to eq(user)
      end

      it 'sets the display order when not provided' do
        # Create an initial section to establish a baseline
        create(:grocery_section, user: user, display_order: 1)

        new_section_params = {
          grocery_section: attributes_for(:grocery_section,
                                          name: 'Auto Order Section',
                                          display_order: nil
          )
        }

        post :create, params: new_section_params

        created_section = GrocerySection.last
        expect(created_section.display_order).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params_no_name) {
        {
          grocery_section: attributes_for(:grocery_section, name: nil)
        }
      }

      let(:duplicate_name_params) {
        {
          grocery_section: attributes_for(:grocery_section, name: 'Duplicate Section')
        }
      }

      it 'does not create a new grocery section with empty name' do
        expect {
          post :create, params: invalid_params_no_name
        }.not_to change(GrocerySection, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        error_response = JSON.parse(response.body)
        expect(error_response['errors']).to include(a_string_including("Name can't be blank"))
      end

      it 'prevents creating a section with duplicate name (case-insensitive)' do
        # Create an initial section
        create(:grocery_section,
               name: 'duplicate section',
               user: user
        )

        # Try to create another section with same name (different case)
        expect {
          post :create, params: {
            grocery_section: attributes_for(:grocery_section, name: 'DUPLICATE SECTION')
          }
        }.not_to change(GrocerySection, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        error_response = JSON.parse(response.body)
        expect(error_response['errors']).to include(a_string_including('Name has already been taken'))
      end

      it 'prevents creating a section with duplicate display order' do
        # Create an initial section
        create(:grocery_section,
               name: 'First Section',
               user: user,
               display_order: 1
        )

        # Try to create another section with same display order
        expect {
          post :create, params: {
            grocery_section: attributes_for(:grocery_section,
                                            name: 'Duplicate Order Section',
                                            display_order: 1
            )
          }
        }.not_to change(GrocerySection, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        error_response = JSON.parse(response.body)
        expect(error_response['errors']).to include(a_string_including('Display order has already been taken'))
      end
    end
  end

  describe 'GET #index' do
    before do
      # Create multiple sections with different display orders
      create(:grocery_section, name: 'Produce', display_order: 1, user: user)
      create(:grocery_section, name: 'Dairy', display_order: 2, user: user)
      create(:grocery_section, name: 'Meat', display_order: 3, user: user)
    end

    it 'returns grocery sections for the current user' do
      get :index, format: :json

      expect(response).to have_http_status(:success)
      response_body = JSON.parse(response.body)

      expect(response_body.size).to eq(3)
      expect(response_body[0]['name']).to eq('Produce')
      expect(response_body[1]['name']).to eq('Dairy')
      expect(response_body[2]['name']).to eq('Meat')
    end
  end

  describe 'Authentication and Authorization' do
    context 'when user is not authenticated' do
      before { sign_out user }

      it 'redirects to login for index' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end

      it 'redirects to login for create' do
        post :create, params: {
          grocery_section: attributes_for(:grocery_section)
        }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
