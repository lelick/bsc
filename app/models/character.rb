class Character < ActiveRecord::Base

  belongs_to :product, :class_name => "Product", :foreign_key => "product_id"

end
