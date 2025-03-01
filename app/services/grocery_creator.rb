class GroceryCreator
  attr_reader :user, :grocery_attributes, :section_attributes, :errors, :grocery, :section

  def initialize(user, grocery_attributes, section_attributes = nil)
    @user = user
    @grocery_attributes = grocery_attributes
    @section_attributes = section_attributes
    @errors = []
    @grocery = nil
    @section = nil
  end

  def call
    result = false

    ActiveRecord::Base.transaction do
      # Create section if needed
      if section_attributes.present?
        @section = create_section
        return false unless @section

        # Assign the section id to the grocery
        grocery_attributes[:grocery_section_id] = @section.id
      end

      # Create the grocery
      @grocery = create_grocery

      if @grocery
        result = true
      else
        raise ActiveRecord::Rollback
      end
    end

    result
  end

  def error_messages
    @errors.join(", ")
  end

  private

  def create_section
    # Set a default display order if not provided
    if !section_attributes.key?(:display_order) || section_attributes[:display_order].nil?
      section_attributes[:display_order] = user.grocery_sections.count + 1
    end

    section = user.grocery_sections.build(section_attributes)

    if section.save
      section
    else
      @errors += section.errors.full_messages
      nil
    end
  end

  def create_grocery
    grocery_attributes[:name] = grocery_attributes[:name]&.downcase

    grocery = user.groceries.build(grocery_attributes)

    if grocery.save
      grocery
    else
      @errors += grocery.errors.full_messages
      nil
    end
  end
end
