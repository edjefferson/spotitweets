require './lib/spotify_api_connection'

class SpotifyPlaylistFromText
  def initialize(text, spotify_user, refresh_token, spotify_key, spotify_secret)
    if refresh_token != nil
      @spotifyapi = SpotifyApiConnection.new(spotify_user, refresh_token, spotify_key, spotify_secret)
    end

    @spotify_user = spotify_user
    @text = text
  end

  def text
    @text
  end

  def exclusion_list
    ["a","and","at","is","in","are","to","by","as","your","for","of","be","with","was","the","i"]
  end

  def search_results(search_term)
    puts "search for: #{search_term}"
    tracks = @spotifyapi.search_spotify_tracks(search_term)
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

  def get_best_fit(tracks, search_term)
    while true do
      term_at_start = tracks.select {|track| track["name"].gsub(/[^ \w\-]+/, "").downcase.start_with?(search_term.downcase) }
      if term_at_start.count > 0
        best_fit = term_at_start[0]
        break
      end

      term_included = tracks.select {|track| track["name"].gsub(/[^ \w\-]+/, "").downcase.include?(search_term.downcase) }
      if term_included.count > 0
        best_fit = term_included[0]
        break
      end
      best_fit = tracks[0]
    end
    return best_fit
  end

  def search_for_first_word(words)
    if exclusion_list.include?(words[0].strip.downcase) == false
      search_term = words.first
      results = search_results(search_term)
      result = results[:exact_matches].count == 0 ? get_best_fit(results[:tracks], search_term) : results[:exact_matches][0]
      @spotify_uris << result["uri"] if result != nil
    end
    y = 5
    y = (words.count - 1) if (words.count - 1) < 5
    return { x: y, remaining_words: words.drop(1)}
  end

  def get_spotify_tracks
    words = self.text.gsub(/[^ \w\-]+/, "").split("http")[0].split(" ")
    @spotify_uris = []
    x = 5
    x = words.count if words.count < 5
    until words.length == 0
      x > 1 ? search = search_for_first_x_words(words, x) : search = search_for_first_word(words)
      words = search[:remaining_words]
      x = search[:x]
    end
    return @spotify_uris
  end

  def spotify_playlist_build
    spotify_uris = get_spotify_tracks
    playlist_uri = @spotifyapi.create_spotify_playlist(@spotify_user, self.text, true)

    @spotifyapi.add_tracks_to_spotify_playlist(@spotify_user, playlist_uri, spotify_uris)
    url = "https://open.spotify.com/user/#{@spotify_user}/playlist/#{playlist_uri}"
    return {original_text: self.text,url: url}
  end

end
