require 'rails_helper'

RSpec.describe GroceryMatchingJob, type: :worker do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:section) { create(:grocery_section, user: user) }
    let(:grocery) { create(:grocery, user: user, grocery_section: section, name: 'apple') }
    let(:recipe_category) { create(:recipe_category, user: user) }
    let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }

    before do
      # Set up Sidekiq testing mode
      Sidekiq::Testing.fake!
    end

    after do
      # Reset Sidekiq testing mode
      Sidekiq::Testing.fake!
    end

    it 'enqueues a job' do
      expect {
        GroceryMatchingJob.perform_async(grocery.id)
      }.to change(GroceryMatchingJob.jobs, :size).by(1)
    end

    it 'calls MatchingService with the correct grocery' do
      # Create recipe ingredient without association
      ingredient = create(:recipe_ingredient,
                          recipe: recipe,
                          name: 'apple',
                          grocery_id: nil)

      # Mock the matching service response
      expected_result = {
        grocery_id: grocery.id,
        grocery_name: 'apple',
        matched_ingredients: 1
      }

      # Expect MatchingService to be called with the grocery
      expect(MatchingService).to receive(:match_grocery_to_ingredients)
                                   .with(grocery)
                                   .and_return(expected_result)

      # Perform the job
      GroceryMatchingJob.new.perform(grocery.id)
    end

    it 'handles non-existent grocery gracefully' do
      non_existent_id = -1

      # Call with a non-existent ID
      expect {
        GroceryMatchingJob.new.perform(non_existent_id)
      }.not_to raise_error
    end

    it 'logs errors when matching fails' do
      # Set up the error
      allow(MatchingService).to receive(:match_grocery_to_ingredients)
                                  .with(grocery)
                                  .and_raise(StandardError.new("Test error"))

      # Expect error to be logged and re-raised
      expect(Rails.logger).to receive(:error).at_least(:once)

      # Expect the error to be re-raised
      expect {
        GroceryMatchingJob.new.perform(grocery.id)
      }.to raise_error(StandardError, "Test error")
    end
  end
end
