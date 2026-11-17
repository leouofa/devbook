# frozen_string_literal: true

class PromptVersionsController < ApplicationController
  before_action :set_prompt
  before_action :load_versions, only: %i[index show]

  def index
    @selected_version = if params[:version_id].present?
      @versions.find(params[:version_id])
    else
      @versions.first
    end

    prepare_comparison
  end

  def show
    @selected_version = @versions.find(params[:id])
    prepare_comparison
    render :index
  end

  def restore
    @version = @prompt.versions.find(params[:id])
    @prompt.restore_version!(@version)

    redirect_to prompt_path(@prompt),
                notice: "Restored prompt to v#{@version.version_number} (saved as v#{@prompt.current_version_number})."
  end

  private

  def set_prompt
    @prompt = Prompt.find(params[:prompt_id])
  end

  def load_versions
    @prompt.record_version_snapshot! if @prompt.versions.empty?
    @versions = @prompt.versions.ordered
  end

  def prepare_comparison
    return unless @selected_version

    @view_mode = params[:view].presence_in(%w[diff rendered raw]) || "diff"

    @previous_version = if params[:compare_id].present?
      @versions.find_by(id: params[:compare_id])
    else
      @prompt.versions
             .where("version_number < ?", @selected_version.version_number)
             .order(version_number: :desc)
             .first
    end

    @diff = PromptDiffer.call(
      @previous_version&.body.to_s,
      @selected_version.body,
      old_title: @previous_version&.title,
      new_title: @selected_version.title
    )
  end
end
