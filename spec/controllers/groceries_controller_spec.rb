require 'rails_helper'

RSpec.describe GroceriesController, type: :controller do
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section, name: 'Produce') }
  let!(:grocery) {
    create(:grocery,
           user: user,
           grocery_section: grocery_section,
           name: 'Apple',
           quantity: 5,
           emoji: 'U+1F34E'
    )
  }

  before do
    sign_in user
  end

  describe 'GET #index' do
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

    context 'when user is not signed in' do
      before do
        sign_out user
      end

      it 'redirects to sign in page' do
        get :index
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end
