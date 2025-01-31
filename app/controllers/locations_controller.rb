class LocationsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story
  before_action :set_location

  def show
  end

  private

  def set_story
    @story = current_user.stories.find(params[:story_id])
  end

  def set_location
    @location = @story.locations.find(params[:id])
  end
end
