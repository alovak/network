require 'test_helper'

class TestNetwork < Test::Unit::TestCase
  def test_make_post_through_connection
    Network::Connection.any_instance.expects(:post)
    Network.post('http://site.com/', "some data")
  end
end
