class Users::SessionsController < Devise::SessionsController
  skip_before_action :verify_authenticity_token, only: :create
  # app/controllers/users/sessions_controller.rb
  class Users::SessionsController < Devise::SessionsController
    def create
      self.resource = warden.authenticate!(auth_options)
      if resource
        sign_in(resource_name, resource)
        response.headers["Turbo-Visit-Control"] = "reload"
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource)
      end
    rescue Warden::NotAuthenticated
      flash[:alert] = "Invalid email or password."
      self.resource = resource_class.new(sign_in_params)
      render :new, status: :unprocessable_entity
    end
  end
end
