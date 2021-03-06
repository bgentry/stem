require 'spec_helper'

describe Stem::Family::Member do
  describe "attributes" do
    before { initialize_vars }

    subject { new_member }

    describe :family do
      it { should respond_to :family }
    end

    describe :sha1 do
      it { should respond_to :sha1 }
    end

    describe :source_ami do
      it { should respond_to :source_ami }
    end

    describe :time do
      it { should respond_to :time }
    end
  end

  describe :initialize do
    before do
      initialize_vars
      @family = "tea_styles"
    end

    it "should set the family" do
      new_member.family.should == @family
    end

    it "should set the source_ami if it's specified directly in the config" do
      ami_id = "ami-aaaabbbb"
      config = { "ami" => ami_id }
      new_member(:config => config).source_ami.should == ami_id
    end

    it "should set the source_ami if ami-name is specified in the config" do
      ami_id = "ami-11112222"
      config = { "ami-name" => "some-new-ami" }
      Stem::Image.should_receive(:named).with("some-new-ami").and_return(ami_id)
      member = new_member(:config => config)
      member.source_ami.should == ami_id
    end

    it "should raise an exception if no valid ami_id is found" do
      lambda { new_member(:config => {}) }.should raise_exception(ArgumentError)
    end

    it "should accept a sha1 instead of userdata" do
      new_member(:sha1 => @sha1).sha1.should == @sha1
    end

    it "should not calculate the sha1 if it was specified instead of userdata" do
      Stem::Family.should_not_receive(:image_hash)
      new_member(:sha1 => @sha1)
    end

    it "should calculate the sha1 from the config and userdata" do
      Stem::Family.should_receive(:image_hash).with(@config, @userdata).
        and_return(@sha1)
      new_member.sha1.should == @sha1
    end

    it "should set :time to Time.now.utc" do
      new_member.time.should == Time.now.utc
    end
  end

  describe :already_built? do
    before { initialize_vars }

    subject { new_member }

    it { should respond_to :already_built? }

    it "should check if the image is already built" do
      Stem::Image.should_receive(:tagged).
        with(:family => @family, :sha1 => @sha1).and_return([])
      subject.already_built?
    end

    it "should return false if the image is not already built" do
      Stem::Image.stub!(:tagged).and_return([])
      subject.already_built?.should == false
    end

    it "should return true if the image is already built" do
      Stem::Image.stub!(:tagged).and_return('ami-55557777')
      subject.already_built?.should == true
    end
  end

  describe :architecture do
    before { initialize_vars }

    subject { new_member }

    it { should respond_to :architecture }

    it "should call Stem::Image.describe with its source_ami" do
      Stem::Image.should_receive(:describe).with(subject.source_ami).
        and_return({ 'architecture' => 'x86_64' })
      subject.architecture
    end
  end

  describe :capture do
    before do
      initialize_vars
      @member = new_member
      @member.stub!(:architecture).and_return('x86_64')
    end

    subject { @member }

    it { should respond_to :capture }

    it "should call Stem::Image.create with its name and instance_id" do
      Stem::Image.should_receive(:create).
        with(subject.name, @instance_id)
      subject.capture(@instance_id)
    end

    it "should return the ami ID of the new image" do
      Stem::Image.stub!(:create).and_return(@ami_id)
      subject.capture(@instance_id).should == @ami_id
    end
  end

  describe :name do
    before do
      initialize_vars
      @member = new_member
      @member.stub!(:architecture).and_return('x86_64')
    end

    subject { @member }

    it { should respond_to :name }

    it "should return the family-timestamp without colons" do
      subject.name.
        should == [subject.family, subject.timestamp.gsub(':', '_'), subject.architecture].join('-')
    end
  end

  describe :tag do
    before do
      initialize_vars
      @member = new_member
      @ami_id = "ami-87654321"
    end

    subject { @member }

    it { should respond_to :tag }

    it "should call Stem::Tag::create with its ami_id and tags" do
      Stem::Tag.should_receive(:create).with(@ami_id,  @member.tags)
      @member.tag(@ami_id)
    end
  end

  describe :tags do
    before do
      initialize_vars
      @member = new_member
      @member.stub!(:architecture).and_return('x86_64')
    end

    subject { @member }

    it { should respond_to :tags }

    it "should return the family member tag hash" do
      subject.tags.should == {
        :created => subject.timestamp,
        :family => subject.family,
        :sha1 => subject.sha1,
        :source_ami => subject.source_ami
      }
    end

  end

  describe :timestamp do
    before { initialize_vars }

    subject { new_member }

    it { should respond_to :timestamp }

    it "should equal time.iso8601" do
      subject.timestamp.should == subject.time.iso8601
    end
  end

  describe :== do
    before { initialize_vars }

    subject { new_member }

    it { should respond_to :== }

    it "should return true if the 2nd object is the same but is missing userdata" do
      member2 = new_member
      member2.instance_variable_set(:@userdata, nil)
      subject.should == member2
    end

    it "should return true when comparing an object constructed with sha1 with one constructed with userdata" do
      member2 = new_member(:userdata => @userdata)
      member1 = new_member(:sha1 => @sha1)
      member1.should == member2
    end
  end

  def initialize_vars
    @ami_id = "ami-12345678"
    @config = { "ami" => @ami_id }
    @family = "tea_styles"
    @instance_id = "i-f00df00d"
    @sha1 = "dc8ec70bef72050c44edb973a36fffdf23cfada6"
    @userdata = "echo 'something useful'"
  end

  def new_member(opts = {})
    family = opts.delete(:family) || @family
    config = opts.delete(:config) || @config
    options = if opts[:sha1]
                { :sha1 => opts.delete(:sha1) }
              else
                { :userdata => opts.delete(:userdata) || @userdata }
              end
    Stem::Family::Member.new(family, config, options)
  end
end
