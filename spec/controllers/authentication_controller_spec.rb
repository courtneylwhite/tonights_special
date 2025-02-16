require 'rails_helper'

RSpec.describe AuthenticationController, type: :controller do
  # Test the index action
  describe 'GET #index' do
    context 'when user is not logged in' do
      it 'returns a successful response' do
        get :index
        expect(response).to be_successful
      end

      it 'assigns a new User instance to @resource' do
        get :index
        expect(assigns(:resource)).to be_a_new(User)
      end
    end

    context 'when user is logged in' do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
      end

      it 'sets a notice message' do
        get :index
        expect(flash[:notice]).to eq('You are already logged in.')
      end
    end
  end

  # Test helper methods
  describe 'helper methods' do
    describe '#resource_name' do
      it 'returns :user symbol' do
        expect(controller.resource_name).to eq(:user)
      end
    end

    describe '#resource_class' do
      it 'returns User class' do
        expect(controller.resource_class).to eq(User)
      end
    end

    describe '#devise_mapping' do
      it 'returns the correct devise mapping' do
        expect(controller.devise_mapping).to eq(Devise.mappings[:user])
      end

      it 'memoizes the devise mapping' do
        # Call it once to set the instance variable
        controller.devise_mapping

        # Expect Devise not to receive mappings call again
        expect(Devise).not_to receive(:mappings)
        controller.devise_mapping
      end
    end
  end
end
