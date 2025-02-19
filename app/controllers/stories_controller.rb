class StoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story, only: [ :show, :destroy, :update ]

  def index
  end

  def create
    result = StoryStartService.new(
      genre: params[:genre],
      user: current_user
    ).start

    if result
      session[:choices] = result[:choices]
      redirect_to story_path(result[:story])
    else
      error_message = find_error_message || "Failed to create story"
      flash[:alert] = error_message
      redirect_to root_path
    end
  end

  def show
    @choices = session[:choices] || []
  end

  def update
    result = StoryContinuationService.new(
      story: @story,
      input: params[:input]
    ).continue

    if result
      session[:choices] = result[:choices]
      redirect_to story_path(result[:story])
    else
      error_message = find_error_message || "Failed to continue story"
      flash[:alert] = error_message
      redirect_to story_path(@story)
    end
  end

  def destroy
    @story.destroy
    flash[:notice] = "Story deleted successfully"
    redirect_to root_path
  end

  private

  def set_story
    @story = current_user.stories.find(params[:id])
  end

  def find_error_message
    log_content = Rails.logger.instance_variable_get(:@logdev)
                      .instance_variable_get(:@dev)
                      .string
                      .split("\n")

    error_line = log_content.find do |line|
      line.include?("Error occurred while saving story:") ||
      line.include?("Validation failed while saving story:")
    end

    return unless error_line

    error_line.gsub(/Error occurred while saving story: |Validation failed while saving story: /, "")
  end
end
