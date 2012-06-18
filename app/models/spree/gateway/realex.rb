module Spree
  class Gateway::Realex < Gateway

    preference :login, :string
    preference :password, :string
    preference :account, :string, :default => "internet"
    
    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end

  end
end
