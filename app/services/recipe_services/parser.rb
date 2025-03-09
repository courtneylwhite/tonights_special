module RecipeServices
  class Parser
    attr_reader :raw_text, :notes

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

    PREP_VERBS = %w[chopped minced diced sliced grated shredded julienned cubed crushed mashed peeled trimmed halved quartered crumbled melted softened divided sifted beaten whisked torn ground pitted seeded cored blanched toasted roasted boiled steamed fried baked grilled broiled sauteed sautéed]

    SIZE_ADJECTIVES = %w[small medium large mini tiny petite big extra-large jumbo bite-size bite-sized thin thick short long coarse fine]

    DESCRIPTORS_TO_REMOVE = %w[freshly fresh homemade finely thinly roughly heaping]

    COMMON_PHRASES = [
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

    def initialize(raw_text)
      @raw_text = normalize_unicode_fractions(raw_text)
      @notes = []
    end

    def normalize_unicode_fractions(text)
      UNICODE_FRACTIONS.each do |fraction, standard|
        text = text.gsub(fraction, standard)
      end
      text
    end

    def parse_ingredients
      lines = @raw_text.split("\n").map(&:strip).reject(&:empty?)
      parsed_ingredients = parse_ingredient_lines(lines)

      {
        ingredients: parsed_ingredients,
        notes: @notes.compact.uniq
      }
    end

    private

    def parse_ingredient_lines(lines)
      ingredients = []

      lines.each do |line|
        next if line.strip.empty?

        alternatives = extract_alternatives(line)
        if alternatives[:has_alternative]
          @notes << "Alternative ingredient: can use #{alternatives[:alternative]} instead of #{alternatives[:primary]}"
          line = alternatives[:primary_text]
        end

        begin
          ingredients << parse_single_ingredient(line)
        rescue => e
          Rails.logger.warn("Ingredient parsing failed for: #{line}. Error: #{e.message}")
          ingredients << create_fallback_ingredient(line)
        end
      end

      ingredients
    end

    def parse_single_ingredient(line)
      parsed = Ingreedy.parse(line.strip)

      name = parsed.ingredient
      quantity = parsed.amount ? parsed.amount.to_f : 1.0
      unit = parsed.unit || "whole"

      processed_name = process_ingredient_name(name)

      {
        name: processed_name[:name],
        quantity: quantity,
        unit_name: unit.to_s,
        preparation: processed_name[:preparation],
        size: processed_name[:size]
      }
    end

    def create_fallback_ingredient(line)
      processed_name = process_ingredient_name(line)

      {
        name: processed_name[:name],
        quantity: 1.0,
        unit_name: "whole",
        preparation: processed_name[:preparation],
        size: processed_name[:size]
      }
    end

    def extract_alternatives(line)
      result = { has_alternative: false, primary: nil, alternative: nil, primary_text: line }

      parts = line.split(' or ', 2).map(&:strip)
      if parts.size == 2
        is_prep_alternative = parts[1].split.size <= 3 &&
          PREP_VERBS.any? { |verb| parts[1].downcase.include?(verb) }

        unless is_prep_alternative
          result[:has_alternative] = true
          result[:primary_text] = parts[0]
          result[:primary] = extract_base_ingredient_name(parts[0])
          result[:alternative] = parts[1]
        end
      end

      result
    end

    def extract_base_ingredient_name(text)
      text.gsub(/^\d+(\s+\d+\/\d+)?|^\d+\.\d+/, '').
        gsub(/^(tablespoons?|teaspoons?|cups?|ounces?|pounds?)\s+/, '').
        strip
    end

    def process_ingredient_name(raw_name)
      name = raw_name.dup
      preparation = extract_preparation_words(name)
      size = extract_size_words(name)
      name = remove_descriptors(name)
      name = clean_ingredient_name(name)

      {
        name: name,
        preparation: preparation.join(', '),
        size: size.join(', ')
      }
    end

    def extract_preparation_words(name)
      preparation = []
      result_name = name.dup

      PREP_VERBS.each do |verb|
        verb_pattern = /\b#{verb}\b/i
        if result_name.match(verb_pattern)
          preparation << verb.downcase
          result_name.gsub!(verb_pattern, '')
        end
      end

      name.replace(result_name)

      preparation
    end

    def extract_size_words(name)
      size = []
      result_name = name.dup

      SIZE_ADJECTIVES.each do |adj|
        adj_pattern = /\b#{adj}\b/i
        if result_name.match(adj_pattern)
          size << adj.downcase
          result_name.gsub!(adj_pattern, '')
        end
      end

      name.replace(result_name)

      size
    end

    def remove_descriptors(name)
      result = name.dup

      DESCRIPTORS_TO_REMOVE.each do |desc|
        desc_pattern = /\b#{desc}\b/i
        result.gsub!(desc_pattern, '')
      end

      result.strip
    end

    def clean_ingredient_name(name)
      # Remove parenthetical notes
      name = name.gsub(/\(.*?\)/, '')

      # Remove quantifiers that might be at the beginning
      name = name.gsub(/^\d+(\s+\d+\/\d+)?|^\d+\.\d+|\d+\s+cups?|\d+\s+tablespoons?|\d+\s+teaspoons?|\d+\s+ounces?/, '').strip

      # Remove common phrases
      COMMON_PHRASES.each do |phrase|
        name = name.gsub(/,?\s+#{phrase}/i, '')
        name = name.gsub(/\b#{phrase}\b/i, '')
      end

      # Handle comma-separated descriptors
      name = handle_comma_descriptors(name)

      # Clean up formatting
      name = name.gsub(/^[,;.\s]+|[,;.\s]+$/, '')  # Remove leading/trailing punctuation
      name = name.gsub(/\s+/, ' ')                  # Remove multiple spaces

      name.strip.downcase
    end

    def handle_comma_descriptors(name)
      # Remove everything after a comma if it's likely a descriptor
      if name.include?(',')
        parts = name.split(',', 2)
        if parts[1].split.size <= 3 && !parts[1].include?(':')
          return parts[0]
        end
      end

      name
    end
  end
end
