class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :load_sidebar_data

  private

  def load_sidebar_data
    @sidebar_projects = Project.order(:name).includes(:prompts)
    @sidebar_standalone_prompts = Prompt.standalone.recent.limit(20)
    @sidebar_total_standalone_count = Prompt.standalone.count
    @sidebar_total_prompts_count = Prompt.count
  end
end
