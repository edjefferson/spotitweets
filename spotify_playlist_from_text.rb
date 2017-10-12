require 'base64'
require 'net/http'
require 'json'

class SpotifyPlaylistFromText
  def initialize(text, spotify_user, refresh_token, spotify_key, spotify_secret)
    @text = text
    @spotify_user = spotify_user
    @spotify_key = spotify_key
    @spotify_secret = spotify_secret
    @access_token = get_access_token(refresh_token)
  end

  def text
    @text
  end

  def exclusion_list
    ["a","and","at","is","in","are","to","by","as","your","for","of","be","with","was"]
  end

  def encoded_auth_info
    Base64.strict_encode64(@spotify_key + ":" + @spotify_secret)
  end

  def get_access_token(refresh_token)
    uri = URI.parse("https://accounts.spotify.com/api/token")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Basic " + encoded_auth_info
    request.set_form_data(
    "grant_type" => "refresh_token",
    "refresh_token" => refresh_token
    )
    req_options = {
    use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end

    return JSON.parse(response.body)["access_token"]
  end

  def search_results(search_term)
    puts "search for: #{search_term}"
    tracks = search_spotify_tracks(search_term)
    if tracks != nil
      tracks.sort_by! { |track| track["name"].length }
      exact_matches = tracks.select { |track|  track["name"].gsub(/[^ \w\-]+/, "").downcase == search_term.downcase }
      puts "matches #{exact_matches.count}"
    else
      exact_matches = []
    end
    return {tracks: tracks, exact_matches: exact_matches}
  end


  def search_for_first_x_words(words, x)
    search_term = words.first(x).join(" ")
    results = search_results(search_term)
    if results[:exact_matches].count > 0
      result = results[:exact_matches][0]
      @spotify_uris << result["uri"]
      y = 5
      y = (words.count - x) if (words.count - x) < 5
      return { x:y, remaining_words: words.drop(x)}
    else
      return { x: x - 1, remaining_words: words}
    end
  end

  def search_for_first_word(words)
    if exclusion_list.include?(words[0].strip.downcase) == false
      search_term = words.first
      results = search_results(search_term)
      result = results[:exact_matches].count == 0 ? results[:tracks][0] : results[:exact_matches][0]
      @spotify_uris << result["uri"]
    end
    y = 5
    y = (words.count - 1) if (words.count - 1) < 5
    return { x: y, remaining_words: words.drop(1)}
  end

  def get_spotify_tracks
    words = self.text.gsub(/[^ \w\-]+/, "").split("http")[0].split(" ")
    puts self.text
    puts words.count
    @spotify_uris = []
    x = 5
    x = words.count if words.count < 5
    until words.length == 0
      if x > 1
        search = search_for_first_x_words(words, x)
      else
        search = search_for_first_word(words)
      end
      words = search[:remaining_words]
      x = search[:x]

    end
    return @spotify_uris
  end

  def spotify_playlist_build
    spotify_uris = get_spotify_tracks
    playlist_uri = create_spotify_playlist(@spotify_user, self.text, true)
    replace_spotify_playlist(@spotify_user, playlist_uri, spotify_uris)
    url = "https://open.spotify.com/user/#{@spotify_user}/playlist/#{playlist_uri}"
    return {original_text: self.text,url: url}
  end

  def get_refresh_token
    redirect_uri = "http://localhost:8082/"
    step_one = RestClient.get 'https://accounts.spotify.com/authorize/', {params: {:client_id => @spotify_key, :redirect_uri => redirect_uri, :response_type => 'code', :scope => "playlist-modify-private playlist-modify-public playlist-read-private"} }
    puts step_one.request.url
    code = gets.split("=")[1][0..-2]
    puts code
    begin
      step_four = RestClient.post 'https://accounts.spotify.com/api/token', {:client_id => @spotify_key, :client_secret => @spotify_secret, grant_type: 'authorization_code', code: code, redirect_uri: redirect_uri }
    rescue RestClient::ExceptionWithResponse => e
      puts  e.response
    end
    puts step_four
  end



  def spotify_api_request(uri,body,type)
    uri = URI.parse(uri)
    if type == "post"
      request = Net::HTTP::Post.new(uri)
    elsif type == "put"
      request = Net::HTTP::Put.new(uri)
    elsif type == "get"
      request = Net::HTTP::Get.new(uri)
    end
    request.content_type = "application/json"
    request["Authorization"] = "Bearer #{@access_token}"
    request.body = JSON.dump(body)

    req_options = {
      use_ssl: uri.scheme == "https",
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
  end

  def replace_spotify_playlist(user_name, playlist_uri, tracks)
    uri = "https://api.spotify.com/v1/users/#{user_name}/playlists/#{playlist_uri}/tracks"
    body = {
        "uris" => tracks
      }

    response = spotify_api_request(uri, body, "put")

    return JSON.parse(response.body)["uri"]
  end


  def create_spotify_playlist(user_name, playlist_name, public)
    uri = "https://api.spotify.com/v1/users/#{user_name}/playlists"
    body = {
        "name" => playlist_name,
        "public" => public
      }
    response = spotify_api_request(uri, body, "post")


    return JSON.parse(response.body)["uri"].to_s.split(":")[4]
  end

  def search_spotify_tracks(query)
    formatted_query = query.gsub(" ","%20").downcase
    if formatted_query.to_s != ""
      limit = 50
      offset = 0
      market = "GB"
      type = "track"
      body = nil
      uri = "https://api.spotify.com/v1/search/?q=track:#{formatted_query}&limit=#{limit}&offset=#{offset}&type=#{type}&market=#{market}"
      response = spotify_api_request(uri, body, "get")
      puts JSON.parse(response.body)["tracks"]["items"].count
      return JSON.parse(response.body)["tracks"]["items"]
    end
  end
end
