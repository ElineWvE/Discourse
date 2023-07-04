# frozen_string_literal: true

RSpec.describe "Exports", type: :system do
  fab!(:admin) { Fabricate(:admin) }
  let(:csv_export_pm_page) { PageObjects::Pages::CSVExportPM.new }

  before do
    Jobs.run_immediately!
    sign_in(admin)
  end

  after { Downloads.clear }

  context "with user list" do
    fab!(:group1) { Fabricate(:group) }
    fab!(:group2) { Fabricate(:group) }
    fab!(:user) do
      Fabricate(
        :user,
        title: "dr",
        last_seen_at: Time.now,
        last_posted_at: Time.now,
        last_emailed_at: Time.now,
        approved: true,
        suspended_at: Time.now,
        suspended_till: Time.now,
        silenced_till: Time.now,
        admin: true,
        moderator: true,
        staged: true,
        group_ids: [group1.id, group2.id],
      )
    end
    let(:second_email) { "second_email@discourse.org" }
    let(:third_email) { "third_email@discourse.org" }

    before do
      user.user_emails.create!(email: second_email)
      user.user_emails.create!(email: third_email)

      user.user_stat.topics_entered = 111
      user.user_stat.posts_read_count = 112
      user.user_stat.time_read = 113
      user.user_stat.topic_count = 114
      user.user_stat.post_count = 115
      user.user_stat.likes_given = 116
      user.user_stat.likes_received = 117
      user.user_stat.save!

      user.user_profile.location = "Tbilisi"
      user.user_profile.website = "https://www.discourse.org"
      user.user_profile.views = 5
      user.user_profile.save!
    end

    it "exports data" do
      visit "admin/users/list/active"
      click_button "Export"
      visit "/u/#{admin.username}/messages"
      click_link "[User List] Data export complete"

      exported_data = csv_export_pm_page.download_and_extract

      expect(exported_data[0]).to eq(
        %w[
          id
          name
          username
          email
          title
          created_at
          last_seen_at
          last_posted_at
          last_emailed_at
          trust_level
          approved
          suspended_at
          suspended_till
          silenced_till
          active
          admin
          moderator
          ip_address
          staged
          secondary_emails
          topics_entered
          posts_read_count
          time_read
          topic_count
          post_count
          likes_given
          likes_received
          location
          website
          views
          group_names
        ],
      )

      expect(exported_data.length).to be(5)

      exported_admin = exported_data[4]
      time_format = "%Y-%m-%d %k:%M:%S UTC"
      expect(exported_admin).to eq(
        [
          user.id.to_s,
          user.name,
          user.username,
          user.email,
          user.title,
          user.created_at.strftime(time_format),
          user.last_seen_at.strftime(time_format),
          user.last_posted_at.strftime(time_format),
          user.last_emailed_at.strftime(time_format),
          user.trust_level.to_s,
          user.approved.to_s,
          user.suspended_at.strftime(time_format),
          user.suspended_till.strftime(time_format),
          user.silenced_till.strftime(time_format),
          user.active.to_s,
          user.admin.to_s,
          user.moderator.to_s,
          user.ip_address.to_s,
          user.staged.to_s,
          "#{second_email};#{third_email}",
          user.user_stat.topics_entered.to_s,
          user.user_stat.posts_read_count.to_s,
          user.user_stat.time_read.to_s,
          user.user_stat.topic_count.to_s,
          user.user_stat.post_count.to_s,
          user.user_stat.likes_given.to_s,
          user.user_stat.likes_received.to_s,
          user.user_profile.location,
          user.user_profile.website,
          user.user_profile.views.to_s,
          "#{group1.name};#{group2.name}",
        ],
      )
    end
  end

  context "with stuff actions log" do
    fab!(:user_history) do
      Fabricate(
        :user_history,
        acting_user: admin,
        action: UserHistory.actions[:change_site_setting],
        subject: "default_trust_level",
        details: "details",
        context: "context",
      )
    end

    it "exports data" do
      visit "admin/logs/staff_action_logs"
      click_button "Export"

      visit "/u/#{admin.username}/messages"
      click_link "[Staff Action] Data export complete"
      exported_data = csv_export_pm_page.download_and_extract

      expect(exported_data[0]).to eq(%w[staff_user action subject created_at details context])

      exported_action = exported_data.last
      time_format = "%Y-%m-%d %k:%M:%S UTC"
      expect(exported_action).to eq(
        [
          user_history.acting_user.username,
          "change_site_setting",
          user_history.subject,
          user_history.created_at.strftime(time_format),
          user_history.details,
          user_history.context,
        ],
      )
    end
  end

  context "with reports" do
  end

  context "with screened emails" do
  end

  context "with screened ips" do
  end

  context "with screened urls" do
  end
end
