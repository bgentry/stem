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

    it "should calculate the sha1 from the config and userdata" do
      Stem::Family.should_receive(:image_hash).with(@config, @userdata).
        and_return(@sha1)
      new_member.sha1.should == @sha1
    end

    it "should set :time to Time.now.utc" do
      new_member.time.should == Time.now.utc
    end
  end

  describe :capture do
    before { initialize_vars }

    subject { new_member }

    it { should respond_to :capture }

    it "should call Stem::Image.create with its name, the instance_id, and tags" do
      Stem::Image.should_receive(:create).
        with(subject.name, @instance_id, subject.tags)
      subject.capture(@instance_id)
    end

    it "should return the ami ID of the new image" do
      Stem::Image.stub!(:create).and_return(@ami_id)
      subject.capture(@instance_id).should == @ami_id
    end
  end

  describe :name do
    before { initialize_vars }

    subject { new_member }

    it { should respond_to :name }

    it "should return the family-timestamp without colons" do
      subject.name.
        should == [subject.family, subject.timestamp.gsub(':', '_')].join('-')
    end
  end

  describe :tags do
    before { initialize_vars }

    subject { new_member }

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
    userdata = opts.delete(:userdata) || @userdata
    Stem::Family::Member.new(family, config, userdata)
  end
end
