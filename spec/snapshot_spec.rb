require 'spec_helper'

describe Stem::Snapshot do
  it { should respond_to :list }

  describe :list do
    use_vcr_cassette

    it "should call swirl with DescribeSnapshots for the current owner" do
      subject.swirl.should_receive(:call).
        with("DescribeSnapshots", "Owner" => "self").and_return({})
      Stem::Snapshot.list
    end

    it "should return an empty array when there are no snapshots" do
      subject.swirl.stub(:call).and_return({'snapshotSet' => nil})
      Stem::Snapshot.list.should == []
    end

    it "should return an array of snapshot IDs" do
      list = Stem::Snapshot.list
      list.should be_an(Array)
    end

    it "should return the snapshot IDs from the swirl response" do
      result = {'snapshotSet' => [
        {'snapshotId' => 'snap-1234abcd'},
        {'snapshotId' => 'snap-5678efgh'}
      ]}
      subject.swirl.stub(:call).and_return(result)
      Stem::Snapshot.list.should == ['snap-1234abcd', 'snap-5678efgh']
    end
  end

  it { should respond_to :destroy }

  describe :destroy do
    use_vcr_cassette

    it "should call swirl with DeleteSnapshot and the snapshot id" do
      snapshot_id = 'snap-1234abcd'
      subject.swirl.should_receive(:call).
        with("DeleteSnapshot", "SnapshotId" => snapshot_id)
      Stem::Snapshot.destroy(snapshot_id)
    end
  end
end
