class Users::RegistrationsController < Devise::RegistrationsController
  def create
    super do |resource|
      response.headers["Turbo-Visit-Control"] = "reload" if resource.persisted?
    end
  end
end
