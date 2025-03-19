module GroceryServices
  class Creator
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
        if section_attributes.present?
          @section = create_section
          return false unless @section

          grocery_attributes[:grocery_section_id] = @section.id
        end

        @grocery = create_grocery

        if @grocery
          result = true
        else
          raise ActiveRecord::Rollback
        end
      end

      if result && @grocery
        ::GroceryMatchingJob.perform_async(@grocery.id)
      end

      result
    end

    def error_messages
      @errors.join(", ")
    end

    private

    def create_section
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
end
