class StoryContinuationService
  def initialize(story:, input:)
    @story = story
    @input = input
  end

  def continue
    content = OpenaiService.new(
      role: story_role,
      prompt: story_prompt
    ).fetch_response

    return if content.nil?

    save_response(content)
  end

  private

  def save_response(content)
    save_characters(content[:new_characters]) if content[:new_characters].present?
    save_locations(content[:new_locations]) if content[:new_locations].present?
    save_missions(content[:new_missions]) if content[:new_missions].present?
    save_events(content[:character_events], :character) if content[:character_events].present?
    save_events(content[:location_events], :location) if content[:location_events].present?
    save_events(content[:mission_events], :mission) if content[:mission_events].present?
    save_items(content[:new_items]) if content[:new_items].present?
    save_facts(content[:new_facts]) if content[:new_facts].present?
  end

  def save_characters(characters)
    characters.each { |character| Character.create!(character.merge(story: @story)) }
  end

  def save_locations(locations)
    locations.each { |location| Location.create!(location.merge(story: @story)) }
  end

  def save_missions(missions)
    missions.each { |mission| Mission.create!(mission.merge(story: @story)) }
  end

  def save_events(events, category)
    events.each do |event|
      case category
      when :character
        character = Character.find(event[:character_id])
        event_record = Event.create!(event.merge(story: @story))
        CharacterEvent.create!(character:, event: event_record)
      when :location
        location = Location.find(event[:location_id])
        event_record = Event.create!(event.merge(story: @story))
        LocationEvent.create!(location:, event: event_record)
      when :mission
        mission = Mission.find(event[:mission_id])
        event_record = Event.create!(event.merge(story: @story))
        MissionEvent.create!(mission:, event: event_record)
      end
    end
  end

  def save_items(items)
    items.each { |item| Item.create!(item.merge(story: @story)) }
  end

  def save_facts(facts)
    facts.each { |fact| Fact.create!(content: fact, story: @story) }
  end

  def story_role
    <<~TEXT
      You are a game master creating a new #{@story.genre} role-playing game titled #{@story.title}. The hero of our
      story is #{@story.hero}. The overview: #{@story.overview}. Based on the provided information, generate an
      appropriate JSON response as outlined. If you are unable to generate a response for any reason, return an empty
      JSON object.
    TEXT
  end

  def story_details
    <<~TEXT
      Facts: #{@story.facts.map(&:content).join("\n")}
      Missions: #{@story.missions.map { |mission| "#{mission.name}: #{mission.description} (#{mission.status})" }.join("\n")}
      Locations: #{@story.locations.map { |location| "#{location.name}: #{location.description} (#{location.category}) ID: #{location.id}" }.join("\n")}
      Characters: #{@story.characters.map { |character| "#{character.name}: #{character.description} (#{character.role}) ID: #{character.id}" }.join("\n")}
      Items: #{@story.items.map { |item| "#{item.name}: #{item.description} (#{item.category}) ID: #{item.id}" }.join("\n")}
      Events: #{@story.events.map(&:short).join("\n")}
      User action: #{@input}
    TEXT
  end

  def story_prompt
    <<~TEXT
      Continue the story based on the following details:
      Genre: #{@story.genre}
      Hero: #{@story.hero.name}
      Overview: #{@story.overview}
      Details: #{story_details}
      Character's Actions: #{@input}

      Generate the next story segment with new events, characters, locations, and missions.
      Your response must be in valid JSON format with the following structure:
      {
        "new_events": [
          {
            "description": "Write a detailed event description",
            "short": "Write a brief summary",
            "category": "Choose from: combat, dialogue, discovery, travel"
          }
        ],
        "new_characters": [
          {
            "name": "Generate NPC name",
            "description": "Write character description",
            "role": "Choose from: ally, villain, neutral"
          }
        ],
        "new_locations": [
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
            "status": "Choose from: not_started, active, completed"
          }
        ],
        "new_facts": [
          "Write a new fact about the story world or characters"
        ]
      }

      Important: Generate completely new and unique content that advances the story.
      Create at least 1 event, and optionally include new characters, locations, missions, or facts as the story requires.
      Make sure all new content fits coherently with the existing story and genre.
    TEXT
  end
end
