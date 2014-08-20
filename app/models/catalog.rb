# encoding: utf-8
class Catalog < ActiveRecord::Base

  belongs_to :parent, :class_name => "Catalog", :foreign_key => "parent_id"
  has_many :children, :order => 'title ASC', :class_name => "Catalog", :foreign_key => "parent_id", dependent: :destroy
  has_many :product, :order => 'title ASC'

  has_attached_file :image, styles: {:medium => "300x300#", :thumb => "150x150>", :thumbnail => "50x50>"}

  validates :title, :description, presence: true #поля заполнены

  validates_attachment_content_type :image, :content_type => ["image/jpg", "image/jpeg", "image/png", "image/gif"]

  #def imageurl
  #  self.image.url != '' ? self.image.url(:thumb) : 'no-image.png'
  #end


end