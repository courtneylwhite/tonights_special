require 'rails_helper'

RSpec.describe StoreSectionsController, type: :controller do
  let(:user) { create(:user) }
  let(:store_section) { create(:store_section) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { id: store_section.id }
      expect(response).to be_successful
    end
  end

  describe 'GET #new' do
    it 'returns a successful response' do
      get :new
      expect(response).to be_successful
    end
  end

  describe 'POST #create' do
    context 'with valid parameters' do
      let(:valid_params) { { store_section: attributes_for(:store_section) } }

      it 'creates a new store section' do
        expect {
          post :create, params: valid_params
        }.to change(StoreSection, :count).by(1)
      end

      it 'redirects to the created store section' do
        post :create, params: valid_params
        expect(response).to redirect_to(StoreSection.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { store_section: attributes_for(:store_section, name: nil) } }

      it 'does not create a new store section' do
        expect {
          post :create, params: invalid_params
        }.not_to change(StoreSection, :count)
      end

      it 'renders the new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit, params: { id: store_section.id }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'New Section Name' } }

      it 'updates the requested store section' do
        patch :update, params: { id: store_section.id, store_section: new_attributes }
        store_section.reload
        expect(store_section.name).to eq('New Section Name')
      end

      it 'redirects to the store section' do
        patch :update, params: { id: store_section.id, store_section: new_attributes }
        expect(response).to redirect_to(store_section)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: nil } }

      it 'does not update the store section' do
        original_name = store_section.name
        patch :update, params: { id: store_section.id, store_section: invalid_attributes }
        store_section.reload
        expect(store_section.name).to eq(original_name)
      end

      it 'renders the edit template' do
        patch :update, params: { id: store_section.id, store_section: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested store section' do
      store_section # Create the store section
      expect {
        delete :destroy, params: { id: store_section.id }
      }.to change(StoreSection, :count).by(-1)
    end

    it 'redirects to the store sections list' do
      delete :destroy, params: { id: store_section.id }
      expect(response).to redirect_to(store_sections_url)
    end
  end
end
