module Api
  module V1
    class PromptAttachmentsController < BaseController
      before_action :set_prompt

      def index
        render json: {
          attachments: @prompt.files.map { |file| attachment_json(file) }
        }
      end

      def create
        if params[:files].blank?
          return render_error("No files provided for attachment", status: :bad_request)
        end

        @prompt.files.attach(params[:files])

        render json: {
          status: "ok",
          attachments: @prompt.files.map { |file| attachment_json(file) }
        }, status: :created
      end

      def destroy
        attachment = @prompt.files.find(params[:attachment_id])
        attachment.purge

        render json: {
          status: "ok",
          message: "Attachment removed successfully"
        }
      end

      private

      def set_prompt
        @prompt = Prompt.find(params[:id])
      end
    end
  end
end
