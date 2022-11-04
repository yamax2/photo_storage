# frozen_string_literal: true

module Admin
  class RubricsController < AdminController
    before_action :find_rubric, only: %i[edit update destroy warm_up]
    helper_method :parent_id, :parent_rubric

    def index
      @search = Rubric.where(rubric: parent_rubric).ransack(params[:q])
      @rubrics = @search.result.page(params[:page])
    end

    def new
      @rubric = Rubric.new(rubric: parent_rubric)
    end

    def edit
    end

    def create
      @rubric = Rubric.new(rubric_params)

      if @rubric.save
        redirect_to admin_rubrics_path(id: @rubric.rubric_id)
      else
        render 'new'
      end
    end

    def update
      if @rubric.update(rubric_params)
        redirect_to admin_rubrics_path(id: @rubric.rubric_id)
      else
        render 'edit'
      end
    end

    def destroy
      @rubric.destroy

      redirect_to admin_rubrics_path(id: @rubric.rubric_id), notice: t('.success', name: @rubric.name)
    end

    def warm_up
      ::Rubrics::WarmUpJob.perform_async(@rubric.id, params.require(:size))

      redirect_to admin_rubrics_path(id: @rubric.rubric_id), notice: t('.success', name: @rubric.name)
    end

    private

    def find_rubric
      @rubric = Rubric.find(params[:id])
    end

    def parent_id
      params[:id]
    end

    def parent_rubric
      @parent_rubric ||= parent_id.present? ? Rubric.find(parent_id) : nil
    end

    def rubric_params
      params.require(:rubric).permit(:rubric_id, :name, :description, :desc_order, :hide_common_stat)
    end
  end
end
