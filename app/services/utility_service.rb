module UtilityService
  def self.normalize_text(text)
    text.to_s.strip.downcase
  end

  def self.format_quantity(quantity)
    return quantity unless quantity.is_a?(Numeric)

    quantity = (quantity * 100).round / 100.0
    quantity.to_i == quantity ? quantity.to_i : quantity
  end

  def self.normalize_unit_name(unit_name)
    clean_name = unit_name.to_s.downcase.gsub(/\.$/, "")

    case clean_name
    when "tbsp", "tbsps", "tbs", "tblsp"
      "tablespoon"
    when "tsp", "tsps"
      "teaspoon"
    when "c"
      "cup"
    when "oz", "ozs"
      "ounce"
    when "lb", "lbs"
      "pound"
    when "g"
      "gram"
    when "kg"
      "kilogram"
    when "ml"
      "milliliter"
    when "l"
      "liter"
    when "pt"
      "pint"
    when "qt"
      "quart"
    when "gal"
      "gallon"
    else
      unit_name.strip
    end
  end

  def self.determine_unit_category(unit_name)
    volume_units = [ "cup", "tablespoon", "teaspoon", "pint", "quart", "gallon", "liter", "milliliter", "fluid" ]
    weight_units = [ "pound", "ounce", "gram", "kilogram" ]
    length_units = [ "inch", "centimeter", "millimeter", "meter" ]

    unit_downcase = unit_name.to_s.downcase

    if volume_units.any? { |u| unit_downcase.include?(u) }
      "volume"
    elsif weight_units.any? { |u| unit_downcase.include?(u) }
      "weight"
    elsif length_units.any? { |u| unit_downcase.include?(u) }
      "length"
    else
      "other"
    end
  end

  def self.handle_errors(result, error_type = "Error")
    if result[:success]
      result
    else
      errors = result[:errors].is_a?(Array) ? result[:errors].join(", ") : result[:errors].to_s
      Rails.logger.error("#{error_type}: #{errors}")
      result
    end
  end

  def self.safe_get(hash, key, default = nil)
    return default unless hash.respond_to?(:[])

    value = hash[key.to_s] || hash[key.to_sym]
    value.presence || default
  end

  def self.with_transaction
    success = false
    result = nil

    ActiveRecord::Base.transaction do
      begin
        result = yield if block_given?
        success = true if result && (result[:success].nil? || result[:success])
      rescue StandardError => e
        Rails.logger.error("Transaction error: #{e.message}")
        result = {
          success: false,
          errors: [ e.message ],
          exception: e
        }
        raise ActiveRecord::Rollback
      end
    end

    result || { success: success }
  end

  def self.api_response(success, data = {}, message = nil, status = :ok)
    response = { success: success }

    if success
      response[:data] = data if data.present?
      response[:message] = message if message.present?
    else
      response[:errors] = data.is_a?(Hash) && data[:errors] ? data[:errors] : [ message || "An error occurred" ]
    end

    [ response, status ]
  end
end
