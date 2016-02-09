require File.join(File.dirname(__FILE__), 'spec_helper')

describe BindLogAnalyzer do
  before :all do
    @db_params = YAML::load(File.open(File.join(File.dirname(__FILE__), '..', 'database.yml')))['database']

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

  it "can be instantiated without a logfile" do
    base = BindLogAnalyzer::Base.new(@db_params)
    expect(base.logfile).to be_nil
  end

  it "permit setting a logfile from initializer" do
    @base = BindLogAnalyzer::Base.new(@db_params, @filename)
    expect(@base.logfile).to eq(@filename)
  end

  it "should update the logfile name" do
    @base = BindLogAnalyzer::Base.new(@db_params, @filename)

    # Create a new dummy file
    @new_filename = 'new_test_file.log'
    doc = ''
    File.open(@new_filename, 'w') { |f| f.write(doc) } unless FileTest.exists?(@new_filename)

    @base.logfile = @new_filename
    expect(@base.logfile).to eq(@new_filename)

    # Delete the file
    File.delete(@new_filename)
  end

  it "shouldn't update the logfile name if it doesn't exist" do
    @base = BindLogAnalyzer::Base.new(@db_params, @filename)
    @base.logfile = 'unexisting_test_file'
    expect(@base.logfile).not_to eq('unexisting_test_file')
  end

  it "should correctly parse a line" do
    @base = BindLogAnalyzer::Base.new(@db_params, @filename)
    line = "28-Mar-2012 16:48:32.412 client 192.168.10.201#60303: query: google.com IN AAAA + (192.168.10.1)"
    test_line = {
      date: Time.local('2012','mar',28, 16, 48, 32),
      client: "192.168.10.201",
      query: "google.com",
      q_type: "AAAA",
      server: "192.168.10.1"
    }
    parsed_line = @base.parse_line(line)
    expect(parsed_line).to eq(test_line)
  end

  # it "should be connected after setup_db is called" do
  #   @base = BindLogAnalyzer::Base.new(@db_params, @filename)
  #   expect(@base.connected?).to be true
  # end

  it "should be possible to instantiate a Log class after BindLogAnalyzer::Base initialization" do
    @base = BindLogAnalyzer::Base.new(@db_params, @filename)
    log = Log.new
    expect(log.class).not_to be_instance_of(NilClass)
  end
end
