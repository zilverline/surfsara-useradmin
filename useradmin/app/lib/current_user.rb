CurrentUser = Struct.new(:request) do
  def uid
    request.get_header('Shib-uid')
  end

  def common_name
    request.get_header('Shib-commonName')
  end

  def home_organization
    request.get_header('Shib-homeOrganization')
  end

  def edu_person_principal_name
    request.get_header('Shib-eduPersonPrincipalName')
  end

  def edu_person_entitlement
    request.get_header('Shib-eduPersonEntitlement')
  end

  def shibboleth_headers
    Hash[request.headers.select { |k, _| k.starts_with?('Shib-') }]
  end

  def one_username
    "#{uid}@#{home_organization}"
  end

  def one_password
    edu_person_principal_name
  end

  def one_user
    @one_user ||= one_client.user_by_password(one_password)
  end

  def admin_groups
    @admin_groups ||= get_admin_groups
  end

  def role
    return Role.surfsara_admin if surfsara_admin?
    return Role.group_admin if group_admin?
  end

  def surfsara_admin?
    (edu_person_entitlement || '').split(',').include?(Rails.application.config.surfsara_admin_entitlement)
  end

  def group_admin?
    return false if surfsara_admin?
    admin_groups.any?
  end

  def can_administer_groups?
    admin_groups.any?
  end

  private

  def get_admin_groups
    return one_client.groups if surfsara_admin?
    return [] unless one_user
    one_client.groups_for_admin(one_user.id)
  end

  def one_client
    @one_client ||= One::Client.new
  end
end
