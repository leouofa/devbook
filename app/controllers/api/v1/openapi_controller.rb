module Api
  module V1
    class OpenapiController < BaseController
      def show
        schema_path = Rails.root.join("config", "openapi.json")
        if File.exist?(schema_path)
          render file: schema_path, content_type: "application/json"
        else
          render_error("OpenAPI specification file not found", status: :not_found)
        end
      end
    end
  end
end
