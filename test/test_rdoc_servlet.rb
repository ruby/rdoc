require 'rdoc/test_case'

class TestRDocServlet < RDoc::TestCase

  def setup
    super

    @tmpdir = File.join Dir.tmpdir, "test_rdoc_servlet_#{$$}"

    server = {}
    def server.mount(*) end

    @stores = {}

    @s = RDoc::Servlet.new server, @stores

    @req = WEBrick::HTTPRequest.new :Logger => nil
    @res = WEBrick::HTTPResponse.new :HTTPVersion => '1.0'

    def @req.path= path
      instance_variable_set :@path, path
    end

    @base = File.join @tmpdir, 'base'
    @orig_base = RDoc::RI::Paths::BASE
    RDoc::RI::Paths::BASE.replace @base

    RDoc::RI::Paths.instance_variable_set \
      :@gemdirs, %w[/nonexistent/gems/example-1.0/ri]
  end

  def teardown
    super

    FileUtils.rm_rf @tmpdir

    RDoc::RI::Paths::BASE.replace @orig_base
    RDoc::RI::Paths.instance_variable_set :@gemdirs, nil
  end

  def test_do_GET_list
    system = File.join @base, 'system'
    FileUtils.mkdir_p system

    store = RDoc::Store.new system
    store.save

    @req.path = '/'

    @s.do_GET @req, @res

    assert_match %r%<a href="ruby/">Ruby Documentation</a>%,
                 @res.body
  end

end

