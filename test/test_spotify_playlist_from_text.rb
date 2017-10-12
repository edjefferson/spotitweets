require './lib/spotify_playlist_from_text'
require 'minitest/autorun'

class TestSpotifyPlaylistFromText < Minitest::Test


  def test_get_best_fit
    spotify_playlist_from_text = SpotifyPlaylistFromText.new(nil,nil,nil,nil,nil)
    search_term = "Egg"
    tracks_one  = [{"name" => "Big Bug" },
      {"name" => "Big Egg"},
      {"name" => "Egg Big"},
      {"name" => "Bug Big"}
    ]
    tracks_two  = [{"name" => "Big Bug" },
      {"name" => "Big Egg"},
      {"name" => "Bug Big"}
    ]
    assert_equal spotify_playlist_from_text.get_best_fit(tracks_one,search_term), {"name" => "Egg Big"}
    assert_equal spotify_playlist_from_text.get_best_fit(tracks_two,search_term), {"name" => "Big Egg"}
  end

end
