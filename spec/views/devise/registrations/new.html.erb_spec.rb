require 'rails_helper'

RSpec.describe "devise/registrations/new", type: :view do
  before(:each) do
    without_partial_double_verification do
      allow(view).to receive(:resource).and_return(User.new)
      allow(view).to receive(:resource_name).and_return(:user)
      allow(view).to receive(:devise_mapping).and_return(Devise.mappings[:user])
    end
  end

  it "renders the sign up form" do
    render
    expect(rendered).to have_selector("form[action='#{user_registration_path}']")
    expect(rendered).to have_field("user[email]")
    expect(rendered).to have_field("user[password]")
    expect(rendered).to have_field("user[password_confirmation]")
    expect(rendered).to have_button("Sign Up")
  end
end
