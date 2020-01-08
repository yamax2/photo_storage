# frozen_string_literal: true

class PagesController < ApplicationController
  def show
    @page = Page.new(params[:id])
    @photos = @page.photos

    redirect_to root_path if !@page.with_rubrics? && @photos.empty?
  end
end
