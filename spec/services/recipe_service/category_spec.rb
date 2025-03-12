require 'rails_helper'

RSpec.describe RecipeServices::Category do
  let(:user) { create(:user) }

  describe '#create_new_category' do
    context 'with valid params' do
      let(:params) { { name: 'Breakfast', display_order: 1 } }

      it 'creates a new recipe category' do
        service = described_class.new(user, params)

        expect {
          result = service.create_new_category
          expect(result[:success]).to be true
        }.to change(RecipeCategory, :count).by(1)
      end

      it 'associates the category with the user' do
        service = described_class.new(user, params)
        result = service.create_new_category

        expect(result[:category].user).to eq(user)
      end

      it 'sets the name and display order correctly' do
        service = described_class.new(user, params)
        result = service.create_new_category

        expect(result[:category].name).to eq('Breakfast')
        expect(result[:category].display_order).to eq(1)
      end
    end

    context 'with missing name' do
      let(:params) { { display_order: 1 } }

      it 'returns nil' do
        service = described_class.new(user, params)
        result = service.create_new_category

        expect(result).to be_nil
      end

      it 'does not create a category' do
        service = described_class.new(user, params)

        expect {
          service.create_new_category
        }.not_to change(RecipeCategory, :count)
      end
    end

    context 'with display order conflicts' do
      before do
        create(:recipe_category, name: 'Existing Category', display_order: 1, user: user)
      end

      it 'increments the display order when there is a conflict' do
        params = { name: 'New Category', display_order: 1 }
        service = described_class.new(user, params)
        result = service.create_new_category

        expect(result[:success]).to be true
        expect(result[:category].display_order).to be > 1
      end

      it 'uses the highest existing display order + 1 when no display order is provided' do
        create(:recipe_category, name: 'Another Category', display_order: 3, user: user)

        params = { name: 'New Category' }
        service = described_class.new(user, params)
        result = service.create_new_category

        expect(result[:success]).to be true
        expect(result[:category].display_order).to eq(4)
      end
    end

    context 'with invalid category data' do
      it 'returns success: false and error messages' do
        # Create a duplicate category to force a validation error
        create(:recipe_category, name: 'Duplicate', user: user)

        params = { name: 'Duplicate' }
        service = described_class.new(user, params)
        result = service.create_new_category

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
      end
    end
  end
end
