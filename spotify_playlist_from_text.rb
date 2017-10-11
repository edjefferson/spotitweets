require 'rspotify'
class SpotifyPlaylistFromText
  def initialize(text, spotify_user, refresh_token, spotify_key, spotify_secret)
    @text = text
    @spotify_user = spotify_user
    @refresh_token = refresh_token
    @spotify_key = spotify_key
    @spotify_secret = spotify_secret
  end
  def text
    @text
  end

  def spotify_user
    @spotify_user
  end

  def refresh_token
    @refresh_token
  end

  def spotify_key
    @spotify_key
  end

  def spotify_secret
    @spotify_secret
  end

  def spotify_playlist_build
    RSpotify.authenticate(self.spotify_key, self.spotify_secret)
    words = self.text.gsub(/[^ \w\-]+/, "").split("http")[0].split(" ")
    spotify_uris = []
    until words.length == 0

      search_term = words.first(3).join(" ")
      tracks = RSpotify::Track.search("track:#{search_term}").select {|track| track.available_markets.include?("GB") == true}.sort_by { |track| track.name.length }
      exact_matches = tracks.select { |track|  track.name.downcase == search_term.downcase }
      if exact_matches.count > 0
        spotify_uris << exact_matches[0].uri
        words = words.drop(3)
      else
        search_term = words.first(2).join(" ")
        tracks = RSpotify::Track.search("track:#{search_term}").sort_by { |track| track.name.length }
        exact_matches = tracks.select { |track|  track.name.downcase == search_term.downcase }
        if exact_matches.count > 0
          spotify_uris << exact_matches[0].uri
          words = words.drop(2)
        else
          if ["a","and","at","is","in","are","to","by","as","your","for","of","be","with"].include?(words[0].strip.downcase) == false
            tracks = RSpotify::Track.search("track:#{words[0]}").sort_by { |track| track.name.length }
            if tracks.count > 0
              exact_matches = tracks.select { |track|  track.name.downcase == words[0].downcase }
              result = exact_matches.count == 0 ? tracks[0].uri : exact_matches[0].uri
              spotify_uris << result
            end
          end
          words = words.drop(1)
        end
      end
    end



    access_token = get_access_token
    playlist_uri = create_spotify_playlist(self.spotify_user, access_token, self.text, true)
    replace_spotify_playlist(self.spotify_user, access_token, playlist_uri, spotify_uris)
    url = "https://open.spotify.com/user/8t759jzmggdm8qpdl79lw1rrs/playlist/#{playlist_uri}"
    return {original_text: self.text,url: url}
  end

  def get_refresh_token
    redirect_uri = "http://localhost:8082/"
    step_one = RestClient.get 'https://accounts.spotify.com/authorize/', {params: {:client_id => self.spotify_key, :redirect_uri => redirect_uri, :response_type => 'code', :scope => "playlist-modify-private playlist-modify-public playlist-read-private"} }
    puts step_one.request.url
    code = gets.split("=")[1][0..-2]
    puts code
    begin
      step_four = RestClient.post 'https://accounts.spotify.com/api/token', {:client_id => self.spotify_key, :client_secret => self.spotify_secret, grant_type: 'authorization_code', code: code, redirect_uri: redirect_uri }
    rescue RestClient::ExceptionWithResponse => e
      puts  e.response
    end
    puts step_four
  end

  def get_access_token
    auth_info = self.spotify_key + ":" + self.spotify_secret
    encoded_auth_info = Base64.strict_encode64(auth_info)
    redirect_uri = "http://localhost:8082/"
    uri = URI.parse("https://accounts.spotify.com/api/token")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Basic " + encoded_auth_info
    request.set_form_data(
    "grant_type" => "refresh_token",
    "refresh_token" => self.refresh_token
    )
    req_options = {
    use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|

      http.request(request)
    end

    return JSON.parse(response.body)["access_token"]
  end

  def spotify_api_request(uri,body,access_token,type)
    uri = URI.parse(uri)
    if type == "post"
      request = Net::HTTP::Post.new(uri)
    elsif type == "put"
      request = Net::HTTP::Put.new(uri)
    end
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{access_token}"
    request.body = JSON.dump(body)

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def replace_spotify_playlist(user_name, access_token, playlist_uri, tracks)
    uri = "https://api.spotify.com/v1/users/#{user_name}/playlists/#{playlist_uri}/tracks"
    body = {
        "uris" => tracks
      }

    response = spotify_api_request(uri, body, access_token, "put")

    return JSON.parse(response.body)["uri"]
  end


  def create_spotify_playlist(user_name, access_token, playlist_name, public)
    uri = "https://api.spotify.com/v1/users/#{user_name}/playlists"
    body = {
        "name" => playlist_name,
        "public" => public
      }
    response = spotify_api_request(uri, body, access_token, "post")


    return JSON.parse(response.body)["uri"].to_s.split(":")[4]
  end
end
