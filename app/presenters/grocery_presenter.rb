class GroceryPresenter
  def self.grouped_groceries(groceries)
    groceries.map { |grocery| format_grocery(grocery) }
             .group_by { |g| g.delete(:category) }
  end

  private

  def self.format_grocery(grocery)
    {
      id: grocery.id,
      name: grocery.name,
      quantity: grocery.quantity,
      unit: grocery.unit.abbreviation,
      emoji: grocery.emoji,
      category: grocery.grocery_section.name
    }
  end
end