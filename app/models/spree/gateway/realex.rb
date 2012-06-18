module Spree
  class Gateway::Realex < Gateway

    preference :login, :string
    preference :password, :string
    preference :account, :string, :default => "internet"

    attr_accessible :preferred_login, :preferred_password
    
    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end

    def options
      # add :test key in the options hash, as that is what the ActiveMerchant::Billing::AuthorizeNetGateway expects
      if self.preferred_test_mode
        self.class.preference :test, :boolean, :default => true
      else
        self.class.remove_preference :test
      end
      result = super
      if result[:order_id].to_s.match(/^[A-Z][0-9]+$/)
        result[:order_id] << "-#{Time.now.to_i}"
      end
      result
    end

  end
end
