require 'rails_helper'

RSpec.describe GroceryServices::EmojiMatcher do
  describe '.find_emoji' do
    # Test exact matches
    context 'when finding exact matches' do
      it 'returns apple emoji for "apple"' do
        expect(described_class.find_emoji('apple')).to eq('🍎')
      end

      it 'returns banana emoji for "banana"' do
        expect(described_class.find_emoji('banana')).to eq('🍌')
      end
    end

    # Test case insensitivity
    context 'when matching is case-insensitive' do
      it 'matches regardless of case' do
        expect(described_class.find_emoji('APPLE')).to eq('🍎')
        expect(described_class.find_emoji('Banana')).to eq('🍌')
      end
    end

    # Test whitespace handling
    context 'when handling whitespace' do
      it 'matches with leading and trailing whitespace' do
        expect(described_class.find_emoji('  apple  ')).to eq('🍎')
      end
    end

    # Test partial matches
    context 'when finding partial matches' do
      it 'matches with partial keywords' do
        expect(described_class.find_emoji('honeycrisp apple')).to eq('🍎')
        expect(described_class.find_emoji('green apple')).to eq('🍎')
      end
    end

    # Test word-level matches
    context 'when matching individual words' do
      it 'matches words in longer strings' do
        expect(described_class.find_emoji('fresh organic banana')).to eq('🍌')
        expect(described_class.find_emoji('spicy chicken with bell pepper')).to eq('🫑')
      end
    end

    # Test variant matches
    context 'when handling variants' do
      it 'matches different variants of the same item' do
        expect(described_class.find_emoji('granny smith')).to eq('🍎')
        expect(described_class.find_emoji('cherry tomato')).to eq('🍅')
      end
    end

    # Test default emoji fallback
    context 'when no match is found' do
      it 'returns shopping cart emoji for unrecognized items' do
        expect(described_class.find_emoji('unknown item')).to eq('🛒')
      end

      it 'returns nil for blank input' do
        expect(described_class.find_emoji('')).to be_nil
        expect(described_class.find_emoji(nil)).to be_nil
      end

      it 'returns shopping cart emoji for unrecognized non-blank items' do
        expect(described_class.find_emoji('unknown item')).to eq('🛒')
      end
    end

    # Test emoji mapping methods
    describe '.available_emojis' do
      it 'returns a non-empty array of emojis' do
        expect(described_class.available_emojis).to be_an(Array)
        expect(described_class.available_emojis).not_to be_empty
        expect(described_class.available_emojis).to include('🍎', '🍌', '🛒')
      end
    end

    describe '.keywords_for_emoji' do
      it 'returns keywords for a given emoji' do
        apple_keywords = described_class.keywords_for_emoji('🍎')
        expect(apple_keywords).to include('apple', 'honeycrisp', 'granny smith')
      end

      it 'returns an empty array for an unknown emoji' do
        expect(described_class.keywords_for_emoji('❌')).to eq([])
      end
    end

    # Reload mappings method
    describe '.reload_mappings!' do
      it 'allows reloading of emoji mappings' do
        expect { described_class.reload_mappings! }.not_to raise_error
      end
    end
  end
end
