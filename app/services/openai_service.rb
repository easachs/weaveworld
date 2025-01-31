class OpenaiService
  def initialize(role:, prompt:)
    @role = role
    @prompt = prompt
  end

  def fetch_response
    response = fetch_gpt
    parsed_response = JSON.parse(response.body, symbolize_names: true)
    content = parsed_response.dig(:choices, 0, :message, :content)
    JSON.parse(content, symbolize_names: true)
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse JSON: #{e.message}"
    nil
  end

  private

  def fetch_gpt
    response = conn.post("v1/chat/completions") do |route|
      route.body = {
        model: "gpt-3.5-turbo",
        messages: [
          { role: "system", content: @role },
          { role: "user", content: @prompt }
        ],
        temperature: 0.5
      }.to_json
    end

    raise "API Error: #{response.status}" unless response.success?

    response
  rescue Faraday::Error => e
    raise "Network Error: #{e.message}"
  end

  def conn
    Faraday.new(url: "https://api.openai.com") do |route|
      route.headers["Authorization"] = "Bearer #{ENV.fetch('OPENAI_KEY', nil)}"
      route.headers["Content-Type"] = "application/json"
    end
  end
end
