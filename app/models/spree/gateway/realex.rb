module Spree
  class Gateway::Realex < Gateway

    preference :login, :string
    preference :password, :string
    preference :account, :string, :default => "internet"

    attr_accessible :preferred_login, :preferred_password
    
    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end

  end
end
