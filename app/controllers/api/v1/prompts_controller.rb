module Api
  module V1
    class PromptsController < BaseController
      before_action :set_prompt, only: %i[show update destroy toggle_pin]

      def index
        scope = Prompt.all

        if params[:project_id].present?
          scope = scope.where(project_id: params[:project_id])
        elsif params[:scope] == "standalone"
          scope = scope.standalone
        end

        if params[:pinned].present?
          scope = params[:pinned].to_s == "true" ? scope.where(pinned: true) : scope.where(pinned: false)
        end

        if params[:q].present?
          scope = scope.search(params[:q])
        end

        # Preserve pinned ordering if specifically requested or default recent
        scope = if params[:pinned].to_s == "true"
          scope.pinned
        else
          scope.recent
        end

        paginated_prompts, meta = paginate_scope(scope)
        render json: {
          prompts: paginated_prompts.map { |p| prompt_json(p, include_body: true) },
          meta: meta
        }
      end

      def show
        render_md = params[:render_markdown].to_s == "true" || params[:render_markdown].to_s == "1"
        render json: prompt_json(@prompt, include_body: true, render_markdown: render_md, include_attachments: true)
      end

      def create
        prompt = Prompt.new(prompt_params)

        if prompt.save
          render json: prompt_json(prompt, include_body: true, include_attachments: true), status: :created
        else
          render_error("Validation failed", status: :unprocessable_entity, details: prompt.errors.full_messages)
        end
      end

      def update
        if @prompt.update(prompt_params)
          render_md = params[:render_markdown].to_s == "true" || params[:render_markdown].to_s == "1"
          render json: prompt_json(@prompt, include_body: true, render_markdown: render_md, include_attachments: true)
        else
          render_error("Validation failed", status: :unprocessable_entity, details: @prompt.errors.full_messages)
        end
      end

      def destroy
        @prompt.destroy
        render json: { status: "ok", message: "Prompt deleted successfully" }
      end

      def toggle_pin
        @prompt.toggle_pin!
        render json: {
          status: "ok",
          pinned: @prompt.pinned?,
          pinned_position: @prompt.pinned_position,
          prompt: prompt_json(@prompt)
        }
      end

      def reorder_pinned
        prompt_ids = params[:prompt_ids] || []

        Prompt.transaction do
          prompt_ids.each_with_index do |id, index|
            Prompt.where(id: id, pinned: true).update_all(pinned_position: index + 1)
          end
        end

        render json: { status: "ok", message: "Pinned prompts reordered successfully" }
      end

      private

      def set_prompt
        @prompt = Prompt.find(params[:id])
      end

      def prompt_params
        payload = params[:prompt].is_a?(ActionController::Parameters) ? params[:prompt] : params
        payload.permit(:title, :body, :project_id, :pinned, :pinned_position)
      end
    end
  end
end
