module Api
  module V1
    class StatsController < BaseController
      def show
        render json: {
          total_prompts: Prompt.count,
          standalone_prompts: Prompt.standalone.count,
          pinned_prompts: Prompt.where(pinned: true).count,
          total_projects: Project.count,
          total_attachments: ActiveStorage::Attachment.where(record_type: "Prompt").count
        }
      end
    end
  end
end
