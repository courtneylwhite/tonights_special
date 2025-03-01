module RecipeServices
  class Parser
    attr_reader :raw_text

    # Unicode fraction characters mapping to their standard fraction format for Ingreedy
    UNICODE_FRACTIONS = {
      "½" => "1/2",
      "⅓" => "1/3",
      "⅔" => "2/3",
      "¼" => "1/4",
      "¾" => "3/4",
      "⅕" => "1/5",
      "⅖" => "2/5",
      "⅗" => "3/5",
      "⅘" => "4/5",
      "⅙" => "1/6",
      "⅚" => "5/6",
      "⅛" => "1/8",
      "⅜" => "3/8",
      "⅝" => "5/8",
      "⅞" => "7/8"
    }

    # Common preparation verbs that should be separated from ingredient names
    PREP_VERBS = [
      'chopped', 'minced', 'diced', 'sliced', 'grated', 'shredded', 'julienned',
      'cubed', 'crushed', 'mashed', 'peeled', 'trimmed', 'halved', 'quartered',
      'crumbled', 'melted', 'softened', 'divided', 'sifted', 'beaten', 'whisked',
      'torn', 'ground', 'pitted', 'seeded', 'cored', 'blanched', 'toasted', 'roasted',
      'boiled', 'steamed', 'fried', 'baked', 'grilled', 'broiled', 'sauteed', 'sautéed'
    ]

    # Size-related adjectives that should be separated from ingredient names
    SIZE_ADJECTIVES = [
      'small', 'medium', 'large', 'mini', 'tiny', 'petite', 'big', 'extra-large', 'jumbo',
      'bite-size', 'bite-sized', 'thin', 'thick', 'short', 'long', 'coarse', 'fine'
    ]

    # Descriptors that should be removed from ingredient names
    DESCRIPTORS_TO_REMOVE = [
      'freshly', 'fresh', 'homemade', 'finely', 'thinly', 'roughly', 'heaping'
    ]

    def initialize(raw_text)
      @raw_text = normalize_unicode_fractions(raw_text)
      @notes = []
    end

    def normalize_unicode_fractions(text)
      # Replace unicode fractions with standard fraction format for Ingreedy
      UNICODE_FRACTIONS.each do |fraction, standard|
        text = text.gsub(fraction, standard)
      end
      text
    end

    # Method for parsing only ingredients (used when ingredients are provided separately)
    def parse_ingredients_only
      # Split lines and parse each one as an ingredient
      lines = @raw_text.split("\n").map(&:strip).reject(&:empty?)
      parsed_ingredients = parse_ingredients(lines)

      {
        ingredients: parsed_ingredients,
        notes: @notes.compact.uniq
      }
    end

    # Legacy method for backward compatibility (used when ingredients and instructions are combined)
    def parse
      # Split the text into sections using the headers
      sections = extract_sections(@raw_text)

      # Get ingredients and instructions from the sections
      ingredients_text = sections[:ingredients] || ""
      instructions_text = sections[:instructions] || ""

      # Parse the ingredients
      parsed_ingredients = parse_ingredients(ingredients_text.split("\n"))

      # Format the instructions as a clean string
      formatted_instructions = format_instructions(instructions_text)

      {
        ingredients: parsed_ingredients,
        instructions: formatted_instructions,
        notes: @notes.compact.uniq
      }
    end

    private

    def extract_sections(text)
      sections = {}

      # Try to find the ingredients section
      if ingredients_match = text.match(/Ingredients:(.*?)(?=Instructions:|$)/im)
        sections[:ingredients] = ingredients_match[1].strip
      end

      # Try to find the instructions section
      if instructions_match = text.match(/Instructions:(.*?)$/im)
        sections[:instructions] = instructions_match[1].strip
      end

      sections
    end

    def parse_ingredients(lines)
      ingredients = []

      lines.each do |line|
        # Skip empty lines
        next if line.strip.empty?

        # Check for alternatives (or) in the line
        if line.include?(' or ')
          alternatives = extract_alternatives(line)
          if alternatives[:has_alternative]
            @notes << "Alternative ingredient: can use #{alternatives[:alternative]} instead of #{alternatives[:primary]}"
            line = alternatives[:primary_text]
          end
        end

        begin
          # Use Ingreedy to parse the ingredient line
          parsed = Ingreedy.parse(line.strip)

          # Extract name, quantity, and unit
          name = parsed.ingredient
          quantity = parsed.amount ? parsed.amount.to_f : 1.0
          unit = parsed.unit || "whole"

          # Process the ingredient name to extract preparation and size
          processed_name = process_ingredient_name(name)

          # Add to ingredients list
          ingredients << {
            name: processed_name[:name],
            quantity: quantity,
            unit_name: unit.to_s,
            preparation: processed_name[:preparation],
            size: processed_name[:size]
          }
        rescue => e
          # If Ingreedy fails, fall back to simple extraction
          Rails.logger.warn("Ingreedy failed to parse: #{line}. Error: #{e.message}")

          # Simple fallback parsing
          processed_name = process_ingredient_name(line)

          ingredients << {
            name: processed_name[:name],
            quantity: 1.0,
            unit_name: "whole",
            preparation: processed_name[:preparation],
            size: processed_name[:size]
          }
        end
      end

      ingredients
    end

    def format_instructions(instructions_text)
      # Split into paragraphs or steps
      steps = instructions_text.split(/\n+/)

      # Clean up each step and remove leading numbers if present
      cleaned_steps = steps.map do |step|
        # Remove leading "1. " or similar step numbers
        step.gsub(/^\d+[\.\)]\s*/, '').strip
      end

      # Join with double newlines to create paragraphs
      cleaned_steps.reject(&:empty?).join("\n\n")
    end

    def extract_alternatives(line)
      result = { has_alternative: false, primary: nil, alternative: nil, primary_text: line }

      parts = line.split(' or ', 2).map(&:strip)
      if parts.size == 2
        # Check if this is a preparation alternative rather than an ingredient alternative
        is_prep_alternative = parts[1].split.size <= 3 &&
          PREP_VERBS.any? { |verb| parts[1].downcase.include?(verb) }

        unless is_prep_alternative
          result[:has_alternative] = true
          result[:primary_text] = parts[0]
          result[:primary] = parts[0].gsub(/^\d+(\s+\d+\/\d+)?|^\d+\.\d+/, '').
            gsub(/^(tablespoons?|teaspoons?|cups?|ounces?|pounds?)\s+/, '').
            strip
          result[:alternative] = parts[1]
        end
      end

      result
    end

    def process_ingredient_name(raw_name)
      name = raw_name.dup
      preparation = []
      size = []

      # Extract preparation verbs
      PREP_VERBS.each do |verb|
        verb_pattern = /\b#{verb}\b/i
        if name.match(verb_pattern)
          preparation << verb.downcase
          name = name.gsub(verb_pattern, '').strip
        end
      end

      # Extract size adjectives
      SIZE_ADJECTIVES.each do |adj|
        adj_pattern = /\b#{adj}\b/i
        if name.match(adj_pattern)
          size << adj.downcase
          name = name.gsub(adj_pattern, '').strip
        end
      end

      # Remove other descriptors
      DESCRIPTORS_TO_REMOVE.each do |desc|
        desc_pattern = /\b#{desc}\b/i
        name = name.gsub(desc_pattern, '').strip
      end

      # Clean up the name
      name = clean_ingredient_name(name)

      {
        name: name,
        preparation: preparation.join(', '),
        size: size.join(', ')
      }
    end

    def clean_ingredient_name(name)
      # Remove parenthetical notes
      name = name.gsub(/\(.*?\)/, '')

      # Remove quantifiers that might be at the beginning
      name = name.gsub(/^\d+(\s+\d+\/\d+)?|^\d+\.\d+|\d+\s+cups?|\d+\s+tablespoons?|\d+\s+teaspoons?|\d+\s+ounces?/, '').strip

      # Common phrases to remove
      common_phrases = [
        'to taste',
        'for garnish',
        'for serving',
        'optional',
        'divided',
        'or more to taste',
        'as needed',
        'or to taste',
        'or as needed',
        'heaping',
        'about'
      ]

      # Remove these phrases
      common_phrases.each do |phrase|
        name = name.gsub(/,?\s+#{phrase}/i, '')
        name = name.gsub(/\b#{phrase}\b/i, '')
      end

      # Remove everything after a comma if it's likely a descriptor
      if name.include?(',')
        parts = name.split(',', 2)
        if parts[1].split.size <= 3 && !parts[1].include?(':')
          name = parts[0]
        end
      end

      # Clean up formatting
      name = name.gsub(/^[,;.\s]+|[,;.\s]+$/, '')  # Remove leading/trailing punctuation
      name = name.gsub(/\s+/, ' ')                  # Remove multiple spaces

      name.strip.downcase
    end
  end
end
