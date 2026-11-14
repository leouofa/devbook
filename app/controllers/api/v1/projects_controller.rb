module Api
  module V1
    class ProjectsController < BaseController
      before_action :set_project, only: %i[show update destroy]

      def index
        scope = Project.order(:name)
        if params[:q].present?
          query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].to_s.strip)}%"
          scope = scope.where("name ILIKE :q OR description ILIKE :q", q: query)
        end

        paginated_projects, meta = paginate_scope(scope)
        render json: {
          projects: paginated_projects.map { |project| project_json(project) },
          meta: meta
        }
      end

      def show
        render json: project_json(@project, include_prompts: true)
      end

      def create
        project = Project.new(project_params)
        if project.save
          render json: project_json(project), status: :created
        else
          render_error("Validation failed", status: :unprocessable_entity, details: project.errors.full_messages)
        end
      end

      def update
        if @project.update(project_params)
          render json: project_json(@project)
        else
          render_error("Validation failed", status: :unprocessable_entity, details: @project.errors.full_messages)
        end
      end

      def destroy
        @project.destroy
        render json: { status: "ok", message: "Project deleted successfully" }
      end

      private

      def set_project
        @project = Project.find(params[:id])
      end

      def project_params
        payload = params[:project].is_a?(ActionController::Parameters) ? params[:project] : params
        payload.permit(:name, :description)
      end
    end
  end
end
