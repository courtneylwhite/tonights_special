# frozen_string_literal: true

module GroceryServices
  class EmojiMatcher
    class << self
      def find_emoji(grocery_name)
        return nil if grocery_name.blank?

        grocery_name = grocery_name.to_s.downcase.strip

        # First check for exact matches
        emoji_mappings.each do |emoji, keywords|
          return emoji if keywords.include?(grocery_name)
        end

        # Then check for partial matches (contains any keyword)
        emoji_mappings.each do |emoji, keywords|
          keywords.each do |keyword|
            return emoji if grocery_name.include?(keyword)
          end
        end

        # Then check if any word in the grocery name matches any keyword
        grocery_words = grocery_name.split(/\s+/).reject { |w| w.length <= 2 }
        grocery_words.each do |word|
          emoji_mappings.each do |emoji, keywords|
            return emoji if keywords.include?(word)
          end
        end

        # Return default emoji if no match found
        emoji_mappings.key?("🛒") ? "🛒" : "🛒"
      end

      def emoji_mappings
        @emoji_mappings ||= load_emoji_mappings
      end

      def reload_mappings!
        @emoji_mappings = load_emoji_mappings
      end

      def available_emojis
        emoji_mappings.keys
      end

      def keywords_for_emoji(emoji)
        emoji_mappings[emoji] || []
      end

      private

      def load_emoji_mappings
        yaml_path = Rails.root.join("config", "grocery_emoji_mappings.yml")
        YAML.load_file(yaml_path)
      rescue StandardError => e
        Rails.logger.error "Failed to load emoji mappings: #{e.message}"
        { "🛒" => [ "default" ] } # Fallback to a default mapping
      end
    end
  end
end
