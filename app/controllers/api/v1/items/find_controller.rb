class Api::V1::Items::FindController < ApplicationController
  before_action :find_item
  def index
    if !@item.nil?
      render json: ItemSerializer.new(@item)
    else
      render json: ErrorSerializer.no_data, status: :bad_request
    end
  end

  private

  def item_params
    params.permit(:name, :min_price, :max_price)
  end

  def find_item
    if !params.include?(:name) && !params.include?(:min_price) && !params.include?(:max_price)
      render json: ErrorSerializer.bad_data, status: :bad_request
    else
      @item = (name_items.order(:name) & min_price_items.order(:name) & max_price_items.order(:name)).first
    end
  end

  def name_items
    # this is stupid and limits the functionality. why not be able to add as much search criteria as you want?
    if item_params.include?(:name)
      if item_params.include?(:min_price) || item_params.include?(:max_price)
        render json: ErrorSerializer.bad_data, status: :bad_request
      elsif params[:name].empty?
        render json: ErrorSerializer.bad_data, status: :bad_request
      end
    end

    if !item_params[:name].nil? && !item_params[:name].empty?
      Item.where('name ILIKE (?)', "%#{item_params[:name]}%")
    else
      Item.all
    end
  end

  def min_price_items
    if !item_params[:min_price].nil? && !item_params[:min_price].empty?
      render json: ErrorSerializer.bad_data, status: :bad_request if params[:min_price].to_i <= 0
      Item.where('unit_price >= (?)', item_params[:min_price])
    else
      Item.all
    end
  end

  def max_price_items
    if !item_params[:max_price].nil? && !item_params[:max_price].empty?
      if params[:max_price].to_i <= 0 || params[:max_price].to_i < Item.order(:unit_price).last.unit_price
        render json: ErrorSerializer.bad_data,
               status: :bad_request
      end
      Item.where('unit_price <= (?)', item_params[:max_price])
    else
      Item.all
    end
  end
end