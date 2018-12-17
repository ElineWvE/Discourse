require "rails_helper"

describe ::DiscoursePoll::PollsValidator do
  let(:post) { Fabricate(:post) }
  subject { described_class.new(post) }

  describe "#validate_polls" do
    it "ensures that polls have valid arguments" do
      raw = <<~RAW
      [poll type=not_good1 status=not_good2 results=not_good3]
      * 1
      * 2
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(I18n.t("poll.invalid_argument", argument: "type", value: "not_good1"))
      expect(post.errors[:base]).to include(I18n.t("poll.invalid_argument", argument: "status", value: "not_good2"))
      expect(post.errors[:base]).to include(I18n.t("poll.invalid_argument", argument: "results", value: "not_good3"))
    end

    it "ensures that all possible values are valid" do
      Poll.types.keys.product(Poll.statuses.keys, Poll.results.keys).each do |type, status, result|
        raw = <<~RAW
        [poll type=#{type} status=#{status} result=#{result}]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(true)
        expect(post.errors[:base].size).to eq(0)
      end
    end

    it "ensure that polls have unique names" do
      raw = <<~RAW
      [poll]
      * 1
      * 2
      [/poll]

      [poll]
      * 1
      * 2
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(
        I18n.t("poll.multiple_polls_without_name")
      )

      raw = <<~RAW
      [poll name=test]
      * 1
      * 2
      [/poll]

      [poll name=test]
      * 1
      * 2
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(
        I18n.t("poll.multiple_polls_with_same_name", name: "test")
      )
    end

    it "ensure that polls have unique options" do
      raw = <<~RAW
      [poll]
      * 1
      * 1
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(
        I18n.t("poll.default_poll_must_have_different_options")
      )

      raw = <<~RAW
      [poll name=test]
      * 1
      * 1
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(
        I18n.t("poll.named_poll_must_have_different_options", name: "test")
      )
    end

    it "ensure that polls have at least 2 options" do
      raw = <<~RAW
      [poll]
      * 1
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(
        I18n.t("poll.default_poll_must_have_at_least_2_options")
      )

      raw = <<~RAW
      [poll name=test]
      * 1
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(
        I18n.t("poll.named_poll_must_have_at_least_2_options", name: "test")
      )
    end

    it "ensure that polls options do not exceed site settings" do
      SiteSetting.poll_maximum_options = 2

      raw = <<~RAW
      [poll]
      * 1
      * 2
      * 3
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(I18n.t(
        "poll.default_poll_must_have_less_options",
        count: SiteSetting.poll_maximum_options
      ))

      raw = <<~RAW
      [poll name=test]
      * 1
      * 2
      * 3
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)

      expect(post.errors[:base]).to include(I18n.t(
        "poll.named_poll_must_have_less_options",
        name: "test", count: SiteSetting.poll_maximum_options
      ))
    end

    describe "multiple type polls" do
      it "ensure that min < max" do
        raw = <<~RAW
        [poll type=multiple min=2 max=1]
        * 1
        * 2
        * 3
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.default_poll_with_multiple_choices_has_invalid_parameters")
        )

        raw = <<~RAW
        [poll type=multiple min=2 max=1 name=test]
        * 1
        * 2
        * 3
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.named_poll_with_multiple_choices_has_invalid_parameters", name: "test")
        )
      end

      it "ensure max > 0" do
        raw = <<~RAW
        [poll type=multiple max=-2]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.default_poll_with_multiple_choices_has_invalid_parameters")
        )
      end

      it "ensure that max <= number of options" do
        raw = <<~RAW
        [poll type=multiple max=3]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.default_poll_with_multiple_choices_has_invalid_parameters")
        )
      end

      it "ensure that min >= 0" do
        raw = <<~RAW
        [poll type=multiple min=-1]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.default_poll_with_multiple_choices_has_invalid_parameters")
        )
      end

      it "ensure that min can be 0" do
        raw = <<~RAW
        [poll type=multiple min=0]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(true)
      end

      it "ensure that min != number of options" do
        raw = <<~RAW
        [poll type=multiple min=2]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.default_poll_with_multiple_choices_has_invalid_parameters")
        )
      end

      it "ensure that min < number of options" do
        raw = <<~RAW
        [poll type=multiple min=3]
        * 1
        * 2
        [/poll]
        RAW

        expect(post.update_attributes(raw: raw)).to eq(false)

        expect(post.errors[:base]).to include(
          I18n.t("poll.default_poll_with_multiple_choices_has_invalid_parameters")
        )
      end
    end

    it "number type polls are validated" do
      raw = <<~RAW
      [poll type=number min=-5 max=-10 step=-1]
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)
      expect(post.errors[:base]).to include("Min " + I18n.t("errors.messages.greater_than", count: 0))
      expect(post.errors[:base]).to include("Max " + I18n.t("errors.messages.greater_than", count: "min"))
      expect(post.errors[:base]).to include("Step " + I18n.t("errors.messages.greater_than", count: 0))

      raw = <<~RAW
      [poll type=number min=9999999999 max=9999999999 step=1]
      [/poll]
      RAW

      expect(post.update_attributes(raw: raw)).to eq(false)
      expect(post.errors[:base]).to include("Min " + I18n.t("errors.messages.less_than", count: 2_147_483_647))
      expect(post.errors[:base]).to include("Max " + I18n.t("errors.messages.less_than", count: 2_147_483_647))
      expect(post.errors[:base]).to include(I18n.t("poll.default_poll_must_have_at_least_2_options"))
    end
  end
end
