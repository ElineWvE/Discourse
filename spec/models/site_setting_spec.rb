require 'spec_helper'
require_dependency 'site_setting'
require_dependency 'site_setting_extension'

describe SiteSetting do

  describe "normalized_embeddable_host" do
    it 'returns the `embeddable_host` value' do
      SiteSetting.stubs(:embeddable_host).returns("eviltrout.com")
      SiteSetting.normalized_embeddable_host.should == "eviltrout.com"
    end

    it 'strip http from `embeddable_host` value' do
      SiteSetting.stubs(:embeddable_host).returns("http://eviltrout.com")
      SiteSetting.normalized_embeddable_host.should == "eviltrout.com"
    end

    it 'strip https from `embeddable_host` value' do
      SiteSetting.stubs(:embeddable_host).returns("https://eviltrout.com")
      SiteSetting.normalized_embeddable_host.should == "eviltrout.com"
    end
  end

  describe 'topic_title_length' do
    it 'returns a range of min/max topic title length' do
      SiteSetting.topic_title_length.should ==
        (SiteSetting.defaults[:min_topic_title_length]..SiteSetting.defaults[:max_topic_title_length])
    end
  end

  describe 'post_length' do
    it 'returns a range of min/max post length' do
      SiteSetting.post_length.should == (SiteSetting.defaults[:min_post_length]..SiteSetting.defaults[:max_post_length])
    end
  end

  describe 'private_message_title_length' do
    it 'returns a range of min/max pm topic title length' do
      expect(SiteSetting.private_message_title_length).to eq(SiteSetting.defaults[:min_private_message_title_length]..SiteSetting.defaults[:max_topic_title_length])
    end
  end

  describe 'in test we do some judo to ensure SiteSetting is always reset between tests' do

    it 'is always the correct default' do
      expect(SiteSetting.contact_email).to eq('')
    end

    it 'sets a setting' do
      SiteSetting.contact_email = 'sam@sam.com'
    end

    it 'is always the correct default' do
      expect(SiteSetting.contact_email).to eq('')
    end
  end

  describe "anonymous_homepage" do
    it "returns latest" do
      expect(SiteSetting.anonymous_homepage).to eq('latest')
    end
  end

  describe "top_menu" do
    before(:each) { SiteSetting.top_menu = 'one,-nope|two|three,-not|four,ignored|category/xyz' }

    describe "items" do
      let(:items) { SiteSetting.top_menu_items }

      it 'returns TopMenuItem objects' do
        expect(items[0]).to be_kind_of(TopMenuItem)
      end
    end

    describe "homepage" do
      it "has homepage" do
        expect(SiteSetting.homepage).to eq('one')
      end
    end
  end

  describe "scheme" do

    it "returns http when ssl is disabled" do
      SiteSetting.expects(:use_https).returns(false)
      SiteSetting.scheme.should == "http"
    end

    it "returns https when using ssl" do
      SiteSetting.expects(:use_https).returns(true)
      SiteSetting.scheme.should == "https"
    end

  end

  # See: https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html
  shared_examples "s3 bucket naming conventions" do |s3_setting|
    describe s3_setting do
      it "disallows bucket names that start with ." do
        expect { SiteSetting.send("#{s3_setting}=", ".foo.bar") }.to raise_error(Discourse::InvalidParameters)
      end

      it "disallows bucket names that end with ." do
        expect { SiteSetting.send("#{s3_setting}=", "foo1.bar.") }.to raise_error(Discourse::InvalidParameters)
      end

      it "disallows bucket names that have more than one . in a row" do
        expect { SiteSetting.send("#{s3_setting}=", "foo1..bar") }.to raise_error(Discourse::InvalidParameters)
      end

      it "disallows bucket names that are less than 3 characters long" do
        expect { SiteSetting.send("#{s3_setting}=", "fo") }.to raise_error(Discourse::InvalidParameters)
      end

      it "allows bucket names that have . in it" do
        expect { SiteSetting.send("#{s3_setting}=", "foo1.bar") }.not_to raise_error
      end

      it "allows bucket names that have - in it" do
        expect { SiteSetting.send("#{s3_setting}=", "foo1-bar") }.not_to raise_error
      end
    end
  end

  it_behaves_like "s3 bucket naming conventions", :s3_upload_bucket
  it_behaves_like "s3 bucket naming conventions", :s3_backup_bucket
end
