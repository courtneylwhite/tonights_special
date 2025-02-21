require 'rails_helper'

RSpec.describe Users::RegistrationsController, type: :controller do
  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  describe 'POST #create' do
    let(:valid_params) do
      {
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123'
        }
      }
    end

    context 'with valid parameters' do
      it 'creates a new user' do
        expect {
          post :create, params: valid_params
        }.to change(User, :count).by(1)
      end

      it 'sets Turbo-Visit-Control header' do
        post :create, params: valid_params
        expect(response.headers['Turbo-Visit-Control']).to eq('reload')
      end

      it 'redirects to groceries path' do
        post :create, params: valid_params
        expect(response).to redirect_to(groceries_path) # Removed reload: true
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          user: {
            email: 'invalid_email',
            password: 'short',
            password_confirmation: 'different'
          }
        }
      end

      it 'does not create a new user' do
        expect {
          post :create, params: invalid_params
        }.not_to change(User, :count)
      end
    end
  end

  describe '#sign_up_params' do
    it 'permits only allowed parameters' do
      params = ActionController::Parameters.new(
        user: {
          email: 'test@example.com',
          password: 'password123',
          password_confirmation: 'password123',
          admin: true # unauthorized parameter
        }
      )
      controller.params = params

      expect(controller.send(:sign_up_params).keys).to match_array([ 'email', 'password', 'password_confirmation' ])
    end
  end
end
