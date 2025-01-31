class MissionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story
  before_action :set_mission

  def show
  end

  private

  def set_story
    @story = current_user.stories.find(params[:story_id])
  end

  def set_mission
    @mission = @story.missions.find(params[:id])
  end
end
