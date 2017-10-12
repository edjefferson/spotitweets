require './lib/spotify_playlist_from_twitter_account'

text = ARGV[0]

test = SpotifyPlaylistFromText.new(text,ENV["SPOTIFY_USER"],
  ENV["REFRESH_TOKEN"],
  ENV["SPOTIFY_KEY"],
  ENV["SPOTIFY_SECRET"])


puts test.spotify_playlist_build
