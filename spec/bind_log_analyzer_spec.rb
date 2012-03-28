require File.join(File.dirname(__FILE__), 'spec_helper')

describe BindLogAnalyzer do
  before :all do
    # Create a test logfile
    @filename = 'test_file.log'
    @doc = <<EOF
28-Mar-2012 15:47:46.240 client 127.0.0.1#60571: query: web.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:46.320 client 127.0.0.1#36756: query: web.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:46.330 client 127.0.0.1#46627: query: web.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:46.448 client 127.0.0.1#35634: query: web.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:46.462 client 127.0.0.1#59687: query: web.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:47.474 client 127.0.0.1#48397: query: jboss2.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:47.648 client 127.0.0.1#58440: query: jboss2.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:47.902 client 127.0.0.1#44378: query: jboss2.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:47:47.911 client 127.0.0.1#58480: query: jboss2.drwolf.it IN A + (127.0.0.1)
28-Mar-2012 15:48:07.097 client 192.168.100.16#46921: query: 1.100.168.192.in-addr.arpa IN PTR + (192.168.100.1)
EOF
    
    File.open(@filename, 'w') { |f| f.write(@doc) } unless FileTest.exists?(@filename)
  end

  after :all do
    #delete the test logfile
    File.delete(@filename) if FileTest.exists?(@filename)
  end

  before :each do
    @base = BindLogAnalyzer::Base.new(@filename)
  end

  it "can be instantiated without a logfile" do
    base = BindLogAnalyzer::Base.new
    base.logfile.should == nil
  end

  it "permit setting a logfile from initializer" do
    @base.logfile.should == @filename
  end

  it "should update the logfile name" do

    # Create a new dummy file
    @new_filename = 'new_test_file.log'
    doc = ''
    File.open(@new_filename, 'w') { |f| f.write(doc) } unless FileTest.exists?(@new_filename)

    @base.logfile = @new_filename
    @base.logfile.should == @new_filename

    # Delete the file
    File.delete(@new_filename)
  end

  it "shouldn't update the logfile name if it doesn't exist" do
    @base.logfile = 'unexisting_test_file'
    @base.logfile.should_not == 'unexisting_test_file'
  end

  it "should correctly parse a line" do
    line = "28-Mar-2012 15:47:46.240 client 127.0.0.1#60571: query: web.drwolf.it IN A + (127.0.0.1)"
    test_line = {
      date: "28-Mar-2012",
      time: "15:47:46",
      client: "127.0.0.1",
      query: "web.drwolf.it",
      type: "A",
      server: "127.0.0.1"
    }
    parsed_line = @base.parse_line(line)
    parsed_line.should == test_line
  end
end