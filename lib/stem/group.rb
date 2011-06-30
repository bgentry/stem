module Stem
  module Group
    include Util
    extend self

    ## Example Rules

    ## icmp://1.2.3.4/32
    ## icmp://1.2.3.4/32:8-0
    ## icmp://GroupName
    ## icmp://GroupName@UserId
    ## icmp://@UserId
    ## tcp://0.0.0.0/0:22
    ## tcp://0.0.0.0/0:22-23
    ## tcp://10.0.0.0/8:    (this imples 0-65535
    ## udp://GroupName:4567
    ## udp://GroupName@UserID:4567-9999

    def get(name)
        swirl.call("DescribeSecurityGroups", "GroupName.1" => name)["securityGroupInfo"].first
      rescue Swirl::InvalidRequest => e
        raise e unless e.message =~ /The security group '\S+' does not exist/
        nil
    end

    def create(name, rules = nil, description = nil)
        create!(name, rules, description)
        true
      rescue Swirl::InvalidRequest => e
        raise e unless e.message =~ /The security group '\S+' already exists/
        false
    end

    def create!(name, rules = nil, description = nil)
      description ||= name
      swirl.call "CreateSecurityGroup",  "GroupName" => name, "GroupDescription" => description
      auth(name, rules) if rules
    end

    def destroy(name)
        destroy!(name)
        true
      rescue Swirl::InvalidRequest => e
        puts "===> #{e.class}"
        puts "===> #{e.message}"
        puts "#{e.backtrace.join("\n")}"
        false
    end

    def destroy!(name)
      swirl.call "DeleteSecurityGroup", "GroupName" => name
    end

    def auth(name, rules)
      index = 0
      args = rules.inject({"GroupName" => name}) do |i,rule|
          index += 1;
          rule_hash = gen_authorize(index, rule)
          i.merge(rule_hash)
      end
      swirl.call "AuthorizeSecurityGroupIngress", args
    end

    def revoke(name, rules)
      index = 0
      args = rules.inject({"GroupName" => name}) do |i,rule|
          index += 1;
          rule_hash = gen_authorize(index, rule)
          i.merge(rule_hash)
      end
      swirl.call "RevokeSecurityGroupIngress", args
    end

    def rules(name)
      group = get(name)
      return unless group
      perms = group["ipPermissions"] || []
      list = []
      perms.map do |h|
        h['ipRanges'].each do |ipr|
          rule = "#{h['ipProtocol']}://#{ipr['cidrIp']}"
          list << [ rule, parse_rule_ports(h) ].join
        end if h['ipRanges']
        h['groups'].each do |group|
          rule = "#{h['ipProtocol']}://#{group['groupName']}@#{group['userId']}"
          list << [ rule, parse_rule_ports(h) ].join
        end if h['groups']
      end
      list
    end

    def gen_authorize_target(index, target)
      if target =~ /^\d+\.\d+\.\d+.\d+\/\d+$/
        { "IpPermissions.#{index}.IpRanges.1.CidrIp"  => target }
      elsif target =~ /^(.+)@(\w+)$/
        { "IpPermissions.#{index}.Groups.1.GroupName" => $1,
          "IpPermissions.#{index}.Groups.1.UserId"    => $2 }
      elsif target =~ /^@(\w+)$/
        { "IpPermissions.#{index}.Groups.1.UserId"    => $1 }
      else
        { "IpPermissions.#{index}.Groups.1.GroupName" => target }
      end
    end

    def gen_authorize_ports(index, ports)
      if ports =~ /^(\d+)-(\d+)$/
        { "IpPermissions.#{index}.FromPort"           => $1,
          "IpPermissions.#{index}.ToPort"             => $2 }
      elsif ports =~ /^(\d+)$/
        { "IpPermissions.#{index}.FromPort"           => $1,
          "IpPermissions.#{index}.ToPort"             => $1 }
      elsif ports == ""
        { "IpPermissions.#{index}.FromPort"           => "0",
          "IpPermissions.#{index}.ToPort"             => "65535" }
      else
        raise "bad ports: #{rule}"
      end
    end

    def gen_authorize(index, rule)
      if rule =~ /icmp:\/\/([^:]+)(?::(.*))?/
        auth = { "IpPermissions.#{index}.IpProtocol"         => "icmp",
          "IpPermissions.#{index}.FromPort"           => "-1",
          "IpPermissions.#{index}.ToPort"             => "-1" }.merge(gen_authorize_target(index,$1))
        $2 ? auth.merge(gen_authorize_ports(index, $2)) : auth
      elsif rule =~ /(tcp|udp):\/\/(.*):(.*)/
        { "IpPermissions.#{index}.IpProtocol"         => $1 }.merge(gen_authorize_target(index,$2)).merge(gen_authorize_ports(index,$3))
      else
        raise "bad rule: #{rule}"
      end
    end

    def parse_rule_ports(rule)
      if rule['ipProtocol'] == 'icmp' && rule['fromPort'] == '-1' && rule['toPort'] == '-1'
        ""
      elsif rule['fromPort'] == '0' && rule['toPort'] == '65535'
        ":"
      else
        ":#{[ rule['fromPort'], rule['toPort']].uniq.join('-')}"
      end
    end
  end
end

