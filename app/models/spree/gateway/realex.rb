module Spree
  class Gateway::Realex < Gateway
    preference :login, :string
    preference :password, :string
    preference :account, :string, :default => "internet"
    
    # Note: EWay supports purchase method only (no authorize method).
    # Ensure Spree::Config[:auto_capture] is set to true

    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end

  end
end
