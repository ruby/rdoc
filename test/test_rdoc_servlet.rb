require 'rdoc/test_case'

class TestRDocServlet < RDoc::TestCase

  def setup
    super

    server = {}
    def server.mount(*) end

    @stores = {}

    @s = RDoc::Servlet.new server, @stores

    @req = WEBrick::HTTPRequest.new :Logger => nil
    @res = WEBrick::HTTPResponse.new :HTTPVersion => '1.0'

    def @req.path= path
      instance_variable_set :@path, path
    end

    RDoc::RI::Paths.instance_variable_set \
      :@gemdirs, %w[/nonexistent/gems/example-1.0/ri]
  end

  def teardown
    super

    RDoc::RI::Paths.instance_variable_set :@gemdirs, nil
  end

  def test_do_GET_list
    @req.path = '/'

    @s.do_GET @req, @res

    assert_match %r%<li class="folder"><a href="ruby/">Ruby Documentation</a>%,
                 @res.body
  end

end

