class StoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story, only: [:show, :destroy]

  def create
    story = AiService.new(genre: params[:genre], user: current_user).start
    redirect_to root_path
  end

  def show
  end

  def destroy
    @story.destroy
    redirect_to root_path, notice: "Story deleted successfully"
  end

  private

  def set_story
    @story = current_user.stories.find(params[:id])
  end
end
