require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  describe 'POST #create' do
    let(:password) { 'password123' }
    let!(:user) { create(:user, password: password, password_confirmation: password) }

    context 'with valid credentials' do
      it 'signs in the user and redirects to groceries path' do
        post :create, params: {
          user: {
            email: user.email,
            password: password
          }
        }

        # Verify redirect
        expect(response).to redirect_to(groceries_path)

        # Verify Turbo header
        expect(response.headers['Turbo-Visit-Control']).to eq('reload')
      end
    end

    context 'with invalid credentials' do
      it 'does not sign in and shows an error' do
        post :create, params: {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response).to render_template(:new)
        expect(flash[:alert].downcase).to eq('invalid email or password.')
      end
    end
  end
end
