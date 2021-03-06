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
    tracks_three  = [{"name" => "Big Bug" },
      {"name" => "Bug Big"}
    ]
    tracks_four = []
    assert_equal spotify_playlist_from_text.get_best_fit(tracks_one,search_term), {"name" => "Egg Big"}
    assert_equal spotify_playlist_from_text.get_best_fit(tracks_two,search_term), {"name" => "Big Egg"}
    assert_equal spotify_playlist_from_text.get_best_fit(tracks_three,search_term), {"name" => "Big Bug"}
    assert_nil spotify_playlist_from_text.get_best_fit(tracks_four,search_term)
  end

end
