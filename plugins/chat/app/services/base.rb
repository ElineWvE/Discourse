# frozen_string_literal: true

module Chat
  module Service
    # Module to be included to provide steps DSL to any class. This allows to
    # create easy to understand services as the whole service cycle is visible
    # simply by reading the beginning of its class.
    #
    # Steps are executed in the order they’re defined. They will use their name
    # to execute the corresponding method defined in the service class.
    #
    # Currently, there are 5 types of steps:
    #
    # * +model(name = :model)+: used to instantiate a model (either by building
    #   it or fetching it from the DB). If a falsy value is returned, then the
    #   step will fail. Otherwise the resulting object will be assigned in
    #   +context[name]+ (+context[:model]+ by default).
    # * +policy(name = :default)+: used to perform a check on the state of the
    #   system. Typically used to run guardians. If a falsy value is returned,
    #   the step will fail.
    # * +contract(name = :default)+: used to validate the input parameters,
    #   typically provided by a user calling an endpoint. A special embedded
    #   +Contract+ class has to be defined to holds the validations. If the
    #   validations fail, the step will fail. Otherwise, the resulting contract
    #   will be available in +context[:"contract.default"]+.
    # * +step(name)+: used to run small snippets of arbitrary code. The step
    #   doesn’t care about its return value, so to mark the service as failed,
    #   {#fail!} has to be called explicitly.
    # * +transaction+: used to wrap other steps inside a DB transaction.
    #
    # The methods defined on the service are automatically provided with
    # the whole context passed as keyword arguments. This allows to define in a
    # very explicit way what dependencies are used by the method. If for
    # whatever reason a key isn’t found in the current context, then Ruby will
    # raise an exception when the method is called.
    #
    # Regarding contract classes, they have automatically {ActiveModel} modules
    # included so all the {ActiveModel} API is available.
    #
    # @example An example from the {TrashChannel} service
    #   class TrashChannel
    #     include Base
    #
    #     model :channel, :fetch_channel
    #     policy :invalid_access
    #     transaction do
    #       step :prevents_slug_collision
    #       step :soft_delete_channel
    #       step :log_channel_deletion
    #     end
    #     step :enqueue_delete_channel_relations_job
    #
    #     private
    #
    #     def fetch_channel(channel_id:, **)
    #       ChatChannel.find_by(id: channel_id)
    #     end
    #
    #     def invalid_access(guardian:, channel:, **)
    #       guardian.can_preview_chat_channel?(channel) && guardian.can_delete_chat_channel?
    #     end
    #
    #     def prevents_slug_collision(channel:, **)
    #       …
    #     end
    #
    #     def soft_delete_channel(guardian:, channel:, **)
    #       …
    #     end
    #
    #     def log_channel_deletion(guardian:, channel:, **)
    #       …
    #     end
    #
    #     def enqueue_delete_channel_relations_job(channel:, **)
    #       …
    #     end
    #   end
    # @example An example from the {UpdateChannelStatus} service which uses a contract
    #   class UpdateChannelStatus
    #     include Base
    #
    #     model :channel, :fetch_channel
    #     contract
    #     policy :check_channel_permission
    #     step :change_status
    #
    #     class Contract
    #       attribute :status
    #       validates :status, inclusion: { in: ChatChannel.editable_statuses.keys }
    #     end
    #
    #     …
    #   end
    module Base
      extend ActiveSupport::Concern

      # The only exception that can be raised by a service.
      class Failure < StandardError
        # @return [Context]
        attr_reader :context

        # @!visibility private
        def initialize(context = nil)
          @context = context
          super
        end
      end

      # Simple structure to hold the context of the service during its whole lifecycle.
      class Context < OpenStruct
        # @return [Boolean] returns +true+ if the conext is set as successful (default)
        def success?
          !failure?
        end

        # @return [Boolean] returns +true+ if the context is set as failed
        # @see #fail!
        # @see #fail
        def failure?
          @failure || false
        end

        # Marks the context as failed.
        # @param context [Hash, Context] the context to merge into the current one
        # @example
        #   context.fail!("failure": "something went wrong")
        # @return [Context]
        def fail!(context = {})
          fail(context)
          raise Failure, self
        end

        # Marks the context as failed without raising an exception.
        # @param context [Hash, Context] the context to merge into the current one
        # @example
        #   context.fail("failure": "something went wrong")
        # @return [Context]
        def fail(context = {})
          merge(context)
          @failure = true
          self
        end

        # Merges the given context into the current one.
        # @!visibility private
        def merge(other_context = {})
          other_context.each { |key, value| self[key.to_sym] = value }
          self
        end

        private

        def self.build(context = {})
          self === context ? context : new(context)
        end
      end

      # Internal module to define available steps as DSL
      # @!visibility private
      module StepsHelpers
        def model(name = :model, step_name = :"fetch_#{name}")
          steps << ModelStep.new(name, step_name)
        end

        def contract(name = :default, class_name: self::Contract)
          steps << ContractStep.new(name, class_name: class_name)
        end

        def policy(name = :default)
          steps << PolicyStep.new(name)
        end

        def step(name)
          steps << Step.new(name)
        end

        def transaction(&block)
          steps << TransactionStep.new(&block)
        end
      end

      # @!visibility private
      class Step
        attr_reader :name, :method_name, :class_name

        def initialize(name, method_name = name, class_name: nil)
          @name = name
          @method_name = method_name
          @class_name = class_name
        end

        def call(instance, context)
          method = instance.method(method_name)
          args = {}
          args = context.to_h unless method.arity.zero?
          instance.instance_exec(**args, &method)
        end
      end

      # @!visibility private
      class ModelStep < Step
        def call(instance, context)
          context[name] = super
          raise ArgumentError, "Model not found" unless context[name]
        rescue ArgumentError => exception
          context.fail!("result.#{name}": Context.build.fail(exception: exception))
        end
      end

      # @!visibility private
      class PolicyStep < Step
        def call(instance, context)
          context["result.policy.#{name}"] = Context.build
          context.fail!("result.policy.#{name}": Context.build.fail) unless super
        end
      end

      # @!visibility private
      class ContractStep < Step
        def call(instance, context)
          contract = class_name.new(context.to_h.slice(*class_name.attribute_names.map(&:to_sym)))
          context[:"contract.#{name}"] = contract

          context["result.contract.#{name}"] = Context.build
          unless contract.valid?
            context.fail!("result.contract.#{name}": Context.build.fail(errors: contract.errors))
          end
        end
      end

      # @!visibility private
      class TransactionStep < Step
        include StepsHelpers

        attr_reader :steps

        def initialize(&block)
          @steps = []
          instance_exec(&block)
        end

        def call(instance, context)
          ActiveRecord::Base.transaction { steps.each { |step| step.call(instance, context) } }
        end
      end

      included do
        attr_reader :context

        delegate :fail!, to: :context

        # @!visibility private
        # Internal class used to setup the base contract of the service.
        self::Contract =
          Class.new do
            include ActiveModel::API
            include ActiveModel::Attributes
            include ActiveModel::AttributeMethods
          end
      end

      class_methods do
        include StepsHelpers

        def call(context = {})
          new(context).tap(&:run).context
        end

        def call!(context = {})
          new(context).tap(&:run!).context
        end

        def steps
          @steps ||= []
        end
      end

      # @!scope class
      # @!method policy(name = :default, &block)
      # Evaluates a set of conditions related to the given context. If the
      # block doesn’t return a truthy value, then the policy will fail.
      # More than one policy can be defined and named. When that’s the case,
      # policies are evaluated in their definition order.
      #
      # @example
      #   policy(:invalid_access) do
      #     guardian.can_delete_chat_channel?
      #   end

      # @!scope class
      # @!method contract(&block)
      # Checks the validity of the input parameters.
      # Implements ActiveModel::Validations and ActiveModel::Attributes.
      #
      # @example
      #   contract do
      #     attribute :name
      #     validates :name, presence: true
      #   end

      # @!scope class
      # @!method service(&block)
      # Holds the business logic of the service.
      #
      # @example
      #   service { context.topic.update!(archived: true) }

      # @!visibility private
      def initialize(initial_context = {})
        @initial_context = initial_context.with_indifferent_access
        @context = Context.build(initial_context.merge(__steps__: self.class.steps))
      end

      private

      def run
        run!
      rescue Failure => exception
        raise if context.object_id != exception.context.object_id
      end

      def run!
        self.class.steps.each { |step| step.call(self, context) }
      end
    end
  end
end
