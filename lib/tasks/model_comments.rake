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

      # Generate schema comments
      schema_comments = generate_schema_comments(model)

      # Read existing file content
      file_content = File.read(model_file)

      # Prepend comments to the file
      updated_content = "# == Schema Information\n#{schema_comments}\n#{file_content}"

      # Write back to the file
      File.write(model_file, updated_content)
    end
  end

  def generate_schema_comments(model)
    columns = model.columns

    comments = columns.map do |column|
      nullable = column.null ? 'nullable' : 'not null'
      default = column.default ? "default: #{column.default}" : ''

      "# #{column.name} :#{column.type}, #{nullable} #{default}"
    end.join("\n")

    comments
  end
end