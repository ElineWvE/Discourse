# frozen_string_literal: true

require 'rails_helper'

describe CategorySerializer do
  fab!(:user) { Fabricate(:user) }
  fab!(:admin) { Fabricate(:admin) }
  fab!(:group) { Fabricate(:group) }
  fab!(:category) { Fabricate(:category, reviewable_by_group_id: group.id) }

  it "includes the reviewable by group name if enabled" do
    SiteSetting.enable_category_group_moderation = true
    json = described_class.new(category, scope: Guardian.new, root: false).as_json
    expect(json[:reviewable_by_group_name]).to eq(group.name)
  end

  it "doesn't include the reviewable by group name if disabled" do
    SiteSetting.enable_category_group_moderation = false
    json = described_class.new(category, scope: Guardian.new, root: false).as_json
    expect(json[:reviewable_by_group_name]).to be_blank
  end

  it "includes custom fields" do
    json = described_class.new(category, scope: Guardian.new, root: false).as_json
    expect(json[:custom_fields]).to be_empty

    category.custom_fields["enable_marketplace"] = true
    category.save_custom_fields

    json = described_class.new(category, scope: Guardian.new, root: false).as_json
    expect(json[:custom_fields]).to be_present
  end

  it "does not include the default notification level when there is no user" do
    json = described_class.new(category, scope: Guardian.new, root: false).as_json
    expect(json.key?(:notification_level)).to eq(false)
  end

  describe "user notification level" do
    it "includes the user's notification level" do
      CategoryUser.set_notification_level_for_category(user, NotificationLevels.all[:watching], category.id)
      json = described_class.new(category, scope: Guardian.new(user), root: false).as_json
      expect(json[:notification_level]).to eq(NotificationLevels.all[:watching])
    end
  end

  describe '#group_permissions' do
    context "category without group permissions configured" do
      it "returns the right category group permissions for an anon user" do
        json = described_class.new(category, scope: Guardian.new, root: false).as_json

        expect(json[:group_permissions]).to eq([
          { permission_type: CategoryGroup.permission_types[:full], group_name: Group[:everyone]&.name }
        ])
      end
    end

    context "category with group permissions configured" do
      fab!(:private_group) { Fabricate(:group, visibility_level: Group.visibility_levels[:staff]) }

      fab!(:user_group) do
        Fabricate(:group, visibility_level: Group.visibility_levels[:members]).tap do |g|
          g.add(user)
        end
      end

      before do
        category.set_permissions(
          :everyone => :readonly,
          group.name => :readonly,
          user_group.name => :full,
          private_group.name => :full,
        )

        category.save!
      end

      it "returns the right category group permissions for an anon user" do
        json = described_class.new(category, scope: Guardian.new, root: false).as_json

        expect(json[:group_permissions]).to contain_exactly(
          { permission_type: CategoryGroup.permission_types[:readonly], group_name: group.name },
        )
      end

      it "returns the right category group permissions for a regular user" do
        json = described_class.new(category, scope: Guardian.new(user), root: false).as_json

        expect(json[:group_permissions]).to contain_exactly(
          { permission_type: CategoryGroup.permission_types[:readonly], group_name: group.name },
          { permission_type: CategoryGroup.permission_types[:full], group_name: user_group.name },
        )
      end

      it "returns the right category group permission for a staff user" do
        json = described_class.new(category, scope: Guardian.new(admin), root: false).as_json

        expect(json[:group_permissions]).to contain_exactly(
          { permission_type: CategoryGroup.permission_types[:readonly], group_name: group.name },
          { permission_type: CategoryGroup.permission_types[:full], group_name: private_group.name },
          { permission_type: CategoryGroup.permission_types[:full], group_name: user_group.name }
        )
      end
    end
  end

  describe "available groups" do
    it "not included for a regular user" do
      json = described_class.new(category, scope: Guardian.new(user), root: false).as_json
      expect(json[:available_groups]).to eq(nil)
    end

    it "included for an admin" do
      json = described_class.new(category, scope: Guardian.new(admin), root: false).as_json
      expect(json[:available_groups]).to eq(Group.order(:name).pluck(:name) - ['everyone'])
    end
  end
end
