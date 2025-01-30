module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: :google_oauth2

    def google_oauth2
      @user = User.from_omniauth(request.env["omniauth.auth"])
      @user.persisted? ? persisted_user : unpersisted_user
    end

    private

    def persisted_user
      sign_in_and_redirect @user, event: :authentication
    end

    def unpersisted_user
      session["devise.google_data"] = request.env["omniauth.auth"].except("extra")
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end
end
