require './spotify_playlist_from_text'

text = ARGV[0]

test = SpotifyPlaylistFromText.new(text,ENV["SPOTIFY_USER"],
  ENV["REFRESH_TOKEN"],
  ENV["SPOTIFY_KEY"],
  ENV["SPOTIFY_SECRET"])


puts test.get_spotify_tracks
