# frozen_string_literal: true

class PagesController < ApplicationController
  def show
    @page = Page.new(params[:id])

    redirect_to root_path if !@page.with_rubrics? && @page.photos.empty?
  end
end
