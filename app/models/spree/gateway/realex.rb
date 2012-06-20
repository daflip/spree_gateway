module Spree
  class Gateway::Realex < Gateway

    preference :login, :string
    preference :password, :string
    preference :account, :string, :default => "internet"

    attr_accessible :preferred_login, :preferred_password, :preferred_account
    
    def provider_class
      ActiveMerchant::Billing::RealexGateway
    end

    def options
      #if self.preferred_test_mode
      #self.class.preference :test, :boolean, :default => true
      #else
      #self.class.remove_preference :test
      #end
      super
    end

    def authorize(money, creditcard, options = {})
      result = super(money,creditcard,make_order_id_unique(options))
      unless result.success?
        logger.error "Failed to authorize order #{options[:order_id]} #{result.inspect}" 
        #raise "Failed to authorize order #{options[:order_id]} #{result.inspect}" 
      end
      result
    end

    def purchase(money, creditcard, options = {})
      result = super(money,creditcard,make_order_id_unique(options))
      unless result.success?
        logger.error "Failed to purchase order #{options[:order_id]} #{result.inspect}" 
      end
      result
    end

    def make_order_id_unique(options)
      options[:order_id] << "-#{Time.now.to_i}"
      options
    end

  end
end
