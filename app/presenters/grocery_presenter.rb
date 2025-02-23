class GroceryPresenter
  def self.grouped_groceries(groceries, sections)
    # First, format all groceries and group them by category
    grouped = groceries.map { |grocery| format_grocery(grocery) }
                       .group_by { |g| g.delete(:category) }

    # Create a hash with all sections, even empty ones
    sections.each_with_object({}) do |section, hash|
      hash[section.name] = {
        items: grouped[section.name] || [],
        id: section.id,
        display_order: section.display_order
      }
    end
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
