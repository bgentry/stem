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

    context "tcp rules" do
      it "should return the correct format for a tcp cidr rule with no ports" do
        Stem::Group.stub(:get).and_return({
          'ipPermissions' => [{
         "ipProtocol" => "tcp",
          "fromPort" => nil,
          "toPort" => nil,
          "groups" => nil,
          "ipRanges" => [{"cidrIp" => "0.0.0.0/0"}]
        }]})
        Stem::Group::rules('tcp_group').should == [ 'tcp://0.0.0.0/0:' ]
      end

      it "should return the correct format for a tcp cidr rule with 1 port" do
        Stem::Group.stub(:get).and_return({
          'ipPermissions' => [{
         "ipProtocol" => "tcp",
          "fromPort" => "22",
          "toPort" => "22",
          "groups" => nil,
          "ipRanges" => [{"cidrIp" => "0.0.0.0/0"}]
        }]})
        Stem::Group::rules('tcp_group').should == [ 'tcp://0.0.0.0/0:22' ]
      end

      it "should return the correct format for a tcp cidr rule with 2 ports" do
        Stem::Group.stub(:get).and_return({
          'ipPermissions' => [{
            "ipProtocol" => "tcp",
            "fromPort" => "5000",
            "toPort" => "6000",
            "groups" => nil,
            "ipRanges" => [{"cidrIp" => "0.0.0.0/0"}]
          }]
        })
        Stem::Group::rules('tcp_group').should == [ 'tcp://0.0.0.0/0:5000-6000' ]
      end

      it "should return the correct format for a tcp group rule with all ports enabled" do
        Stem::Group.stub(:get).and_return({
          'ipPermissions' => [{
            "ipProtocol" => "tcp",
            "fromPort" => "0",
            "toPort" => "65535",
            "groups" => [{"userId" => "123456789", "groupName" => "default"}],
            "ipRanges" => nil
          }]
        })
        Stem::Group::rules('tcp_group').should == [ 'tcp://default@123456789:' ]
      end

      it "should return the correct format for a tcp group rule with 1 port" do
        Stem::Group.stub(:get).and_return({
          'ipPermissions' => [{
            "ipProtocol" => "tcp",
            "fromPort" => "22",
            "toPort" => "22",
            "groups" => [{"userId" => "123456789", "groupName" => "default"}],
            "ipRanges" => nil
          }]
        })
        Stem::Group::rules('tcp_group').should == [ 'tcp://default@123456789:22' ]
      end
    end

    it "should return the correct rules for an assortment of rules" do
      Stem::Group.stub(:get).and_return({
        'ipPermissions' => [{
          "ipProtocol" => "icmp",
          "groups" => nil,
          "ipRanges" => [{ "cidrIp" => "0.0.0.0/0" }]
        }, {
          "ipProtocol" => "tcp",
          "groups" => [{ "userId" => "123456789", "groupName" => "default" }],
          "fromPort" => "0",
          "toPort" => "65535",
          "ipRanges" => nil
        }, {
          "ipProtocol" => "tcp",
          "groups" => nil,
          "fromPort" => "443",
          "toPort" => "443",
          "ipRanges" => [{ "cidrIp" => "10.10.10.10/16" }]
        }, {
          "ipProtocol" => "udp",
          "groups" => [{
            "userId" => "123456789",
            "groupName" => "zealot"
          }, {
            "userId" => "987654321",
            "groupName" => "raven"
          }],
          "fromPort" => '30',
          "toPort" => '80',
          "ipRanges" => nil
        }]
      })
      Stem::Group::rules('all_group').should == [
        'icmp://0.0.0.0/0',
        'tcp://default@123456789:',
        "tcp://10.10.10.10/16:443",
        'udp://zealot@123456789:30-80',
        'udp://raven@987654321:30-80'
      ]
    end
  end
end
