# The configured citation metadata service. It answers GET /works?doi=... with a
# JSON title and source URL, using HTTP basic authentication. Settings come from
# config/secrets.yml, which reads them from the environment.
class Citation::Provider
  # The provider answered, but cannot supply metadata for this DOI.
  class Error < StandardError; end

  # The provider cannot answer now. Asking again later may succeed.
  class Unavailable < StandardError; end

  Metadata = Struct.new(:title, :source_url)

  def initialize(settings = Rails.application.secrets.citation_provider.to_h)
    @url, @user, @password = settings.values_at(:url, :user, :password)
  end

  def lookup(doi)
    raise Error, "No citation provider is configured" if @url.blank?

    response = connection.get("works", doi: doi)

    case response.status
    when 200 then metadata_from(response.body)
    when 401, 403 then raise Error, "The provider rejected the configured credentials (HTTP #{response.status})"
    when 404 then raise Error, "The provider has no record of this DOI"
    when 429, 500..599 then raise Unavailable, "The provider is unavailable (HTTP #{response.status})"
    else raise Error, "The provider gave an unexpected response (HTTP #{response.status})"
    end
  rescue Faraday::ConnectionFailed, Faraday::TimeoutError => error
    raise Unavailable, "The provider could not be reached (#{error.message})"
  end

  private
    # Retries a GET once on 503 before reporting the provider unavailable.
    def connection
      Faraday.new(url: @url, request: { open_timeout: 2, timeout: 5 }) do |faraday|
        faraday.request :retry, max: 1, retry_statuses: [503]
        faraday.request :basic_auth, @user, @password
      end
    end

    def metadata_from(body)
      attributes = JSON.parse(body)
      title, source_url = attributes["title"], attributes["url"] if attributes.is_a?(Hash)

      if title.is_a?(String) && title.present? && web_url?(source_url)
        Metadata.new(title.strip, source_url)
      else
        raise Error, "The provider's response did not include a title and web address"
      end
    rescue JSON::ParserError
      raise Error, "The provider's response was not valid JSON"
    end

    def web_url?(url)
      uri = URI.parse(url.to_s)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
end
