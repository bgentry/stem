module Stem
  module Image
    include Util
    extend self

    def create name, instance, tags = {}
      unless tags == {}
        raise Stem::Deprecated.new "Tags should be created separately due to AWS eventual consistency issues"
      end
      swirl.call("CreateImage", "Name" => name, "InstanceId" => instance)["imageId"]
    end

    def deregister image
      swirl.call("DeregisterImage", "ImageId" => image)["return"]
    end

    def list
      swirl.call("DescribeImages", "Owner" => "self")["imagesSet"].map do |i|
        i["imageId"]
      end
    end

    def named name
      opts = get_filter_opts("name" => name).merge("Owner" => "self")
      i = swirl.call("DescribeImages", opts)["imagesSet"].first
      i ? i["imageId"] : nil
    end

    def tagged tags
      return if tags.empty?
      opts = tags_to_filter(tags).merge("Owner" => "self")
      res = swirl.call("DescribeImages", opts)['imagesSet']
      res ? res.map {|image| image['imageId'] } : []
    end

    def describe_tagged tags
      opts = tags_to_filter(tags).merge("Owner" => "self")
      images = swirl.call("DescribeImages", opts)["imagesSet"]
      if images
        images.each {|image| image["tags"] = tagset_to_hash(image["tagSet"]) }
        images
      else
        []
      end
    end

    def describe image
      swirl.call("DescribeImages", "ImageId" => image)["imagesSet"][0]
    rescue Swirl::InvalidRequest => e
      raise e unless e.message =~ /does not exist/
      nil
    end
  end
end

