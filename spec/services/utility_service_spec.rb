require 'rails_helper'

RSpec.describe UtilityService do
  describe '.normalize_text' do
    it 'strips whitespace and converts to lowercase' do
      expect(UtilityService.normalize_text('  Hello World  ')).to eq('hello world')
      expect(UtilityService.normalize_text('TESTING')).to eq('testing')
    end

    it 'handles nil input' do
      expect(UtilityService.normalize_text(nil)).to eq('')
    end
  end

  describe '.format_quantity' do
    it 'rounds decimal numbers to two decimal places' do
      expect(UtilityService.format_quantity(3.14159)).to eq(3.14)
      expect(UtilityService.format_quantity(2.005)).to eq(2.01)
    end

    it 'converts whole numbers to integers' do
      expect(UtilityService.format_quantity(5.0)).to eq(5)
      expect(UtilityService.format_quantity(7.00)).to eq(7)
    end

    it 'returns non-numeric values as-is' do
      expect(UtilityService.format_quantity('abc')).to eq('abc')
      expect(UtilityService.format_quantity(nil)).to be_nil
    end
  end

  describe '.normalize_unit_name' do
    it 'normalizes various tablespoon abbreviations' do
      %w[tbsp tbsps tbs tblsp].each do |abbr|
        expect(UtilityService.normalize_unit_name(abbr)).to eq('tablespoon')
      end
    end

    it 'normalizes various teaspoon abbreviations' do
      %w[tsp tsps].each do |abbr|
        expect(UtilityService.normalize_unit_name(abbr)).to eq('teaspoon')
      end
    end

    it 'normalizes various unit abbreviations' do
      expect(UtilityService.normalize_unit_name('c')).to eq('cup')
      expect(UtilityService.normalize_unit_name('oz')).to eq('ounce')
      expect(UtilityService.normalize_unit_name('lbs')).to eq('pound')
      expect(UtilityService.normalize_unit_name('g')).to eq('gram')
      expect(UtilityService.normalize_unit_name('kg')).to eq('kilogram')
      expect(UtilityService.normalize_unit_name('ml')).to eq('milliliter')
      expect(UtilityService.normalize_unit_name('l')).to eq('liter')
      expect(UtilityService.normalize_unit_name('pt')).to eq('pint')
      expect(UtilityService.normalize_unit_name('qt')).to eq('quart')
      expect(UtilityService.normalize_unit_name('gal')).to eq('gallon')
    end

    it 'returns stripped original name for unknown units' do
      expect(UtilityService.normalize_unit_name('  unknown  ')).to eq('unknown')
    end
  end

  describe '.determine_unit_category' do
    it 'identifies volume units' do
      volume_units = [ 'cup', 'tablespoon', 'teaspoon', 'Fluid Ounce', 'pint', 'quart', 'gallon', 'liter', 'milliliter' ]
      volume_units.each do |unit|
        expect(UtilityService.determine_unit_category(unit)).to eq('volume')
      end
    end

    it 'identifies weight units' do
      weight_units = [ 'pound', 'ounce', 'gram', 'kilogram' ]
      weight_units.each do |unit|
        expect(UtilityService.determine_unit_category(unit)).to eq('weight')
      end
    end

    it 'identifies length units' do
      length_units = [ 'inch', 'centimeter', 'millimeter', 'meter' ]
      length_units.each do |unit|
        expect(UtilityService.determine_unit_category(unit)).to eq('length')
      end
    end

    it 'returns other for unrecognized units' do
      expect(UtilityService.determine_unit_category('something')).to eq('other')
    end
  end

  describe '.handle_errors' do
    let(:logger) { double('Logger') }

    before do
      allow(Rails.logger).to receive(:error).and_return(true)
    end

    it 'returns the result if successful' do
      result = { success: true, data: 'Some data' }
      expect(UtilityService.handle_errors(result)).to eq(result)
    end

    it 'logs errors for unsuccessful results' do
      result = {
        success: false,
        errors: [ 'Error 1', 'Error 2' ]
      }

      expect(Rails.logger).to receive(:error).with('Error: Error 1, Error 2')

      returned_result = UtilityService.handle_errors(result)
      expect(returned_result).to eq(result)
    end

    it 'handles single error string' do
      result = {
        success: false,
        errors: 'Single error'
      }

      expect(Rails.logger).to receive(:error).with('Error: Single error')

      returned_result = UtilityService.handle_errors(result)
      expect(returned_result).to eq(result)
    end
  end

  describe '.safe_get' do
    let(:test_hash) { { 'key1' => 'value1', :key2 => 'value2' } }

    it 'retrieves value by string key' do
      expect(UtilityService.safe_get(test_hash, 'key1')).to eq('value1')
    end

    it 'retrieves value by symbol key' do
      expect(UtilityService.safe_get(test_hash, :key2)).to eq('value2')
    end

    it 'returns default value for non-existent key' do
      expect(UtilityService.safe_get(test_hash, 'missing_key', 'default')).to eq('default')
    end

    it 'handles nil input gracefully' do
      expect(UtilityService.safe_get(nil, 'key')).to be_nil
    end
  end

  describe '.with_transaction' do
    it 'yields block and returns success' do
      result = UtilityService.with_transaction do
        { success: true, data: 'Transaction completed' }
      end

      expect(result).to include(success: true)
      expect(result[:data]).to eq('Transaction completed')
    end

    it 'handles exceptions during transaction' do
      expect(Rails.logger).to receive(:error).with(/Transaction error/)

      result = UtilityService.with_transaction do
        raise StandardError, 'Test error'
      end

      expect(result).to include(
                          success: false,
                          errors: kind_of(Array),
                          exception: kind_of(StandardError)
                        )
    end
  end

  describe '.api_response' do
    context 'when successful' do
      it 'creates a response with data and optional message' do
        response, status = UtilityService.api_response(true, { user: 'test' }, 'Success')

        expect(response).to eq({
                                 success: true,
                                 data: { user: 'test' },
                                 message: 'Success'
                               })
        expect(status).to eq(:ok)
      end

      it 'creates a response without optional parameters' do
        response, status = UtilityService.api_response(true)

        expect(response).to eq({
                                 success: true
                               })
        expect(status).to eq(:ok)
      end
    end

    context 'when unsuccessful' do
      it 'creates a response with errors' do
        response, status = UtilityService.api_response(false, { errors: [ 'Error 1' ] }, 'Error')

        expect(response).to eq({
                                 success: false,
                                 errors: [ 'Error 1' ]
                               })
        expect(status).to eq(:ok)
      end

      it 'creates a response with default error message' do
        response, status = UtilityService.api_response(false)

        expect(response).to eq({
                                 success: false,
                                 errors: [ 'An error occurred' ]
                               })
        expect(status).to eq(:ok)
      end
    end
  end
end
