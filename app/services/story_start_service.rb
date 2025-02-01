class StoryStartService
  def initialize(genre:, user:)
    @genre = genre
    @user = user
  end

  def start
    content = OpenaiService.new(
      role: start_role,
      prompt: start_prompt
    ).fetch_response

    # Add logging for AI response
    Rails.logger.info "AI Response: #{content.inspect}"

    return nil if content.nil?

    story = save_start(content)
    return nil if story.nil?

    {
      story: story,
      choices: content[:choices] || []
    }
  end

  private

  def save_start(content)
    ActiveRecord::Base.transaction do
      story = Story.create!(
        title: content[:title],
        overview: content[:overview],
        genre: @genre,
        user: @user
      )

      Character.create!(
        name: content.dig(:hero, :name),
        description: content.dig(:hero, :description),
        role: "user",
        story: story
      )

      save_characters(content[:new_characters], story) if content[:new_characters].present?
      save_locations(content[:new_locations], story) if content[:new_locations].present?
      save_missions(content[:new_missions], story) if content[:new_missions].present?
      save_facts(content[:new_facts], story) if content[:new_facts].present?

      Summary.create!(text: story.overview, story: story)

      story
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Validation failed while saving story: #{e.message}"
    nil
  rescue StandardError => e
    Rails.logger.error "Error occurred while saving story: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end

  def save_characters(characters, story)
    characters.each { |character| Character.create!(character.merge(story: story)) }
  end

  def save_locations(locations, story)
    locations.each { |location| Location.create!(location.merge(story: story)) }
  end

  def save_missions(missions, story)
    missions.each do |mission|
      mission[:status] = "not started"
      Mission.create!(mission.merge(story: story))
    end
  end

  def save_facts(facts, story)
    facts.each { |fact| Fact.create!(text: fact, story: story) }
  end

  def start_role
    genre_guidance = case @genre.downcase
    when "horror"
      "Create a dark and unsettling horror story with elements of dread, supernatural threats, and psychological tension."
    when "science fiction"
      "Create a science fiction story with advanced technology, space exploration, or futuristic concepts as central elements."
    else # fantasy
      "Create a fantasy story with magical elements, mythical creatures, and epic adventures."
    end

    <<~TEXT
      You are a game master creating a new #{@genre} role-playing game. #{genre_guidance}
      Generate an appropriate JSON response as outlined. If you are unable to generate a response for any reason,
      return an empty JSON object.
    TEXT
  end

  def start_prompt
    <<~TEXT
      You are creating a new #{@genre} story. Generate a compelling #{@genre} story setup including a title,
      overview, and initial world details.
      Your response must be in valid JSON format with the following structure:
      {
        "title": "Create an engaging #{@genre} title",
        "overview": "Write a 2-3 sentence story overview that captures the #{@genre} atmosphere",
        "hero": {
          "name": "Generate main character's name appropriate for #{@genre}",
          "description": "Write main character's description fitting the #{@genre} setting"
        },
        "new_characters": [
          {
            "name": "Generate NPC name",
            "description": "Write character description",
            "role": "Choose from: ally, villain, neutral"
          }
        ],
        "new_locations": [
          {
            "name": "The World",
            "description": "Write an overview of the story's world/setting",
            "category": "world"
          },
          {
            "name": "Generate location name",
            "description": "Write location description",
            "category": "Choose from: city, dungeon, forest, castle, etc"
          }
        ],
        "new_missions": [
          {
            "name": "Generate mission name",
            "description": "Write mission description",
            "status": "not started"
          }
        ],
        "new_facts": [
          "Write an important fact about the story world, its history, or key elements"
        ],
        "choices": [
          "Write a short, specific action the player could take (1-2 sentences)",
          "Write another distinct action choice",
          "Write a third distinct action choice"
        ]
      }

      Important: Generate completely new and unique content. Do not return this example structure.
      Create:
      - 3 characters (in addition to the hero)
      - 1 world location and 3 specific locations
      - 3 missions (all not started)
      - 3 key facts about the world

      Ensure all content strongly reflects the #{@genre} genre and creates a cohesive setting.
    TEXT
  end
end
