module Stem
  module Snapshot
    include Util
    extend self

    def list
      result = swirl.call("DescribeSnapshots", "Owner" => "self")['snapshotSet'] || []
      result.map {|h| h['snapshotId'] }
    end

    def destroy(snapshot_id)
      swirl.call("DeleteSnapshot", "SnapshotId" => snapshot_id)
    end
  end
end


