require 'rails_helper'

RSpec.describe "UnitConversions", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/unit_conversions/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/unit_conversions/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /update" do
    it "returns http success" do
      get "/unit_conversions/update"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/unit_conversions/destroy"
      expect(response).to have_http_status(:success)
    end
  end
end
