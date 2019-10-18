# frozen_string_literal: true

class PagesController < ApplicationController
  def show
    id = params[:id]

    @page = Page.new(id)

    redirect_to root_path if id.present? && @page.rubrics.empty? && @page.photos.empty?
  end
end
