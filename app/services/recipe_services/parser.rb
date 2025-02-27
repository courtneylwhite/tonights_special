module RecipeServices
  class Parser
    attr_reader :raw_text

    COMMON_UNITS = [
      # Full names
      'cup', 'cups', 'tablespoon', 'tablespoons', 'teaspoon', 'teaspoons',
      'pound', 'pounds', 'ounce', 'ounces', 'gram', 'grams',
      'kilogram', 'kilograms', 'liter', 'liters', 'milliliter', 'milliliters',
      'pint', 'pints', 'quart', 'quarts', 'gallon', 'gallons',
      # Abbreviations
      'tbsp', 'tbsps', 'tsp', 'tsps', 'oz', 'ozs', 'lb', 'lbs',
      'g', 'kg', 'ml', 'l', 'pt', 'qt', 'gal'
    ]

    # Unicode fraction characters mapping to their decimal values
    UNICODE_FRACTIONS = {
      "½" => 0.5,
      "⅓" => 1.0/3,
      "⅔" => 2.0/3,
      "¼" => 0.25,
      "¾" => 0.75,
      "⅕" => 0.2,
      "⅖" => 0.4,
      "⅗" => 0.6,
      "⅘" => 0.8,
      "⅙" => 1.0/6,
      "⅚" => 5.0/6,
      "⅛" => 0.125,
      "⅜" => 0.375,
      "⅝" => 0.625,
      "⅞" => 0.875
    }

    def initialize(raw_text)
      @raw_text = normalize_unicode_fractions(raw_text)
    end

    def normalize_unicode_fractions(text)
      # Replace unicode fractions with their decimal equivalents
      UNICODE_FRACTIONS.each do |fraction, decimal|
        text = text.gsub(fraction, decimal.to_s)
      end
      text
    end

    def parse
      lines = raw_text.split("\n").map(&:strip).reject(&:empty?)

      # Find the indices that separate ingredients from instructions
      ingredient_start_idx = find_section_start(lines, ['ingredients', 'ingredients:'])
      instruction_start_idx = find_section_start(lines, ['instructions', 'instructions:', 'directions', 'directions:', 'steps', 'steps:', 'method', 'method:'])

      # Handle cases where sections aren't explicitly defined
      if ingredient_start_idx.nil? && instruction_start_idx.nil?
        # Attempt to infer based on line structure
        section_break = infer_section_break(lines)

        if section_break
          ingredient_start_idx = 0
          instruction_start_idx = section_break
        else
          # Default to assuming everything is instructions with no ingredients
          return { ingredients: [], instructions: lines.join("\n\n") }
        end
      elsif ingredient_start_idx.nil?
        ingredient_start_idx = 0
        instruction_start_idx = [instruction_start_idx, lines.size].min
      elsif instruction_start_idx.nil?
        instruction_start_idx = lines.size
      end

      # Extract sections
      ingredient_lines = if ingredient_start_idx + 1 < instruction_start_idx
                           lines[(ingredient_start_idx + 1)...instruction_start_idx]
                         else
                           []
                         end

      instruction_lines = if instruction_start_idx + 1 <= lines.size
                            lines[(instruction_start_idx + 1)..]
                          else
                            []
                          end

      {
        ingredients: parse_ingredients(ingredient_lines),
        instructions: instruction_lines.join("\n\n")
      }
    end

    private

    def find_section_start(lines, section_identifiers)
      lines.each_with_index do |line, index|
        line_downcase = line.downcase
        return index if section_identifiers.any? { |identifier| line_downcase == identifier || line_downcase.start_with?(identifier) }
      end
      nil
    end

    def infer_section_break(lines)
      # Look for the pattern change that often indicates transition from ingredients to instructions
      # Ingredients often have quantities and are shorter lines than full instruction sentences

      lines.each_with_index do |line, index|
        next if index < 3 || index >= lines.size - 3  # Skip the first and last few lines

        prev_lines_avg_length = lines[index-3..index-1].map(&:length).sum / 3.0
        next_lines_avg_length = lines[index..index+2].map(&:length).sum / 3.0

        # If we see a significant increase in line length, it might indicate a transition
        # from ingredients to instructions
        if next_lines_avg_length > prev_lines_avg_length * 1.8
          return index
        end

        # Check for numbered steps which often indicate instructions
        if line.match(/^\d+\./) && !lines[index-1].match(/^\d+\./)
          return index
        end
      end

      nil  # No clear transition found
    end

    def parse_ingredients(lines)
      ingredients = []

      lines.each do |line|
        # Skip subheadings or comments
        next if line.match(/^-{3,}$/) || line.match(/^\#{3,}$/) || line.match(/^\/\//)

        # Remove bullet points, asterisks, and list markers
        cleaned_line = line.gsub(/^[-*•]|\d+\.\s*/, '').strip

        # Special handling for common package formats
        # Like "1 (14.5 ounce) can diced tomatoes"
        if match = cleaned_line.match(/^(\d+(?:\.\d+)?)\s+\(([^)]+)\)\s+(\w+)\s+(.+)$/)
          count = match[1].to_f
          parenthetical = match[2].strip
          container = match[3].strip
          item = match[4].strip

          # Check if parenthetical contains a weight/volume
          if weight_match = parenthetical.match(/(\d+(?:\.\d+)?)\s*(\w+)/)
            weight_amount = weight_match[1].to_f
            weight_unit = normalize_unit(weight_match[2])

            # The item name should include the container type
            full_name = "#{container} #{item}"

            ingredients << {
              name: clean_ingredient_name(full_name),
              quantity: count,
              unit_name: "whole"  # The count is of containers, not the contents
            }
          else
            # If no volume/weight in parentheses, treat as regular ingredient
            parsed = parse_ingredient_line(cleaned_line)
            ingredients << parsed if parsed
          end
        else
          # Regular ingredient line parsing
          parsed = parse_ingredient_line(cleaned_line)
          ingredients << parsed if parsed
        end
      end

      ingredients
    end

    def parse_ingredient_line(line)
      # First, handle parenthetical information
      # Extract any information in parentheses for special handling
      parenthetical_info = {}
      line_without_parentheses = line.gsub(/\(([^)]+)\)/) do |match|
        content = $1
        # Check if the parenthesis contains volume or weight info
        if content.match(/\d+(\.\d+)?\s*(ounce|oz|pound|lb|gram|g|ml|cup)s?/i)
          parenthetical_info[:quantity_info] = content
        end
        " " # Replace with space to maintain word separation
      end.gsub(/\s+/, ' ').strip

      # Match patterns like "1 cup flour" or "2 tablespoons sugar"
      # This also covers unicode fractions that have been normalized like "0.5 cup flour"
      if match = line_without_parentheses.match(/^((\d+\s+)?\d+\/\d+|\d+(\.\d+)?)\s+([a-zA-Z\.]+)?\s+(.+)$/)
        quantity = parse_fraction(match[1])
        unit_name = match[4]&.strip&.downcase
        name = match[5].strip

        # Check if what we thought was a unit is actually part of the ingredient name
        if unit_name && !is_likely_unit?(unit_name)
          name = "#{unit_name} #{name}"
          unit_name = "whole" # Default unit when no unit is specified
        end

        # Apply parenthetical info if available
        apply_parenthetical_info(name, quantity, unit_name, parenthetical_info)

        return format_ingredient(name, quantity, unit_name)
      end

      # Match patterns like "flour - 1 cup" or "sugar: 2 tablespoons"
      if match = line_without_parentheses.match(/^(.+?)(-|:|\s+)\s*(\d+(?:\.\d+)?|\d+\/\d+|\d+\s+\d+\/\d+)\s+([a-zA-Z\.]+)?$/)
        name = match[1].strip
        quantity = parse_fraction(match[3])
        unit_name = match[4]&.strip&.downcase

        # If unit is not specified, use "whole"
        unit_name = "whole" unless unit_name && is_likely_unit?(unit_name)

        # Apply parenthetical info if available
        apply_parenthetical_info(name, quantity, unit_name, parenthetical_info)

        return format_ingredient(name, quantity, unit_name)
      end

      # Match just a number followed by ingredient name (implicit unit)
      # Example: "2 eggs" or "3 apples"
      if match = line_without_parentheses.match(/^(\d+(?:\.\d+)?|\d+\/\d+)\s+(.+)$/)
        quantity = parse_fraction(match[1])
        name = match[2].strip

        # Check if the first word might be a unit
        first_word = name.split(' ').first&.downcase
        if first_word && is_likely_unit?(first_word)
          unit_name = first_word
          name = name.sub(/^#{Regexp.escape(first_word)}\s+/, '')
        else
          unit_name = "whole" # Default unit for countable items
        end

        # Apply parenthetical info if available
        apply_parenthetical_info(name, quantity, unit_name, parenthetical_info)

        return format_ingredient(name, quantity, unit_name)
      end

      # Handle case with just ingredient name (no quantity or unit)
      # Example: "Salt to taste" or "Black pepper"
      if line_without_parentheses.strip.length > 0
        name = line_without_parentheses.strip
        return format_ingredient(name, 1, "whole") # Default quantity and unit
      end

      nil
    end

    def apply_parenthetical_info(name, quantity, unit_name, parenthetical_info)
      # This method applies information extracted from parentheses
      # Currently just a placeholder but can be expanded
      # We could use this to handle cases like "1 (14.5 ounce) can diced tomatoes"
    end

    def parse_fraction(fraction_str)
      # Handle mixed fractions like "1 1/2"
      if fraction_str.include?(' ') && fraction_str.include?('/')
        whole, fraction = fraction_str.split(' ', 2)
        numerator, denominator = fraction.split('/')
        return whole.to_f + (numerator.to_f / denominator.to_f)
      end

      # Handle simple fractions like "1/2"
      if fraction_str.include?('/')
        numerator, denominator = fraction_str.split('/')
        return numerator.to_f / denominator.to_f
      end

      # Handle decimals and integers
      fraction_str.to_f
    end

    def is_likely_unit?(word)
      # Remove any trailing periods and make lowercase
      cleaned_word = word.gsub(/\.$/, '').downcase

      # Check against common units list
      COMMON_UNITS.include?(cleaned_word)
    end

    def format_ingredient(name, quantity, unit_name)
      # Clean up the ingredient name
      name = clean_ingredient_name(name)

      # Normalize unit name
      unit_name = normalize_unit(unit_name) if unit_name

      {
        name: name,
        quantity: quantity.to_f,
        unit_name: unit_name || "whole"
      }
    end

    def normalize_unit(unit)
      case unit.downcase.gsub(/\.$/, '') # Remove trailing period
      when 'tbsp', 'tbsps', 'tbs', 'tablespoon', 'tablespoons'
        'tablespoon'
      when 'tsp', 'tsps', 'teaspoon', 'teaspoons'
        'teaspoon'
      when 'c', 'cup', 'cups'
        'cup'
      when 'oz', 'ozs', 'ounce', 'ounces'
        'ounce'
      when 'lb', 'lbs', 'pound', 'pounds'
        'pound'
      when 'g', 'gram', 'grams'
        'gram'
      when 'kg', 'kilogram', 'kilograms'
        'kilogram'
      when 'ml', 'milliliter', 'milliliters'
        'milliliter'
      when 'l', 'liter', 'liters'
        'liter'
      when 'pt', 'pint', 'pints'
        'pint'
      when 'qt', 'quart', 'quarts'
        'quart'
      when 'gal', 'gallon', 'gallons'
        'gallon'
      else
        unit
      end
    end

    def clean_ingredient_name(name)
      # Remove parenthetical notes completely
      name = name.gsub(/\(.*?\)/, '')

      # Common phrases to remove or handle specially
      common_phrases = [
        'to taste',
        'for garnish',
        'optional',
        'divided',
        'or more to taste',
        'as needed',
        'or to taste',
        'or as needed'
      ]

      # Remove these phrases from anywhere in the string
      common_phrases.each do |phrase|
        name = name.gsub(/,?\s+#{phrase}/i, '')
        name = name.gsub(/#{phrase}/i, '')
      end

      # Remove leading/trailing commas, semicolons, and periods
      name = name.gsub(/^[,;.\s]+|[,;.\s]+$/, '')

      # Remove multiple spaces
      name = name.gsub(/\s+/, ' ')

      # Downcase the name
      name.strip.downcase
    end
  end
end