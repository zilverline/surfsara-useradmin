module One
  class MigrateUser < Operation
    include Model
    include Trailblazer::Operation::Policy

    model Migration, :create
    policy Migration::Policy, :create?

    contract do
      property :username, virtual: true, validates: {presence: true}
      property :password, virtual: true, validates: {presence: true}
      property :accept_terms_of_service, virtual: true

      validate :accept_terms_of_service do
        errors.add(:accept_terms_of_service, :not_accepted) if accept_terms_of_service != '1'
      end
    end

    def process(params)
      validate(params[:migration]) do
        return unless authenticate_user
        return unless check_password_available

        @model.update!(
          accepted_at: Time.current,
          accepted_by: current_user.remote_user,
          accepted_from_ip: current_user.remote_ip,
          one_username: @contract.username
        )
        migrate_user
      end
    end

    private

    def authenticate_user
      if one_user.blank?
        self.errors.add(:base, :could_not_be_authenticated)
        invalid!
        return false
      end
      true
    end

    def one_user
      @one_user ||= find_one_user
    end

    def find_one_user
      user_client.find_user(username)
    rescue RuntimeError => e
      raise unless e.message =~ /User couldn't be authenticated/
    end

    def user_client
      @user_client ||= One::Client.new(credentials: credentials)
    end

    def check_password_available
      if admin_client.user_by_password(current_user.remote_user).present?
        self.errors.add(:base, :account_already_linked)
        invalid!
        return false
      end
      true
    end

    def admin_client
      @admin_client ||= One::Client.new
    end

    def migrate_user
      admin_client.migrate_user(one_user.id, current_user.remote_user)
    end

    def credentials
      "#{username}:#{password}"
    end

    def username
      @params[:migration][:username]
    end

    def password
      @params[:migration][:password]
    end
  end
end
