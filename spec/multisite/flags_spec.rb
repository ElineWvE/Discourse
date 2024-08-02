# frozen_string_literal: true

RSpec.describe "Custom flags in multisite", type: :multisite do
  describe "#all_flags" do
    use_redis_snapshotting

    it "does not share flag definitions between sites" do
      flag_1 = Flag.create!(name: "test flag 1", position: 99, applies_to: ["Post"])

      test_multisite_connection("second") do
        flag_2 = Flag.create!(name: "test flag 2", position: 99, applies_to: ["Post"])
        PostActionType.expire_cache
        expect(PostActionType.all_flags.last).to eq(flag_2)
      end

      PostActionType.expire_cache
      expect(PostActionType.all_flags.last).to eq(flag_1)
    end
  end
end
