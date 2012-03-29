require File.join(File.dirname(__FILE__), 'spec_helper')

describe BindLogAnalyzer do
  before :all do
    # Create a test logfile
    @filename = 'test_file.log'
    @doc = <<EOF
28-Mar-2012 16:48:32.411 client 192.168.10.37#60303: query: github.com IN A + (192.168.10.1)
28-Mar-2012 16:48:32.412 client 192.168.10.201#60303: query: google.com IN AAAA + (192.168.10.1)
28-Mar-2012 16:48:32.898 client 192.168.10.114#53309: query: www.nasa.gov IN A + (192.168.10.1)
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
    line = "28-Mar-2012 16:48:32.412 client 192.168.10.201#60303: query: google.com IN AAAA + (192.168.10.1)"
    test_line = {
      date: "28-Mar-2012",
      time: "16:48:32",
      client: "192.168.10.201",
      query: "google.com",
      type: "AAAA",
      server: "192.168.10.1"
    }
    parsed_line = @base.parse_line(line)
    parsed_line.should == test_line
  end

  it "should be connected after connect() is called" do
    @base.connect
    @base.connected?.should == true
  end
end