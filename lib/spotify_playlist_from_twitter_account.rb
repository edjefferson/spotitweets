require 'twitter'
require './lib/spotify_playlist_from_text'

class SpotifyPlaylistFromTwitterAccount
  def initialize(source_account, key, secret, access_token, access_secret, spotify_user, refresh_token, spotify_key, spotify_secret)
    @client = Twitter::REST::Client.new do |config|
      config.consumer_key        = key
      config.consumer_secret     = secret
      config.access_token        = access_token
      config.access_token_secret = access_secret
    end

    @stream = Twitter::Streaming::Client.new do |config|
      config.consumer_key        = key
      config.consumer_secret     = secret
      config.access_token        = access_token
      config.access_token_secret = access_secret
    end
    @source_account = source_account
    @spotify_user = spotify_user
    @refresh_token = refresh_token
    @spotify_key = spotify_key
    @spotify_secret = spotify_secret
  end

  def tweet_text(original_text)
    if original_text.include?('http')
      return original_text.split("http")[0][0..91] + " http" + original_text.split("http")[1]
    else
      return original_text.split("http")[0][0..110]
    end
  end

  def tweet_to_playlist(tweet)
    spotify_playlist_from_text = SpotifyPlaylistFromText.new(tweet, @spotify_user, @refresh_token, @spotify_key, @spotify_secret)
    playlist = spotify_playlist_from_text.spotify_playlist_build
    tweet = tweet_text(playlist[:original_text]) + " " + playlist[:url]
    puts tweet
    @client.update(tweet)
  end

  def if_tweet(original_id, object)
    if object.is_a?(Twitter::Tweet) && object.user.id == original_id && object.to_h[:retweeted_status] == nil
      puts object.text
      tweet_to_playlist(object.text)
      puts "waiting for tweets"
    end
  end

  def start_streaming
    original_id = @client.user(@source_account).id
    @stream.filter(follow:"#{original_id}") { |object| if_tweet(original_id, object) }
  end

  def wait_for_tweets
    while true do
      begin
        puts "waiting for tweets"
        start_streaming
      rescue Exception => e
        puts e.backtrace
        raise
      end
    end
  end


  def last_tweets
    puts "getting recent tweets"
    original_id = @client.user(@source_account).id
    @client.user_timeline(@source_account)[0..1].each { |object| if_tweet(original_id, object) }
  end
end
