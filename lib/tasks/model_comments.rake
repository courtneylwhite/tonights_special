namespace :model_comments do
  desc "Add schema comments to model files"
  task add: :environment do
    # Eager load all models to ensure they're available
    Rails.application.eager_load!

    # Find models that inherit from ApplicationRecord
    models = ActiveRecord::Base.descendants.select { |model| model < ApplicationRecord }

    models.each do |model|
      next unless model.table_exists?

      model_file = Rails.root.join("app/models/#{model.name.underscore}.rb")
      next unless File.exist?(model_file)

      # Read existing file content
      file_content = File.read(model_file)

      # Remove any existing schema comments
      clean_content = remove_existing_comments(file_content)

      # Generate new schema comments
      schema_comments = generate_schema_comments(model)

      # Prepend new comments to the cleaned file
      updated_content = "# == Schema Information\n#{schema_comments}\n#{clean_content}"

      # Write back to the file
      File.write(model_file, updated_content)

      puts "Updated schema comments for #{model.name}"
    end

    puts "Schema comments update complete!"
  end

  def remove_existing_comments(content)
    # Look for schema information block
    if content.include?("# == Schema Information")
      # Find the end of the schema block (either the first line that doesn't start with # or an empty line)
      lines = content.split("\n")

      start_index = lines.find_index { |line| line.strip == "# == Schema Information" }
      return content unless start_index

      # Find the first line after comments
      end_index = start_index + 1
      while end_index < lines.size && (lines[end_index].start_with?("#") || lines[end_index].strip.empty?)
        end_index += 1
      end

      # Return everything after the schema comment block
      lines[end_index..-1].join("\n")
    else
      # No existing schema comments found
      content
    end
  end

  def generate_schema_comments(model)
    columns = model.columns

    comments = columns.map do |column|
      nullable = column.null ? "nullable" : "not null"
      default = column.default ? "default: #{column.default}" : ""

      "# #{column.name} :#{column.type}, #{nullable} #{default}".strip
    end.join("\n")

    comments
  end
end