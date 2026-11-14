module Api
  module V1
    class BaseController < ActionController::API
      include Rails.application.routes.url_helpers

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActionController::ParameterMissing, with: :parameter_missing
      rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

      protected

      def render_error(message, status: :bad_request, details: [])
        render json: {
          error: message,
          details: Array(details)
        }, status: status
      end

      def record_not_found(exception)
        render_error("Resource not found", status: :not_found, details: [ exception.message ])
      end

      def parameter_missing(exception)
        render_error("Parameter missing", status: :bad_request, details: [ exception.message ])
      end

      def record_invalid(exception)
        render_error("Validation failed", status: :unprocessable_entity, details: exception.record.errors.full_messages)
      end

      def paginate_scope(scope, default_limit: 50, max_limit: 100)
        limit = (params[:limit].presence || default_limit).to_i
        limit = max_limit if limit > max_limit || limit <= 0
        offset = [ params[:offset].to_i, 0 ].max

        [ scope.offset(offset).limit(limit), { limit: limit, offset: offset, total_count: scope.count } ]
      end

      def project_json(project, include_prompts: false)
        data = {
          id: project.id,
          name: project.name,
          description: project.description,
          prompts_count: project.prompts.count,
          created_at: project.created_at&.iso8601,
          updated_at: project.updated_at&.iso8601
        }

        if include_prompts
          data[:prompts] = project.prompts.recent.map do |p|
            {
              id: p.id,
              title: p.title,
              pinned: p.pinned?,
              pinned_position: p.pinned_position,
              updated_at: p.updated_at&.iso8601
            }
          end
        end

        data
      end

      def prompt_json(prompt, include_body: true, render_markdown: false, include_attachments: false)
        data = {
          id: prompt.id,
          project_id: prompt.project_id,
          project_name: prompt.project&.name,
          title: prompt.title,
          pinned: prompt.pinned?,
          pinned_position: prompt.pinned_position,
          attachments_count: prompt.files.count,
          created_at: prompt.created_at&.iso8601,
          updated_at: prompt.updated_at&.iso8601
        }

        data[:body] = prompt.body if include_body

        if render_markdown
          data[:rendered_html] = MarkdownRenderer.render(prompt.body)
        end

        if include_attachments
          data[:attachments] = prompt.files.map { |file| attachment_json(file) }
        end

        data
      end

      def attachment_json(attachment)
        url = begin
          rails_blob_url(attachment, only_path: false)
        rescue StandardError
          "/rails/active_storage/blobs/redirect/#{attachment.signed_id}/#{ERB::Util.url_encode(attachment.filename.to_s)}"
        end

        {
          id: attachment.id,
          filename: attachment.filename.to_s,
          content_type: attachment.content_type,
          byte_size: attachment.byte_size,
          created_at: attachment.created_at&.iso8601,
          url: url
        }
      end
    end
  end
end
