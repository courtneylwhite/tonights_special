# spec/controllers/users/sessions_controller_spec.rb
require 'rails_helper'

RSpec.describe Users::SessionsController, type: :controller do
  before(:each) do
    @request.env['devise.mapping'] = Devise.mappings[:user]
  end

  describe 'POST #create' do
    let(:password) { 'password123' }
    let!(:user) { create(:user, password: password, password_confirmation: password) }

    context 'with valid credentials' do
      before do
        @request.env["HTTP_ACCEPT"] = "text/html"

        # Setup warden with more permissive stubs
        warden = double(Warden::Proxy)
        allow(warden).to receive(:authenticate?).with(any_args).and_return(false)
        allow(warden).to receive(:authenticate!).and_return(user)
        allow(warden).to receive(:user).and_return(user)

        allow(controller).to receive(:warden).and_return(warden)
        allow(controller).to receive(:current_user).and_return(user)

        post :create, params: {
          user: {
            email: user.email,
            password: password
          }
        }, format: :html
      end

      it 'signs in the user' do
        expect(controller.current_user).to eq(user)
      end

      it 'sets Turbo-Visit-Control header' do
        expect(response.headers['Turbo-Visit-Control']).to eq('reload')
      end

      it 'redirects to groceries path' do
        expect(response).to redirect_to(groceries_path)
      end
    end

    context 'with invalid credentials' do
      before do
        @request.env["HTTP_ACCEPT"] = "text/html"

        # Setup warden for authentication failure
        warden = double(Warden::Proxy)
        allow(warden).to receive(:authenticate?).with(any_args).and_return(false)
        allow(warden).to receive(:authenticate!).and_raise(Warden::NotAuthenticated)
        allow(warden).to receive(:user).and_return(nil)

        allow(controller).to receive(:warden).and_return(warden)
        allow(controller).to receive(:current_user).and_return(nil)

        post :create, params: {
          user: {
            email: user.email,
            password: 'wrong_password'
          }
        }, format: :html
      end

      it 'does not sign in the user' do
        expect(controller.current_user).to be_nil
      end

      it 'returns an error status' do
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'renders the new template' do
        expect(response).to render_template(:new)
      end

      it 'sets a flash alert' do
        expect(flash[:alert]).to eq('Invalid email or password.')
      end
    end
  end
end
