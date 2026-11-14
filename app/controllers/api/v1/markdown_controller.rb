module Api
  module V1
    class MarkdownController < BaseController
      def render_text
        text = params[:text].to_s
        html = MarkdownRenderer.render(text)
        render json: { html: html }
      end
    end
  end
end
