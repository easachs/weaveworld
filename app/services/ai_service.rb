class AiService
  def initialize(story: nil, input: nil, genre: nil, user: nil)
    @story = story
    @input = input
    @genre = genre
    @user = user
  end

  def start = format_response(STORY_ROLE, START_PROMPT, :start)
  def story = format_response(STORY_ROLE, STORY_PROMPT, :story)

  private

  def format_response(role, input, category)
    return if input.blank?

    response = fetch_gpt(role, input)
    parsed_response = JSON.parse(response.body, symbolize_names: true)
    content = parsed_response.dig(:choices, 0, :message, :content)
    parsed_content = JSON.parse(content, symbolize_names: true)

    category == :start ? save_start(parsed_content) : save_response(parsed_content)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse JSON: #{e.message}"
    nil
  end

  def save_start(content)
    story = Story.create!(title: content.dig(:title), overview: content.dig(:overview), genre: @genre, user: @user)
    Character.create!(name: content.dig(:hero, :name), description: content.dig(:hero, :description), role: "user", story: story)
    save_characters(content.dig(:new_characters), story) if content.dig(:new_characters).present?
    save_locations(content.dig(:new_locations), story) if content.dig(:new_locations).present?
    save_missions(content.dig(:new_missions), story) if content.dig(:new_missions).present?
  rescue => e
    Rails.logger.error "Failed to save start: #{e.message}"
    nil
  end

  def save_response(content)
    save_characters(content.dig(:new_characters)) if content.dig(:new_characters).present?
    save_locations(content.dig(:new_locations)) if content.dig(:new_locations).present?
    save_missions(content.dig(:new_missions)) if content.dig(:new_missions).present?
    save_events(content.dig(:character_events), :character) if content.dig(:character_events).present?
    save_events(content.dig(:location_events), :location) if content.dig(:location_events).present?
    save_events(content.dig(:mission_events), :mission) if content.dig(:mission_events).present?
    save_items(content.dig(:new_items)) if content.dig(:new_items).present?
    save_facts(content.dig(:new_facts)) if content.dig(:new_facts).present?
  end

  def save_characters(characters, story)
    characters.each { |character| Character.create!(character.merge(story: story)) }
  end

  def save_locations(locations, story)
    locations.each { |location| Location.create!(location.merge(story: story)) }
  end

  def save_missions(missions, story)
    missions.each { |mission| Mission.create!(mission.merge(story: story)) }
  end

  def save_events(events, category, story)
    events.each do |event|
      case category
      when :character
        character = Character.find(event[:character_id])
        event_record = Event.create!(event.merge(story: story))
        CharacterEvent.create!(character:, event: event_record)
      when :location
        location = Location.find(event[:location_id])
        event_record = Event.create!(event.merge(story: story))
        LocationEvent.create!(location:, event: event_record)
      when :mission
        mission = Mission.find(event[:mission_id])
        event_record = Event.create!(event.merge(story: story))
        MissionEvent.create!(mission:, event: event_record)
      end
    end
  end

  def save_items(items, story)
    items.each { |item| Item.create!(item.merge(story: story)) }
  end

  def save_facts(facts, story)
    facts.each { |fact| Fact.create!(content: fact, story: story) }
  end

  def fetch_gpt(role, prompt)
    response = conn.post("v1/chat/completions") do |route|
      route.body = { model: "gpt-3.5-turbo",
                    messages: [ { role: "system", content: role },
                                { role: "user", content: prompt } ],
                    temperature: 0.5 }.to_json
    end

    raise "API Error: #{response.status}" unless response.success?

    response
  rescue Faraday::Error => e
    raise "Network Error: #{e.message}"
  end

  def conn
    Faraday.new(url: "https://api.openai.com") do |route|
      route.headers["Authorization"] = "Bearer #{ENV.fetch('OPENAI_KEY', nil)}"
      route.headers["Content-Type"]  = "application/json"
    end
  end

  START_ROLE = <<~TEXT
    You are a game master creating a new #{@genre} role-playing game. Generate an appropriate JSON response as
    outlined. If you are unable to generate a response for any reason, return an empty JSON object.
  TEXT

  START_PROMPT = <<~TEXT
    You are creating a new #{@genre} story. The main character's name is #{@name}.

    Generate a compelling #{@genre} story setup including a title, overview, and initial characters, locations,
    and missions.
    Your response must be in valid JSON format with the following structure:
    {
      "title": "Create an engaging title",
      "overview": "Write a 2-3 sentence story overview",
      "hero": {
        "name": "Generate main character's name",
        "description": "Write main character's description"
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
          "name": "Generate location name",
          "description": "Write location description",
          "category": "Choose from: city, dungeon, forest, castle, etc"
        }
      ],
      "new_missions": [
        {
          "name": "Generate mission name",
          "description": "Write mission description",
          "status": "Choose from: not started, active"
        }
      ]
    }

    Important: Generate completely new and unique content. Do not return this example structure.
    Create 3 characters, 3 locations, and 3 missions.
  TEXT

  STORY_ROLE = <<~TEXT
    You are a game master creating a new #{@story&.genre} role-playing game titled #{@story&.title}. The hero of our
    story is #{@story&.hero}. The overview: #{@story&.overview}. Based on the provided information, generate an
    appropriate JSON response as outlined. If you are unable to generate a response for any reason, return an empty
    JSON object.
  TEXT

  DETAILS = <<~TEXT
    Facts: #{@story&.facts&.map(&:content)&.join("\n")}
    Missions: #{@story&.missions&.map { |mission| "#{mission.name}: #{mission.description} (#{mission.status})" }&.join("\n")}
    Locations: #{@story&.locations&.map { |location| "#{location.name}: #{location.description} (#{location.category}) ID: #{location.id}" }&.join("\n")}
    Characters: #{@story&.characters&.map { |character| "#{character.name}: #{character.description} (#{character.role}) ID: #{character.id}" }&.join("\n")}
    Items: #{@story&.items&.map { |item| "#{item.name}: #{item.description} (#{item.category}) ID: #{item.id}" }&.join("\n")}
    Events: #{@story&.events&.map(&:short)&.join("\n")}
    User action: #{@input}
  TEXT

  STORY_PROMPT = <<~TEXT
    Continue the story based on the following details:
    Genre: #{@genre}
    Hero: #{@name}
    Overview: #{@story&.overview}
    Details: #{DETAILS}
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
        {
          "text": "Write a new fact about the story world or characters"
        }
      ]
    }

    Important: Generate completely new and unique content that advances the story.
    Create at least 1 event, and optionally include new characters, locations, missions, or facts as the story requires.
    Make sure all new content fits coherently with the existing story and genre.
  TEXT
end
