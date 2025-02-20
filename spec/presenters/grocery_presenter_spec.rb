require 'rails_helper'
RSpec.describe GroceryPresenter do
  describe '.grouped_groceries' do
    let(:user) { create(:user) }
    let(:fruits_section) { create(:grocery_section, name: 'Fruits', user: user) }
    let(:veggies_section) { create(:grocery_section, name: 'Vegetables', user: user) }
    let(:dairy_section) { create(:grocery_section, name: 'Dairy', user: user) }
    let(:unit) { create(:unit, abbreviation: 'pcs') }

    before(:each) { Grocery.destroy_all }

    context 'with test data' do
      let(:sections) { [fruits_section, veggies_section, dairy_section] }

      it 'groups groceries by their section' do
        g1 = Grocery.create!(
          name: "Test1",
          user: user,
          grocery_section: fruits_section,
          store_section: create(:store_section),
          unit: unit,
          quantity: 5
        )

        g2 = Grocery.create!(
          name: "Test2",
          user: user,
          grocery_section: fruits_section,
          store_section: create(:store_section),
          unit: unit,
          quantity: 3
        )

        g3 = Grocery.create!(
          name: "Test3",
          user: user,
          grocery_section: veggies_section,
          store_section: create(:store_section),
          unit: unit,
          quantity: 6
        )

        result = described_class.grouped_groceries([g1, g2, g3], sections)
        expect(result.keys).to contain_exactly('Fruits', 'Vegetables', 'Dairy')
        expect(result['Fruits'].length).to eq(2)
        expect(result['Vegetables'].length).to eq(1)
        expect(result['Dairy']).to be_empty
      end

      it 'formats each grocery correctly' do
        grocery = create(:grocery, user: user, grocery_section: fruits_section, unit: unit, quantity: 5)
        result = described_class.grouped_groceries([grocery], sections)

        first_grocery = result['Fruits'].first
        expect(first_grocery).to include(
                                   id: grocery.id,
                                   name: grocery.name,
                                   quantity: 5,
                                   unit: 'pcs',
                                   emoji: grocery.emoji
                                 )
      end

      it 'includes empty sections' do
        grocery = create(:grocery, user: user, grocery_section: fruits_section, unit: unit)
        result = described_class.grouped_groceries([grocery], sections)
        expect(result['Dairy']).to eq([])
      end
    end

    context 'with no groceries' do
      let(:sections) { [fruits_section, veggies_section, dairy_section] }

      it 'returns empty arrays for all sections' do
        result = described_class.grouped_groceries([], sections)
        expect(result.keys).to contain_exactly('Fruits', 'Vegetables', 'Dairy')
        expect(result.values).to all(be_empty)
      end
    end

    context 'with no sections' do
      it 'returns an empty hash' do
        grocery = create(:grocery, user: user, grocery_section: fruits_section, unit: unit)
        result = described_class.grouped_groceries([grocery], [])
        expect(result).to be_empty
      end
    end
  end
end