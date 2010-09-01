require 'test_helper'

class TestNetwork < Test::Unit::TestCase
  def test_make_post_through_connection
    Network::Connection.any_instance.expects(:post)
    Network.post('http://site.com/', "some data")
  end

  def test_make_get_throught_connection
    Network::Connection.any_instance.expects(:get)
    Network.get('http://site.com/', 'query=helo')
  end
end
