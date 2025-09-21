class ChangeDefaultValueToCartItem < ActiveRecord::Migration[7.1]
  def change
    change_column :cart_items, :quantity, :integer, default: 0
  end

  def down
    change_column :cart_items, :quantity, :integer, default: nil
  end
end
