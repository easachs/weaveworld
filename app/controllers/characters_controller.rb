class CharactersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story
  before_action :set_character

  def show
    # redirect_to story_path(@story) if @character.role == "user"
  end

  private

  def set_story
    @story = current_user.stories.find(params[:story_id])
  end

  def set_character
    @character = @story.characters.find(params[:id])
  end
end
