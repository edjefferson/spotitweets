require './spotify_playlist_from_twitter_account'


session = SpotifyPlaylistFromTwitterAccount.new(ENV["SOURCE_ACCOUNT"],
                                                ENV["KEY"],
                                                ENV["SECRET"],
                                                ENV["ACCESS_TOKEN"],
                                                ENV["ACCESS_SECRET"],
                                                ENV["SPOTIFY_USER"],
                                                ENV["REFRESH_TOKEN"],
                                                ENV["SPOTIFY_KEY"],
                                                ENV["SPOTIFY_SECRET"])
if ARGV[0] == "fetch_last"
  session.last_tweets
  session.wait_for_tweets
else
  session.wait_for_tweets
end
