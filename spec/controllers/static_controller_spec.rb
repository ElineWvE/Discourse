require 'spec_helper'

describe StaticController do

  context "with a static file that's present" do

    before do
      xhr :get, :show, id: 'faq'
    end

    it 'renders the static file if present' do
      response.should be_success
    end

    it "renders the file" do
      response.should render_template('faq')
    end
  end

  [ ['tos', :tos_url], ['privacy', :privacy_policy_url] ].each do |id, setting_name|
    context "#{id}" do
      subject { xhr :get, :show, id: id }

      context "when #{setting_name} site setting is NOT set" do
        it "renders the #{id} page" do
          expect(subject).to render_template(id)
        end
      end

      context "when #{setting_name} site setting is set" do
        before  { SiteSetting.stubs(setting_name).returns('http://example.com/page') }

        it "redirects to the #{setting_name}" do
          expect(subject).to redirect_to('http://example.com/page')
        end
      end
    end
  end

  context "with a missing file" do
    it "should respond 404" do
      xhr :get, :show, id: 'does-not-exist'
      response.response_code.should == 404
    end
  end

  describe '#enter' do
    context 'without a redirect path' do
      it 'redirects to the root url' do
        xhr :post, :enter
        expect(response).to redirect_to root_path
      end
    end

    context 'with a redirect path' do
      it 'redirects to the redirect path' do
        xhr :post, :enter, redirect: '/foo'
        expect(response).to redirect_to '/foo'
      end
    end

    context 'when the redirect path is the login page' do
      it 'redirects to the root url' do
        xhr :post, :enter, redirect: login_path
        expect(response).to redirect_to root_path
      end
    end
  end
end
