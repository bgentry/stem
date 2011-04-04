module Stem
  module Family
    class Member
      include Util
      attr_reader :family, :sha1, :source_ami, :time

      def initialize(family, config, options = {})
        aggregate_hash_options_for_ami!(config)
        @time = Time.now.utc
        @family = family
        userdata = options.delete(:userdata)
        @sha1 = if userdata
          Family.image_hash(config, userdata)
        elsif options[:sha1]
          options.delete(:sha1)
        else
          raise ArgumentError.new("Must specify either userdata or sha1")
        end
        @source_ami = config['ami']
      end

      def ==(member)
        [ :family, :sha1, :source_ami, :time ].map do |attribute|
          self.send(attribute) == member.send(attribute)
        end.all?
      end

      def already_built?
        !Stem::Image.tagged(:family => family, :sha1 => sha1).empty?
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
