require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  # Create a test controller that inherits from ApplicationController
  controller do
    def index
      render plain: "index"
    end
  end

  describe 'CSRF Protection' do
    it 'allows JSON requests' do
      request.content_type = 'application/json'
      get :index
      expect(response).to have_http_status(:success)
    end
  end

  describe 'Favicon' do
    controller do
      def index
        render plain: "test"
      end

      def test_favicon
        favicon
      end
    end

    it 'sends the favicon file' do
      expect(controller).to receive(:send_file).with(
        Rails.root.join("app", "assets", "images", "favicon.svg"),
        { type: "image/svg+xml", disposition: "inline" }
      ) do
        controller.head :ok # This prevents the template missing error
      end

      routes.draw { get 'test_favicon' => 'anonymous#test_favicon' }
      get :test_favicon
    end
  end

  describe 'Devise configuration' do
    let(:devise_parameter_sanitizer) { double('devise_parameter_sanitizer') }

    before do
      allow(controller).to receive(:devise_parameter_sanitizer).and_return(devise_parameter_sanitizer)
      allow(controller).to receive(:devise_controller?).and_return(true)
    end

    it 'permits the correct parameters for sign up' do
      expect(devise_parameter_sanitizer).to receive(:permit).with(
        :sign_up,
        keys: [ :email, :password, :password_confirmation ]
      )
      controller.send(:configure_permitted_parameters)
    end
  end

  describe 'Redirection paths' do
    include Rails.application.routes.url_helpers

    controller do
      def index
        render plain: "index"
      end

      # Make the methods public for testing
      public :after_sign_in_path_for, :after_sign_out_path_for
    end

    # Mock route helper
    before do
      allow(controller).to receive(:root_path).and_return('/')
    end

    it 'redirects to pantry path after sign in' do
      expect(controller.after_sign_in_path_for(:user)).to eq('/groceries')
    end

    it 'redirects to root path after sign out' do
      expect(controller.after_sign_out_path_for(:user)).to eq('/')
    end
  end

  describe 'Helper inclusion' do
    it 'includes ReactHelper' do
      expect(controller.class.helpers).to respond_to(:react_component)
    end
  end
end
