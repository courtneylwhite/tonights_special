require 'rails_helper'

RSpec.describe GroceryCreator do
  let(:user) { create(:user) }
  let(:grocery_section) { create(:grocery_section, user: user) }
  let(:unit) { create(:unit) }

  describe '#call' do
    context 'when creating just a grocery' do
      let(:grocery_attributes) do
        {
          name: 'Test Grocery',
          quantity: 5,
          unit_id: unit.id,
          grocery_section_id: grocery_section.id,
          emoji: 'U+1F34E'
        }
      end

      it 'creates a grocery item successfully' do
        creator = GroceryCreator.new(user, grocery_attributes)

        expect { creator.call }.to change(Grocery, :count).by(1)
        expect(creator.grocery.name).to eq('test grocery')
        expect(creator.grocery.user).to eq(user)
        expect(creator.errors).to be_empty
      end

      it 'returns false and has errors when grocery creation fails' do
        grocery_attributes[:name] = '' # Should trigger validation error

        creator = GroceryCreator.new(user, grocery_attributes)

        expect(creator.call).to be false
        expect(creator.grocery).to be_nil
        expect(creator.errors).not_to be_empty
        expect(creator.error_messages).to include("Name can't be blank")
      end
    end

    context 'when creating a grocery with a new section' do
      let(:grocery_attributes) do
        {
          name: 'Test Grocery',
          quantity: 5,
          unit_id: unit.id,
          emoji: 'U+1F34E'
        }
      end

      let(:section_attributes) do
        {
          name: 'New Test Section',
          display_order: 5
        }
      end

      it 'creates both a section and a grocery' do
        creator = GroceryCreator.new(user, grocery_attributes, section_attributes)

        expect {
          expect(creator.call).to be true
        }.to change(Grocery, :count).by(1).and change(GrocerySection, :count).by(1)

        expect(creator.section.name).to eq('New Test Section')
        expect(creator.grocery.grocery_section).to eq(creator.section)
      end

      it 'handles section creation without display_order' do
        section_attributes.delete(:display_order)
        creator = GroceryCreator.new(user, grocery_attributes, section_attributes)

        expect {
          expect(creator.call).to be true
        }.to change(Grocery, :count).by(1).and change(GrocerySection, :count).by(1)

        # Should assign a default display_order
        expect(creator.section.display_order).to be_present
      end

      it 'returns false and has errors when section creation fails' do
        section_attributes[:name] = '' # Should trigger validation error

        creator = GroceryCreator.new(user, grocery_attributes, section_attributes)

        expect {
          expect(creator.call).to be false
        }.to change(Grocery, :count).by(0).and change(GrocerySection, :count).by(0)

        expect(creator.errors).not_to be_empty
      end

      it 'does not create a grocery if section creation fails' do
        section_attributes[:name] = '' # Should trigger validation error

        creator = GroceryCreator.new(user, grocery_attributes, section_attributes)

        expect {
          creator.call
        }.not_to change(Grocery, :count)

        expect(creator.grocery).to be_nil
      end
    end

    context 'transaction integrity' do
      let(:grocery_attributes) do
        {
          name: 'Test Grocery',
          quantity: 5,
          unit_id: unit.id,
          emoji: 'U+1F34E'
        }
      end

      let(:section_attributes) { { name: 'New Section' } }

      it 'rolls back section creation if grocery creation fails' do
        # Make section creation succeed but grocery creation fail
        allow_any_instance_of(Grocery).to receive(:save).and_return(false)
        allow_any_instance_of(Grocery).to receive(:errors).and_return(
          ActiveModel::Errors.new(Grocery.new).tap { |e| e.add(:base, "Forced failure") }
        )

        creator = GroceryCreator.new(user, grocery_attributes, section_attributes)

        expect {
          creator.call
        }.to change(GrocerySection, :count).by(0)

        expect(creator.errors).to include("Forced failure")
      end
    end
  end
end
