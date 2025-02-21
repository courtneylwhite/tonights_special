class Users::RegistrationsController < Devise::RegistrationsController
  # Optional: Add custom logic for sign up
  def create
    super do |resource|
      if resource.persisted?
        response.headers['Turbo-Visit-Control'] = 'reload'
      end
    end
  end

  # Optional: Customize permitted parameters
  protected

  def sign_up_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
