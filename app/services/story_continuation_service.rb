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

    # Add logging for AI response
    Rails.logger.info "AI Response: #{content.inspect}"

    return nil if content.nil?

    ActiveRecord::Base.transaction do
      # Store existing record IDs before saving new content
      existing_character_ids = @story.characters.pluck(:id)
      existing_location_ids = @story.locations.pluck(:id)
      existing_mission_ids = @story.missions.pluck(:id)
      existing_fact_ids = @story.facts.pluck(:id)
      existing_event_ids = @story.events.pluck(:id)

      # Save new content
      save_response(content)
      save_summary(content[:summary]) if content[:summary].present?

      # Only mark existing records as not new
      @story.characters.where(id: existing_character_ids).update_all(new: false)
      @story.locations.where(id: existing_location_ids).update_all(new: false)
      @story.missions.where(id: existing_mission_ids).update_all(new: false)
      @story.facts.where(id: existing_fact_ids).update_all(new: false)
      @story.events.where(id: existing_event_ids).update_all(new: false)
    end

    {
      story: @story,
      choices: content[:choices] || []
    }
  end

  private

  def save_response(content)
    # Create a hash to store new records by their temp_ids
    temp_id_map = {}

    ActiveRecord::Base.transaction do
      # First create all new records and store their mappings
      if content[:new_characters].present?
        content[:new_characters].each do |char|
          temp_id = char.delete(:temp_id)
          record = Character.create!(char.merge(story: @story, new: true))
          temp_id_map[temp_id] = record if temp_id
        end
      end

      if content[:new_locations].present?
        content[:new_locations].each do |loc|
          temp_id = loc.delete(:temp_id)
          record = Location.create!(loc.merge(story: @story, new: true))
          temp_id_map[temp_id] = record if temp_id
        end
      end

      if content[:new_missions].present?
        content[:new_missions].each do |mission|
          temp_id = mission.delete(:temp_id)
          mission[:status] = "not started"
          record = Mission.create!(mission.merge(story: @story, new: true))
          temp_id_map[temp_id] = record if temp_id
        end
      end

      # Then create events with proper associations
      if content[:events].present?
        content[:events].each do |event|
          # Create the event
          event_attrs = event.except(:character_ids, :location_ids, :mission_ids,
                                   :new_character_refs, :new_location_refs, :new_mission_refs)
          event_record = Event.create!(event_attrs.merge(story: @story))

          # Handle existing record associations
          event[:character_ids]&.each do |id|
            character = @story.characters.find(id)
            CharacterEvent.create!(character: character, event: event_record)
          end

          event[:location_ids]&.each do |id|
            location = @story.locations.find(id)
            LocationEvent.create!(location: location, event: event_record)
          end

          event[:mission_ids]&.each do |id|
            mission = @story.missions.find(id)
            MissionEvent.create!(mission: mission, event: event_record)
          end

          # Handle new record associations using temp_ids
          event[:new_character_refs]&.each do |temp_id|
            if character = temp_id_map[temp_id]
              CharacterEvent.create!(character: character, event: event_record)
            end
          end

          event[:new_location_refs]&.each do |temp_id|
            if location = temp_id_map[temp_id]
              LocationEvent.create!(location: location, event: event_record)
            end
          end

          event[:new_mission_refs]&.each do |temp_id|
            if mission = temp_id_map[temp_id]
              MissionEvent.create!(mission: mission, event: event_record)
            end
          end

          # Update character locations based on the event's location
          if event[:location_ids].present? && event[:character_ids].present?
            location_id = event[:location_ids].first # Assume the first location is where the action happens
            @story.characters.where(id: event[:character_ids]).update_all(location_id: location_id)
          end

          # For new characters, set their initial location
          event[:new_character_refs]&.each do |temp_id|
            if character = temp_id_map[temp_id]
              if event[:location_ids].present?
                character.update(location_id: event[:location_ids].first)
              elsif event[:new_location_refs].present? && (location = temp_id_map[event[:new_location_refs].first])
                character.update(location_id: location.id)
              end
            end
          end
        end
      end

      # Save any new facts
      content[:new_facts]&.each { |fact| Fact.create!(text: fact, story: @story, new: true) }

      # Handle completed missions
      if content[:completed_mission_ids].present?
        @story.missions.where(id: content[:completed_mission_ids]).update_all(status: "completed")
      end
    end
  end

  def save_summary(summary_text)
    Summary.create!(text: summary_text, story: @story)
  end

  def story_role
    <<~TEXT
      You are a game master creating a new #{@story.genre} role-playing game titled #{@story.title}.#{' '}
      The hero is #{@story.hero.name}: #{@story.hero.description}
      Overview: #{@story.overview}

      Your role is to continue the story based on the player's input, creating a cohesive narrative that#{' '}
      builds upon existing elements. Add new characters, locations, missions, or facts ONLY when necessary#{' '}
      to advance the story naturally. Focus on creating meaningful events and interactions with existing#{' '}
      story elements whenever possible.
    TEXT
  end

  def story_details
    <<~TEXT
      World Facts:
      #{@story.facts.map(&:text).join("\n")}

      Active Missions:
      #{@story.missions.map { |m| "#{m.name} (#{m.status}): #{m.description} [ID: #{m.id}]" }.join("\n")}

      Key Locations:
      #{@story.locations.map { |l| "#{l.name} (#{l.category}): #{l.description} [ID: #{l.id}]" }.join("\n")}

      Characters Present:
      #{@story.characters.map { |c|# {' '}
        location_info = c.location ? " - Currently at: #{c.location.name}" : " - Location: Unknown"
        "#{c.name} (#{c.role}): #{c.description}#{location_info} [ID: #{c.id}]"
      }.join("\n")}

      Recent Events:
      #{@story.events.limit(5).map(&:description).join("\n")}

      Player Input:
      #{@input}
    TEXT
  end

  def story_prompt
    <<~TEXT
      Continue the story based on these details:
      #{story_details}

      Generate the next story segment focusing on direct responses to the player's input.
      Your response must be valid JSON with this structure:
      {
        "summary": "Write a detailed narrative summary (3-4 sentences) describing what just happened in the story, including any important changes or revelations",
        "events": [
          {
            "description": "Detailed event description",
            "short": "Brief summary",
            "category": "combat/dialogue/discovery/travel",
            "character_ids": [ids_of_characters_involved],
            "location_ids": [id_of_location_where_event_occurs],
            "mission_ids": [related_mission_ids],
            "new_character_refs": ["temp_id_for_new_character"],
            "new_location_refs": ["temp_id_for_new_location"],
            "new_mission_refs": ["temp_id_for_new_mission"]
          }
        ],
        "new_characters": [
          {
            "temp_id": "temp_id_used_in_events",
            "name": "NPC name",
            "description": "Character description",
            "role": "ally/villain/neutral"
          }
        ],
        "new_locations": [
          {
            "temp_id": "temp_id_used_in_events",
            "name": "Location name",
            "description": "Location description",
            "category": "city/dungeon/forest/castle/etc"
          }
        ],
        "new_missions": [
          {
            "temp_id": "temp_id_used_in_events",
            "name": "Mission name",
            "description": "Mission description",
            "status": "not_started"
          }
        ],
        "new_facts": [
          "New fact about the story world or characters"
        ],
        "completed_mission_ids": [
          "IDs of any missions that should be marked as completed"
        ],
        "choices": [
          "Write a short, specific action the player could take (1-2 sentences)",
          "Write another distinct action choice",
          "Write a third distinct action choice"
        ]
      }

      Important:
      1. Create events that directly respond to the player's input
      2. Use existing story elements whenever possible
      3. Only create new characters, locations, missions, or facts if absolutely necessary
      4. When creating new elements that need to be referenced in events, use temp_id to connect them
      5. Mark missions as completed when appropriate via completed_mission_ids
      6. The summary should be detailed and comprehensive, covering all significant events and changes
      7. Always include the location where events occur - this tracks character movement
    TEXT
  end
end
