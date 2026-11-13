class PromptsController < ApplicationController
  before_action :set_prompt, only: %i[show edit update destroy attach_files purge_attachment]

  def index
    @scope = params[:scope].presence

    base_scope = if params[:q].present?
      @scope == "standalone" ? Prompt.standalone : Prompt.all
    elsif @scope == "all"
      Prompt.all
    else
      @scope = "standalone"
      Prompt.standalone
    end

    @prompts = base_scope.recent
    if params[:q].present?
      @prompts = @prompts.search(params[:q])
    end
  end

  def show
  end

  def new
    @prompt = Prompt.new(project_id: params[:project_id])
  end

  def edit
  end

  def create
    @prompt = Prompt.new(prompt_params)

    if @prompt.save
      redirect_to @prompt, notice: "Prompt created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @prompt.update(prompt_params)
      respond_to do |format|
        format.html { redirect_to @prompt, notice: "Prompt updated successfully." }
        format.json { render json: { status: :ok, prompt: @prompt } }
        format.turbo_stream
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @prompt.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    redirect_target = @prompt.project ? project_path(@prompt.project) : root_path
    @prompt.destroy
    redirect_to redirect_target, notice: "Prompt deleted successfully."
  end

  def attach_files
    if params[:files].present?
      @prompt.files.attach(params[:files])
    end

    respond_to do |format|
      format.html { redirect_to @prompt, notice: "Files attached successfully." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "prompt_attachments",
          partial: "prompts/attachments",
          locals: { prompt: @prompt }
        )
      end
      format.json { render json: { status: :ok, count: @prompt.files.count } }
    end
  end

  def purge_attachment
    attachment = @prompt.files.find(params[:attachment_id])
    attachment.purge

    respond_to do |format|
      format.html { redirect_to @prompt, notice: "Attachment removed." }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "prompt_attachments",
          partial: "prompts/attachments",
          locals: { prompt: @prompt }
        )
      end
    end
  end

  private

  def set_prompt
    @prompt = Prompt.find(params[:id])
  end

  def prompt_params
    params.require(:prompt).permit(:title, :body, :project_id, files: [])
  end
end
