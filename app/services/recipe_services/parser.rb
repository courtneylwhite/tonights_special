module Recipe
  class Parser
    attr_reader :raw_text

    def initialize(raw_text)
      @raw_text = raw_text
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

    def parse_all_as_ingredients(lines)
      parse_ingredients(lines)
    end

    def parse_ingredients(lines)
      ingredients = []

      lines.each do |line|
        # Skip subheadings or comments
        next if line.match(/^-{3,}$/) || line.match(/^#{3,}$/) || line.match(/^\/\//)

        # Try to extract quantity, unit, and ingredient name
        # Pattern: "1 cup flour" or "1.5 cups flour" or "1/2 cup flour" or "1 1/2 cups flour" etc.
        if (match = line.match(/^((\d+\s+)?\d+\/\d+|\d+(\.\d+)?)\s+([a-zA-Z\s]+)?\s+(.+)$/))
          quantity = match[1].strip
          unit_name = match[4]&.strip || ""
          name = match[5].strip
          # Handle "flour - 1 cup" format
        elsif (match = line.match(/^(.+?)(-|:|\s+)\s*(\d+(?:\.\d+)?|\d+\/\d+|\d+\s+\d+\/\d+)\s+([a-zA-Z\s]+)?$/))
          name = match[1].strip
          quantity = match[3].strip
          unit_name = match[4]&.strip || ""
          # Handle case with just "flour" as an ingredient
        else
          name = line.gsub(/^[-*•]/, "").strip
          quantity = "1"
          unit_name = ""
        end

        # Clean up text
        name = clean_ingredient_name(name)

        ingredients << {
          name: name,
          quantity: quantity.to_f,
          unit_name: unit_name
        }
      end

      ingredients
    end

    def parse_instructions(lines)
      instructions = []
      current_instruction = ""

      lines.each do |line|
        # Remove step numbers (e.g., "1." or "Step 1:")
        cleaned_line = line.gsub(/^\d+[\.\)]\s*|^Step\s+\d+[\.\:]\s*/i, "").strip

        # Skip empty lines or separator lines
        next if cleaned_line.empty? || cleaned_line.match(/^-{3,}$/) || cleaned_line.match(/^#{3,}$/)

        # Check if this is a new step or a continuation
        if line.match(/^\d+[\.\)]|^Step\s+\d+[\.\:]/i) || current_instruction.empty?
          # Save previous instruction if it exists
          instructions << current_instruction if !current_instruction.empty?
          current_instruction = cleaned_line
        else
          # Continue previous instruction
          current_instruction += " " + cleaned_line
        end
      end

      # Add the last instruction
      instructions << current_instruction if !current_instruction.empty?

      instructions.join("\n\n")
    end

    def clean_ingredient_name(name)
      # Remove common non-essential phrases
      name = name.gsub(/,\s+(to taste|for garnish|optional)/, "")

      # Remove trailing punctuation
      name = name.gsub(/[,;.]$/, "")

      name.strip
    end
  end
end