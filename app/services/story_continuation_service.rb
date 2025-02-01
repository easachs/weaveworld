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
    Rails.logger.info "AI Request: #{story_prompt}"
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
    temp_id_map = {}

    ActiveRecord::Base.transaction do
      # First create all new records and store their mappings
      if content[:new_locations].present?
        content[:new_locations].each do |loc|
          temp_id = loc.delete(:temp_id)
          record = Location.create!(loc.merge(story: @story, new: true))
          temp_id_map[temp_id.to_s] = record if temp_id
        end
      end

      if content[:new_characters].present?
        content[:new_characters].each do |char|
          temp_id = char.delete(:temp_id)
          record = Character.create!(char.merge(story: @story, new: true))
          temp_id_map[temp_id.to_s] = record if temp_id
        end
      end

      if content[:new_missions].present?
        content[:new_missions].each do |mission|
          temp_id = mission.delete(:temp_id)
          mission[:status] = "not started"
          record = Mission.create!(mission.merge(story: @story, new: true))
          temp_id_map[temp_id.to_s] = record if temp_id
        end
      end

      # Then create events with proper associations
      if content[:events].present?
        content[:events].each do |event|
          # Map location IDs - check if they're temp IDs first
          location_ids = (event[:location_ids] || []).map do |id|
            temp_id_map[id.to_s]&.id || id
          end

          # Create the event with mapped IDs
          event_attrs = event.except(:character_ids, :location_ids, :mission_ids,
                                   :new_character_refs, :new_location_refs, :new_mission_refs)
          event_record = Event.create!(event_attrs.merge(story: @story))

          # Handle location associations with mapped IDs
          location_ids.each do |id|
            location = @story.locations.find(id)
            LocationEvent.create!(location: location, event: event_record)
          end

          # Handle character associations
          event[:character_ids]&.each do |id|
            character = @story.characters.find(id)
            CharacterEvent.create!(character: character, event: event_record)
          end

          event[:mission_ids]&.each do |id|
            mission = @story.missions.find(id)
            MissionEvent.create!(mission: mission, event: event_record)
          end

          # Handle new record associations using temp_ids
          event[:new_character_refs]&.each do |temp_id|
            if character = temp_id_map[temp_id.to_s]
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

          # Update character locations based on the mapped location IDs
          if location_ids.present? && event[:character_ids].present?
            location_id = location_ids.first # Use the mapped location ID
            @story.characters.where(id: event[:character_ids]).update_all(location_id: location_id)
          end

          # For new characters, set their initial location using mapped IDs
          event[:new_character_refs]&.each do |temp_id|
            if character = temp_id_map[temp_id.to_s]
              if location_ids.present?
                character.update(location_id: location_ids.first)
              elsif event[:new_location_refs].present?
                new_location = temp_id_map[event[:new_location_refs].first.to_s]
                character.update(location_id: new_location.id) if new_location
              end
            end
          end
        end
      end

      # Save any new facts
      content[:new_facts]&.each { |fact| Fact.create!(text: fact, story: @story, new: true) }

      # Handle mission status updates
      if content[:completed_mission_ids].present?
        @story.missions.where(id: content[:completed_mission_ids]).update_all(status: "completed")
      end

      if content[:in_progress_mission_ids].present?
        missions_to_update = @story.missions.where(id: content[:in_progress_mission_ids])
                                   .where.not(status: "completed")

        missions_to_update.update_all(status: "in progress")
      end
    end
  end

  def save_summary(summary_text)
    Summary.create!(text: summary_text, story: @story)
  end

  def story_role
    <<~TEXT
      You are a game master continuing a #{@story.genre} story titled #{@story.title}, featuring #{@story.hero.name} as the hero.

      Core Principles:
      1. Maintain strict consistency with established facts and events
      2. Remember character relationships/motivations
      3. Keep track of character locations
      4. Build upon existing plot threads over starting new ones
      5. Keep the story focused on active missions and current conflicts

      Continue the story based on the player's input, creating a cohesive narrative that
      builds upon existing elements. Focus on developing current storylines and existing
      relationships rather than introducing new elements unless absolutely necessary.
    TEXT
  end

  def story_details
    <<~TEXT
      Story Overview:
      #{@story.overview}

      Story So Far:
      #{@story.summaries.last(10).map(&:text).join("\n")}

      World Facts:
      #{@story.facts.map(&:text).join("\n")}

      Active Missions:
      #{@story.missions.where.not(status: "completed").map { |m| "#{m.name} (#{m.status}): #{m.description} [ID: #{m.id}]" }.join("\n")}

      Key Locations:
      #{@story.locations.map { |l| "#{l.name} (#{l.category}): #{l.description} [ID: #{l.id}]" }.join("\n")}

      Characters Present:
      #{@story.characters.map { |c|
        location_info = c.location ? " - Currently at: #{c.location.name}" : " - Location: Unknown"
        relationships = c.role == "user" ? "" : " - Role: #{c.role}"
        "#{c.name} [ID: #{c.id}]:#{relationships} #{c.description}#{location_info} [ID: #{c.location_id}]"
      }.join("\n")}

      Recent Events:
      #{@story.events.last(10).map { |e|
        characters = e.characters.map(&:name).join(", ")
        location = e.locations.first&.name || "Unknown Location"
        "- At #{location} (#{characters}): #{e.description}"
      }.join("\n")}

      Player Input:
      #{@input}
    TEXT
  end

  def story_prompt
    <<~TEXT
      Continue the story based on these details:
      #{story_details}

      Key Requirements:
      1. Advance at least one active mission
      2. Keep character movements logical
      3. Reference past events when relevant
      4. Use temp_ids to connect new elements
      5. Include locations for all events

      Generate the next story segment in response to the player's input.
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
            "description": "Mission description"
          }
        ],
        "new_facts": [
          "New key fact about the story world or characters that are relevant to missions"
        ],
        "completed_mission_ids": [
          "IDs of any missions that should be marked as completed"
        ],
        "in_progress_mission_ids": [
          "IDs of any missions that should be marked as in progress"
        ],
        "choices": [
          "Write a short, specific action the player could take (1-2 sentences)",
          "Write another distinct action choice",
          "Write a third distinct action choice"
        ]
      }

      Additional Guidelines:
      1. Events should directly build on previous events and established context
      2. New characters should have clear connections to existing characters or plot threads
      3. Location changes should be explicitly noted and logically possible
      4. Mission updates should reflect meaningful progress
      5. New facts should clarify or expand existing knowledge, not contradict it
      6. Choices should reflect current situation and available options
      7. The summary should be detailed and comprehensive
      8. Make sure not to createduplicate events, characters, locations, or missions
    TEXT
  end
end
