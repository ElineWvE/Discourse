# name: discourse-edgeryders
# about: Custom discourse functionality for edgeryderse.eu
# version: 0.0.1


register_asset 'stylesheets/consent.scss'
register_asset 'stylesheets/paycoupons.scss'
register_asset 'javascripts/quiz.js'
register_asset 'javascripts/quizlib.1.0.0.min.js'


after_initialize do


  require_dependency 'user_serializer'
  class ::UserSerializer
    attributes :consent_given

    def consent_given
      object.consent_given?
    end
  end


  require_dependency 'post_serializer'
  class ::PostSerializer
    attributes :poster_paycoupons_username

    def poster_paycoupons_username
      object.user.paycoupons_username
    end
  end


  require_dependency 'topics_controller'
  module TopicsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        before_filter :ensure_consent_given, only: [:update]
      end
    end

    module InstanceMethods
      def ensure_consent_given
        raise Discourse::InvalidAccess.new unless current_user && current_user.consent_given?
      end
    end
  end
  TopicsController.send :include, TopicsControllerPatch


  require_dependency 'posts_controller'
  module PostsControllerPatch
    def self.included(base)
      base.send(:include, InstanceMethods)
      base.class_eval do
        before_filter :ensure_consent_given, only: [:create, :update]
      end
    end

    module InstanceMethods
      def ensure_consent_given
        raise Discourse::InvalidAccess.new unless current_user && current_user.consent_given?
      end
    end
  end
  PostsController.send :include, PostsControllerPatch


  class ::User
    # NOTE: A corresponding 'edgeryders_consent' field must be created in: Admin -> Customize -> User Fields.
    def consent_given?
      UserCustomField.exists?(user_id: id, name: 'edgeryders_consent', value: '1')
    end

    def paycoupons_username
      UserCustomField.find_by(user_id: id, name: 'user_field_2').try(:value)
    end
  end


  User.class_eval do
    # Use to notify community managers about new sign-ups.
    # Users can simply set the notification level of the posts thread accordingly ("Watching" to get immediate
    # e-mail notifications, "Tracking" to only get in-site and desktop notifications).
    after_create do
      if topic = Topic.find_by(id: 6710)
        manager = NewPostManager.new(
          Discourse.system_user,
          raw: "We're glad to welcome [#{username}](/u/#{username}) to our community.",
          topic_id: topic.id
        )
        manager.perform
      end
    end
  end


  class ::SiteSetting

    class << self
      attr_accessor :current_hostname
    end


    def self.logo_url
      path = "/images/logo.#{SiteSetting.current_hostname}.png"
      File.exists?(Rails.root.join("public#{path}")) ? path : '/images/logo-small.png'
    end

    def self.logo_small_url
      path = "/images/logo-small.#{SiteSetting.current_hostname}.png"
      File.exists?(Rails.root.join("public#{path}")) ? path :  '/images/logo-small.png'
    end

    def self.digest_logo_url
      logo_url
    end

    def self.mobile_logo_url
      logo_small_url
    end

    def self.favicon_url
      path = "/images/favicon.#{SiteSetting.current_hostname}.png"
      File.exists?(Rails.root.join("public#{path}")) ? path : '/images/favicon.png'
    end

    def self.apple_touch_icon_url
      path = "/images/apple-touch-icon.#{SiteSetting.current_hostname}.png"
      File.exists?(Rails.root.join("public#{path}")) ? path : '/images/apple-touch-icon.png'
    end

  end


end
