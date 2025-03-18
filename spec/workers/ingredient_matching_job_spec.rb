require 'rails_helper'

RSpec.describe IngredientMatchingJob, type: :worker do
  describe '#perform' do
    let(:user) { create(:user) }
    let(:section) { create(:grocery_section, user: user) }
    let(:recipe_category) { create(:recipe_category, user: user) }
    let(:recipe) { create(:recipe, user: user, recipe_category: recipe_category) }
    let(:grocery) { create(:grocery, user: user, grocery_section: section, name: 'carrot') }
    let(:ingredient) { create(:recipe_ingredient, recipe: recipe, name: 'carrots', grocery_id: nil) }

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
        IngredientMatchingJob.perform_async(ingredient.id, user.id)
      }.to change(IngredientMatchingJob.jobs, :size).by(1)
    end

    it 'calls MatchingService with the correct parameters' do
      # Expect MatchingService to be called and return a grocery
      expect(MatchingService).to receive(:match_ingredient_to_grocery)
                                   .with(user, ingredient.name)
                                   .and_return(grocery)

      # Perform the job
      IngredientMatchingJob.new.perform(ingredient.id, user.id)

      # Reload the ingredient to see if it was updated
      ingredient.reload
      expect(ingredient.grocery_id).to eq(grocery.id)
    end

    it 'does nothing when no matching grocery is found' do
      # Expect MatchingService to be called and return nil
      expect(MatchingService).to receive(:match_ingredient_to_grocery)
                                   .with(user, ingredient.name)
                                   .and_return(nil)

      # Perform the job
      IngredientMatchingJob.new.perform(ingredient.id, user.id)

      # Reload the ingredient to confirm it wasn't updated
      ingredient.reload
      expect(ingredient.grocery_id).to be_nil
    end

    it 'handles non-existent ingredient gracefully' do
      non_existent_id = -1

      # Call with a non-existent ID
      expect {
        IngredientMatchingJob.new.perform(non_existent_id, user.id)
      }.not_to raise_error
    end

    it 'handles non-existent user gracefully' do
      non_existent_user_id = -1

      # Call with a non-existent user ID
      expect {
        IngredientMatchingJob.new.perform(ingredient.id, non_existent_user_id)
      }.not_to raise_error
    end

    it 'logs errors when matching fails' do
      # Set up the error
      allow(MatchingService).to receive(:match_ingredient_to_grocery)
                                  .with(user, ingredient.name)
                                  .and_raise(StandardError.new("Test error"))

      # Expect error to be logged and re-raised
      expect(Rails.logger).to receive(:error).at_least(:once)

      # Expect the error to be re-raised
      expect {
        IngredientMatchingJob.new.perform(ingredient.id, user.id)
      }.to raise_error(StandardError, "Test error")
    end
  end
end
