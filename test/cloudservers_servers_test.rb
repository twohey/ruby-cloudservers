$:.unshift File.dirname(__FILE__)
require 'test_helper'
require 'tempfile'

class CloudServersServersTest < Test::Unit::TestCase

  include TestConnection

  def setup
    @conn=get_test_connection
  end
  
  def test_list_servers

    response = mock()
    response.stubs(:code => "200", :body => fixture('list_servers.json'))

    @conn.stubs(:csreq).returns(response)
    servers=@conn.list_servers

    assert_equal 2, servers.size
    assert_equal 1234, servers[0][:id]
    assert_equal "sample-server", servers[0][:name]

  end

  def test_get_server

    server=get_test_server
    assert_equal "sample-server", server.name
    assert_equal 2, server.imageId
    assert_equal 1, server.flavorId
    assert_equal "e4d909c290d0fb1ca068ffaddf22cbd0", server.hostId
    assert_equal "BUILD", server.status
    assert_equal 60, server.progress
    assert_equal "67.23.10.132", server.addresses[:public][0]
    assert_equal "67.23.10.131", server.addresses[:public][1]
    assert_equal "10.176.42.16", server.addresses[:private][0]

  end

  def test_share_ip

    server=get_test_server
    response = mock()
    response.stubs(:code => "200")

    @conn.stubs(:csreq).returns(response)

    assert server.share_ip(:sharedIpGroupId => 100, :ipAddress => "67.23.10.132")
  end

  def test_share_ip_requires_shared_ip_group_id

    server=get_test_server

    assert_raises(CloudServers::Exception::MissingArgument) do
      assert server.share_ip(:ipAddress => "67.23.10.132")
    end

  end

  def test_share_ip_requires_ip_address

    server=get_test_server

    assert_raises(CloudServers::Exception::MissingArgument) do
      assert server.share_ip(:sharedIpGroupId => 100)
    end

  end

  def test_unshare_ip

    server=get_test_server
    response = mock()
    response.stubs(:code => "200")

    @conn.stubs(:csreq).returns(response)

    assert server.unshare_ip(:ipAddress => "67.23.10.132")

  end

  def test_unshare_ip_requires_ip_address

    server=get_test_server

    assert_raises(CloudServers::Exception::MissingArgument) do
      assert server.share_ip({})
    end

  end

  def test_create_server_requires_name

    assert_raises(CloudServers::Exception::MissingArgument) do
        @conn.create_server(:imageId => 2, :flavorId => 2)
    end

  end

  def test_create_server_requires_image_id

    assert_raises(CloudServers::Exception::MissingArgument) do
        @conn.create_server(:name => "test1", :flavorId => 2)
    end

  end

  def test_create_server_requires_flavor_id

    assert_raises(CloudServers::Exception::MissingArgument) do
        @conn.create_server(:name => "test1", :imageId => 2)
    end

  end

  def test_create_server_with_local_file_personality

    response = mock()
    response.stubs(:code => "200", :body => fixture('create_server.json'))
    @conn.stubs(:csreq).returns(response)

    tmp = Tempfile.open('ruby_cloud_servers')
    tmp.write("hello")
    tmp.flush

    server = @conn.create_server(:name => "sample-server", :imageId => 2, :flavorId => 2, :metadata => {'Racker' => 'Fanatical'}, :personality => {tmp.path => '/root/tmp.jpg'})

    assert_equal "blah", server.adminPass

  end

  def test_create_server_with_personalities

    response = mock()
    response.stubs(:code => "200", :body => fixture('create_server.json'))
    @conn.stubs(:csreq).returns(response)

    server = @conn.create_server(:name => "sample-server", :imageId => 2, :flavorId => 2, :metadata => {'Racker' => 'Fanatical'}, :personality => [{:path => '/root/hello.txt', :contents => "Hello there!"}, {:path => '/root/.ssh/authorized_keys', :contents => ""}])

    assert_equal "blah", server.adminPass

  end

  def test_too_many_personalities

    personalities=[
        {:path => "/tmp/test1.txt", :contents => ""},
        {:path => "/tmp/test2.txt", :contents => ""},
        {:path => "/tmp/test3.txt", :contents => ""},
        {:path => "/tmp/test4.txt", :contents => ""},
        {:path => "/tmp/test5.txt", :contents => ""},
        {:path => "/tmp/test6.txt", :contents => ""}
    ]

    assert_raises(CloudServers::Exception::TooManyPersonalityItems) do
        @conn.create_server(:name => "sample-server", :imageId => 2, :flavorId => 2, :metadata => {'Racker' => 'Fanatical'}, :personality => personalities)
    end

  end

private
  def get_test_server

    response = mock()
    response.stubs(:code => "200", :body => fixture('test_server.json'))

    @conn=get_test_connection

    @conn.stubs(:csreq).returns(response)
    return @conn.server(1234) 

  end

end
