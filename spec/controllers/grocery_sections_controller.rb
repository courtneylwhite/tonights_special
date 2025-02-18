RSpec.describe GrocerySectionsController, type: :controller do
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section) }

  before { sign_in user }

  describe 'GET #index' do
    it 'returns a successful response' do
      get :index
      expect(response).to be_successful
    end
  end

  describe 'GET #show' do
    it 'returns a successful response' do
      get :show, params: { id: grocery_section.id }
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
      let(:valid_params) { { grocery_section: attributes_for(:grocery_section) } }

      it 'creates a new grocery section' do
        expect {
          post :create, params: valid_params
        }.to change(GrocerySection, :count).by(1)
      end

      it 'redirects to the created grocery section' do
        post :create, params: valid_params
        expect(response).to redirect_to(GrocerySection.last)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) { { grocery_section: attributes_for(:grocery_section, name: nil) } }

      it 'does not create a new grocery section' do
        expect {
          post :create, params: invalid_params
        }.not_to change(GrocerySection, :count)
      end

      it 'renders the new template' do
        post :create, params: invalid_params
        expect(response).to render_template(:new)
      end
    end
  end

  describe 'GET #edit' do
    it 'returns a successful response' do
      get :edit, params: { id: grocery_section.id }
      expect(response).to be_successful
    end
  end

  describe 'PATCH #update' do
    context 'with valid parameters' do
      let(:new_attributes) { { name: 'New Section Name' } }

      it 'updates the requested grocery section' do
        patch :update, params: { id: grocery_section.id, grocery_section: new_attributes }
        grocery_section.reload
        expect(grocery_section.name).to eq('New Section Name')
      end

      it 'redirects to the grocery section' do
        patch :update, params: { id: grocery_section.id, grocery_section: new_attributes }
        expect(response).to redirect_to(grocery_section)
      end
    end

    context 'with invalid parameters' do
      let(:invalid_attributes) { { name: nil } }

      it 'does not update the grocery section' do
        original_name = grocery_section.name
        patch :update, params: { id: grocery_section.id, grocery_section: invalid_attributes }
        grocery_section.reload
        expect(grocery_section.name).to eq(original_name)
      end

      it 'renders the edit template' do
        patch :update, params: { id: grocery_section.id, grocery_section: invalid_attributes }
        expect(response).to render_template(:edit)
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested grocery section' do
      grocery_section # Create the grocery section
      expect {
        delete :destroy, params: { id: grocery_section.id }
      }.to change(GrocerySection, :count).by(-1)
    end

    it 'redirects to the grocery sections list' do
      delete :destroy, params: { id: grocery_section.id }
      expect(response).to redirect_to(grocery_sections_url)
    end
  end
end
