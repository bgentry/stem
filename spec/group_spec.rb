require 'spec_helper'

describe Stem::Group do
  it { should respond_to :rules }

  describe :rules do
    use_vcr_cassette

    it "should call :get with the group name" do
      Stem::Group.should_receive(:get).with('raven')
      Stem::Group::rules('raven')
    end

    it "should return nil if :get returns nil" do
      Stem::Group.stub(:get).and_return(nil)
      Stem::Group::rules('raven').should == nil
    end

    it "should return an empty array if the group has no rules" do
      Stem::Group::rules('new_group').should == []
    end
# [{"ipProtocol"=>"icmp", "fromPort"=>"-1", "toPort"=>"-1", "groups"=>nil, "ipRanges"=>[{"cidrIp"=>"0.0.0.0/0"}]}] 

    context "icmp rules" do
      it "should return the correct format for a single icmp rule" do
        Stem::Group::rules('icmp_group').should == [ 'icmp://0.0.0.0/0' ]
      end

      it "should return the correct format for a single intergroup icmp rule" do
        Stem::Group::rules('icmp_intergroup').should == [ 'icmp://default@646412345678' ]
      end

      it "should return the correct rules for multiple icmp ip rules and intergroup rules" do
        Stem::Group::rules('icmp_multirule').should == [
          'icmp://0.0.0.0/0',
          'icmp://10.0.0.0/32',
          'icmp://default@646412345678',
          'icmp://core@646412345678'
        ]
      end
    end
  end
end
