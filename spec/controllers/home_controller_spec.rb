require 'rails_helper'

RSpec.describe HomeController, type: :controller do
  describe 'GET #index' do
    before do
      get :index
    end

    it 'returns a successful response' do
      expect(response).to be_successful
    end

    it 'renders the index template' do
      expect(response).to render_template('index')
    end

    it 'assigns @authenticate_path' do
      expect(assigns(:authenticate_path)).to eq(authenticate_path)
    end
  end
end
