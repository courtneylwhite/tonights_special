require 'rails_helper'

RSpec.describe GroceriesController, type: :controller do
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section, name: 'Produce', user: user) }
  let(:store_section) { create(:store_section, name: 'Main Store') }
  let(:unit) { create(:unit, name: 'pieces', abbreviation: 'pcs') }
  let!(:grocery) {
    create(:grocery,
           user: user,
           grocery_section: grocery_section,
           store_section: store_section,
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
    context 'HTML format' do
      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns @grouped_groceries' do
        get :index
        expect(assigns(:grouped_groceries)).to be_present
        expect(assigns(:grouped_groceries)['Produce']).to be_present
      end

      it 'groups groceries by section name' do
        get :index
        grouped = assigns(:grouped_groceries)
        expect(grouped['Produce'].first[:name]).to eq('Apple')
        expect(grouped['Produce'].first[:quantity]).to eq(5)
        expect(grouped['Produce'].first[:emoji]).to eq('U+1F34E')
      end
    end

    context 'JSON format' do
      it 'returns groceries as JSON' do
        get :index, format: :json
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['Produce']).to be_present
      end
    end

    context 'when user is not signed in' do
      before { sign_out user }

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end

  describe 'GET #show' do
    context 'HTML format' do
      it 'returns a successful response' do
        get :show, params: { id: grocery.id }
        expect(response).to be_successful
      end

      it 'assigns the requested grocery' do
        get :show, params: { id: grocery.id }
        expect(assigns(:grocery)).to eq(grocery)
      end
    end

    context 'JSON format' do
      it 'returns the grocery as JSON' do
        get :show, params: { id: grocery.id }, format: :json
        expect(response).to be_successful
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(grocery.id)
      end
    end

    context 'when grocery does not exist' do
      it 'returns 404 status' do
        get :show, params: { id: 999999 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'PATCH #update' do
    let(:new_quantity) { 10 }

    context 'with valid parameters' do
      it 'updates the grocery' do
        patch :update, params: { id: grocery.id, grocery: { quantity: new_quantity } }, format: :json
        expect(response).to be_successful
        expect(grocery.reload.quantity).to eq(new_quantity)
      end
    end

    context 'with invalid parameters' do
      it 'returns unprocessable entity status' do
        patch :update, params: { id: grocery.id, grocery: { quantity: nil } }, format: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the grocery' do
      expect {
        delete :destroy, params: { id: grocery.id }
      }.to change(Grocery, :count).by(-1)
      expect(response).to have_http_status(:no_content)
    end
  end

  describe 'POST #create' do
    let(:valid_attributes) {
      {
        grocery: {  # Wrap attributes in grocery key
                    name: 'Banana',
                    quantity: 3,
                    emoji: 'U+1F34C',
                    unit_id: unit.id,
                    grocery_section_id: grocery_section.id,
                    store_section_id: store_section.id
        }
      }
    }

    context 'with valid parameters' do
      it 'creates a new grocery' do
        expect {
          post :create, params: valid_attributes, format: :json
          puts "Response body: #{response.body}" if response.status != 201
        }.to change(Grocery, :count).by(1)
        expect(response).to have_http_status(:created)
      end
    end
  end
end
