module Spree
  class Gateway::StripeGateway < Gateway
    preference :login, :string

    attr_accessible :preferred_login, :preferred_currency

    def provider_class
      ActiveMerchant::Billing::StripeGateway
    end

    def payment_profiles_supported?
      true
    end

    def purchase(money, creditcard, gateway_options)
      provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def authorize(money, creditcard, gateway_options)
      provider.authorize(*options_for_purchase_or_auth(money, creditcard, gateway_options))
    end

    def capture(payment, creditcard, gateway_options)
      provider.capture((payment.amount * 100).round, payment.response_code, gateway_options)
    end

    def credit(money, creditcard, response_code, gateway_options)
      provider.refund(money, response_code, {})
    end

    def void(response_code, creditcard, gateway_options)
      provider.void(response_code, {})
    end

    def create_profile(payment)
      return unless payment.source.gateway_customer_profile_id.nil?

      customer = payment.order.user

      # using a stored card and there's a stored card on file?
      if payment.source.use_stored_card? and customer.creditcard_on_file?
        update_payment_with_profile_info(payment, customer)
        return 
      end

      options = {
        :email => payment.order.email,
        :login => preferred_login
      }.merge! address_for(payment)

      # if we have a gateway token then assign the customer id
      # and mark the latest card as being the default
      if customer.gateway_token.present?
        options[:customer] = customer.gateway_token
        options[:set_default] = true
      end

      response = provider.store(payment.source, options)
      #raise payment.source.inspect
      if response.success?
        if options[:customer] 
          gateway_token = options[:customer]
          card_token    = response.params['id']
        else
          gateway_token = response.params['id']
          card_token    = response.params['default_card']
        end
        customer_attrs = {
          gateway_token: gateway_token,
          card_token:    card_token,
          card_details:  payment.source.attributes
        }
        customer.update_attributes!(customer_attrs, without_protection: true)
        #end
        update_payment_with_profile_info(payment, customer)
      else
        payment.send(:gateway_error, response.message)
    end
  end

  private

  def update_payment_with_profile_info(payment, customer)
    payment.source.update_attributes!({
        gateway_customer_profile_id: customer.gateway_token,
        gateway_payment_profile_id:  customer.card_token
      })
  end

  def options_for_purchase_or_auth(money, creditcard, gateway_options)
    options = {}
    options[:description] = "Order Number: #{gateway_options[:order_id]}"
    options[:currency] = 'EUR'

    customer = creditcard.payments.last.order.user

    if creditcard.use_stored_card? 
      options[:customer] = customer.gateway_token
      creditcard = customer.card_token
    elsif customer.gateway_token
      options[:customer] = customer.gateway_token
      creditcard = nil
      #raise creditcard.payments.last.order.user.inspect
    elsif customer = creditcard.gateway_customer_profile_id
      options[:customer] = customer
      creditcard = nil
    elsif token = creditcard.gateway_payment_profile_id
      # The Stripe ActiveMerchant gateway supports passing the token directly as the creditcard parameter
      creditcard = token
    end
    return money, creditcard, options
  end

  def address_for(payment)
    {}.tap do |options|
      if address = payment.order.bill_address
        options.merge!(:address => {
            :address1 => address.address1,
            :address2 => address.address2,
            :city => address.city,
            :zip => address.zipcode
          })

        if country = address.country
          options[:address].merge!(:country => country.name)
        end

        if state = address.state
          options[:address].merge!(:state => state.name)
        end
      end
    end
  end
end

end
