# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_03_23_162232) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "action_mailbox_inbound_emails", force: :cascade do |t|
    t.integer "status", default: 0, null: false
    t.string "message_id", null: false
    t.string "message_checksum", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "groceries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "grocery_section_id", null: false
    t.string "name", null: false
    t.decimal "quantity", null: false
    t.bigint "unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "emoji"
    t.index ["grocery_section_id"], name: "index_groceries_on_grocery_section_id"
    t.index ["unit_id"], name: "index_groceries_on_unit_id"
    t.index ["user_id", "grocery_section_id"], name: "index_groceries_on_user_id_and_grocery_section_id"
    t.index ["user_id", "name"], name: "index_groceries_on_user_id_and_name"
    t.index ["user_id"], name: "index_groceries_on_user_id"
  end

  create_table "grocery_list_items", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "grocery_id"
    t.decimal "quantity"
    t.bigint "unit_id", null: false
    t.text "notes"
    t.boolean "purchased"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "store_section_id"
    t.index ["grocery_id"], name: "index_grocery_list_items_on_grocery_id"
    t.index ["store_section_id"], name: "index_grocery_list_items_on_store_section_id"
    t.index ["unit_id"], name: "index_grocery_list_items_on_unit_id"
    t.index ["user_id", "grocery_id"], name: "index_grocery_list_items_on_user_id_and_grocery_id"
    t.index ["user_id", "purchased"], name: "index_grocery_list_items_on_user_id_and_purchased"
    t.index ["user_id", "store_section_id"], name: "index_grocery_list_items_on_user_id_and_store_section_id"
    t.index ["user_id"], name: "index_grocery_list_items_on_user_id"
  end

  create_table "grocery_sections", force: :cascade do |t|
    t.string "name"
    t.integer "display_order", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["display_order"], name: "index_grocery_sections_on_display_order"
    t.index ["user_id", "display_order"], name: "index_grocery_sections_on_user_id_and_display_order", unique: true
    t.index ["user_id"], name: "index_grocery_sections_on_user_id"
  end

  create_table "recipe_categories", force: :cascade do |t|
    t.string "name", null: false
    t.integer "display_order"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id", "display_order"], name: "index_recipe_categories_on_user_id_and_display_order", unique: true
    t.index ["user_id", "name"], name: "index_recipe_categories_on_user_id_and_name", unique: true
    t.index ["user_id"], name: "index_recipe_categories_on_user_id"
  end

  create_table "recipe_ingredients", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "grocery_id"
    t.decimal "quantity", null: false
    t.bigint "unit_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name", null: false
    t.string "preparation"
    t.string "size"
    t.index ["grocery_id"], name: "index_recipe_ingredients_on_grocery_id"
    t.index ["recipe_id"], name: "index_recipe_ingredients_on_recipe_id"
    t.index ["unit_id"], name: "index_recipe_ingredients_on_unit_id"
  end

  create_table "recipes", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.text "instructions", null: false
    t.boolean "completed"
    t.datetime "completed_at"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recipe_category_id", null: false
    t.string "prep_time"
    t.string "cook_time"
    t.float "servings"
    t.index ["name"], name: "index_recipes_on_name", unique: true
    t.index ["recipe_category_id"], name: "index_recipes_on_recipe_category_id"
    t.index ["user_id", "completed"], name: "index_recipes_on_user_id_and_completed"
    t.index ["user_id", "name"], name: "index_recipes_on_user_id_and_name"
    t.index ["user_id"], name: "index_recipes_on_user_id"
  end

  create_table "store_sections", force: :cascade do |t|
    t.string "name"
    t.integer "display_order"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "display_order"], name: "index_store_sections_on_user_id_and_display_order", unique: true
    t.index ["user_id"], name: "index_store_sections_on_user_id"
  end

  create_table "unit_conversions", force: :cascade do |t|
    t.bigint "from_unit_id", null: false
    t.bigint "to_unit_id", null: false
    t.decimal "conversion_factor", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["from_unit_id", "to_unit_id"], name: "index_unit_conversions_on_from_unit_id_and_to_unit_id", unique: true
    t.index ["from_unit_id"], name: "index_unit_conversions_on_from_unit_id"
    t.index ["to_unit_id"], name: "index_unit_conversions_on_to_unit_id"
  end

  create_table "units", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.string "abbreviation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["category", "name"], name: "index_units_on_category_and_name"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "groceries", "grocery_sections"
  add_foreign_key "groceries", "units"
  add_foreign_key "groceries", "users"
  add_foreign_key "grocery_list_items", "groceries"
  add_foreign_key "grocery_list_items", "store_sections"
  add_foreign_key "grocery_list_items", "units"
  add_foreign_key "grocery_list_items", "users"
  add_foreign_key "grocery_sections", "users"
  add_foreign_key "recipe_categories", "users"
  add_foreign_key "recipe_ingredients", "groceries"
  add_foreign_key "recipe_ingredients", "recipes"
  add_foreign_key "recipe_ingredients", "units"
  add_foreign_key "recipes", "recipe_categories"
  add_foreign_key "recipes", "users"
  add_foreign_key "store_sections", "users"
  add_foreign_key "unit_conversions", "units", column: "from_unit_id"
  add_foreign_key "unit_conversions", "units", column: "to_unit_id"
end
