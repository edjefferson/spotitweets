session = SpotifyPlaylistFromTwitterAccount.new(ENV["source_account"],
                                                ENV["key"],
                                                ENV["secret"],
                                                ENV["access_token"],
                                                ENV["access_secret"],
                                                ENV["spotify_user"],
                                                ENV["refresh_token"],
                                                ENV["spotify_key"],
                                                ENV["spotify_secret"])
sesson.wait_for_tweets
