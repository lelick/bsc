class ProductsController < ApplicationController
  include CurrentCart
  include CurrentCompare
  before_action :set_cart
  before_action :set_compare

  before_action :set_product, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource except: :create
  skip_authorize_resource :only => [:show, :search]

  # before_filter :load_attachable

  # GET /products
  # GET /products.json
  def index
    @products = Product.where('id NOT IN (SELECT DISTINCT(product_id) FROM details) AND price > 1500 AND supplier_id <> 2').order(:updated_at).paginate(:page => params[:page], :per_page => 30)
  end

  # GET /products/1
  # GET /products/1.json
  def show
    @tree = []
    self.breadcrumb(@product.catalog)
    @subcatalogs = []

    while @tree.size > 0
      catalog_item = @tree.pop
      @subcatalogs.push(catalog_item)
      add_breadcrumb catalog_item.title, catalog_item
    end

    @line_item = LineItem.new
    @compare_item = CompareItem.new
  end

  # GET /products/new
  def new
    @product = Product.new

    report = Report.new
    report.user = current_user
    report.product = @product
    report.type_action = Report.create_open
    report.save

  end

  # GET /products/1/edit
  def edit
    #@product = @attachable.Product.find(params[:id])

    report = Report.new
    report.user = current_user
    report.product = @product
    report.type_action = Report.edit_open
    report.save

    @characters = @product.characters
  end

  # POST /products
  # POST /products.json
  def create
    @product = Product.new(product_params)

    respond_to do |format|
      if @product.save

        report = Report.new
        report.user = current_user
        report.product = @product
        report.type_action = Report.create_save
        report.save

        format.html { redirect_to edit_product_path @product, scrollto: 'imgs' }
        format.json { render action: 'show', status: :created, location: @product }
      else
        format.html { render action: 'new' }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /products/1
  # PATCH/PUT /products/1.json
  def update
    characters_params = params[:product][:characters]
    if !characters_params.nil?
      characters_params.each do |key, characters_param|
        if characters_param.is_a?(Hash)
          if characters_param[:name].to_s.size > 0 and characters_param[:value].to_s.size > 0
            if key.include? 'new'
              i = 0
              characters_param[:name].each do |key|
                character = Character.new
                character.name = characters_param[:name][i]
                character.value = characters_param[:value][i]
                character.product_id = @product.id
                if character.name.to_s.size > 0 and character.value.to_s.size > 0
                  character.save
                end
                i = i + 1
              end
            elsif key.to_i > 0
              character = Character.find(key.to_i)
              character.name = characters_param[:name]
              character.value = characters_param[:value]
              character.product_id = @product.id
              character.save
            end
          end
          if characters_param[:_destroy].to_i == 1
            character = Character.find(key.to_i)
            character.destroy
          end
        end
      end
    end

    brand_id = params[:product][:brand_id].to_i
    brand_name = params[:product][:brand]
    if brand_id == 0 and brand_name != ""
      brand = Brand.where("lower(title) = ?", brand_name.downcase).first
      if brand.nil?
        brand = Brand.new
        brand.title = brand_name
        brand.save
      end
    else
      brand = Brand.find(brand_id)
      if brand.title != brand_name and brand_name != ""
        brand = Brand.where("lower(title) = ?", brand_name.downcase).first
        if brand.nil?
          brand = Brand.new
          brand.title = brand_name
          brand.save
        end
      end
    end
    params[:product][:brand_id] = brand.id
    respond_to do |format|
      if @product.update(product_params)

        report = Report.new
        report.user = current_user
        report.product = @product
        report.type_action = Report.edit_save
        report.save

        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /products/1
  # DELETE /products/1.json
  def destroy
    # @product = @attachable.assets.find(params[:id])

    report = Report.new
    report.user = current_user
    report.product = @product
    report.type_action = Report.delete
    report.save

    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_url }
      format.json { head :no_content }
    end
  end

  def who_bought
    @product = Product.find(params[:id])
    @latest_order = @product.orders.order(:updated_at).last
    if stale?(@latest_order)
      respond_to do |format|
        format.atom
      end
    end
  end

  def breadcrumb (catalog_item)
    if catalog_item != nil
      #add_breadcrumb catalog_item.title, catalog_item
      @tree.push(catalog_item)
      self.breadcrumb(catalog_item.parent)
    end
  end

  def change_ajax
    @product = Product.find(params[:id])
    product_params = Hash[params[:field] => params[:value]]
    respond_to do |format|
      if @product.update(product_params)
        format.html { redirect_to @product, notice: 'Product was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @product.errors, status: :unprocessable_entity }
      end
    end
  end

  def search
    @query = params[:query].split(/'([^']+)'|"([^"]+)"|\s+|\+/).reject{|x| x.empty?}.map{|x| x.inspect }*' && '
    @products = ThinkingSphinx.search @query, :classes => [Product], :conditions => {:is_active => 1}, :limit => 5
    @total_found = @products .total_entries
    @line_item = LineItem.new
    @compare_item = CompareItem.new
    @query = params[:query]
    #@artists.run
    respond_to do |format|
      format.js #search.js.erb
    end
  end

  # def load_attachable
  #   resource, id = request.path.split('/')[1, 2]
  #   @attachable  = resource.singularize.classify.constantize.find(id)
  # end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = Product.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def product_params
      params.require(:product).permit(:title, :article, :description, :image_url, :price, :catalog_id, :is_active, :image, :_destroy, :value, :imgs, :characters, :brand_id, :content, :reports)
    end
end