module Stem
  module Family
    class Member
      include Util
      attr_reader :family, :sha1, :source_ami, :time

      def initialize(family, config, userdata)
        aggregate_hash_options_for_ami!(config)
        @time = Time.now.utc
        @family = family
        @sha1 = Family.image_hash(config, userdata)
        @source_ami = config['ami']
        @userdata = userdata
      end

      def capture(instance_id)
        Stem::Image.create(name, instance_id, tags)
      end

      def name
        "#{family}-#{timestamp.gsub(':', '_')}"
      end

      def tags
        {
          :created => timestamp,
          :family => family,
          :sha1 => sha1,
          :source_ami => source_ami
        }
      end

      def timestamp
        time.iso8601
      end
    end
  end
end
