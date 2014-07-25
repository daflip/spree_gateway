class AddStripeCustomerTokenToSpreeUsers < ActiveRecord::Migration
  def up
    add_column :spree_users, :gateway_token, :string
  end
  
end
