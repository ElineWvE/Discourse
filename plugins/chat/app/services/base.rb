# frozen_string_literal: true

module Chat
  module Service
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
        def success?
          !failure?
        end

        def failure?
          @failure || false
        end

        # Marks the service as failed.
        # @param context [Hash, Context] the context to merge into the current one
        # @example
        #   context.fail!("failure": "something went wrong")
        # @return [Context]
        def fail!(context = {})
          fail(context)
          raise Failure, self
        end

        # Marks the service as failed without raising an exception.
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

      class Step
        attr_reader :name, :block, :class_name

        def initialize(name, class_name: nil, &block)
          @name = name
          @block = block
          @class_name = class_name
        end

        def call(instance, context)
          block = instance.method(name) unless block
          instance.instance_exec(&block)
        end
      end

      class ModelStep < Step
        attr_reader :key

        def initialize(name, class_name:, key:)
          @key = key
          super name, class_name: class_name
        end

        def call(instance, context)
          model = class_name.find_by(id: context[key])
          context[name] = model
          context.fail!("result.#{name}": Context.build.fail) unless model
        end
      end

      class PolicyStep < Step
        def call(instance, context)
          context.fail!("result.policy.#{name}": Context.build.fail) unless super
        end
      end

      class ContractStep < Step
        def call(instance, context)
          contract = class_name.new(context.to_h.slice(*class_name.attribute_names.map(&:to_sym)))
          context[:"contract.#{name}"] = contract

          unless contract.valid?
            context.fail!("result.contract.#{name}": Context.build.fail(errors: contract.errors))
          end
        end
      end

      included do
        attr_reader :context, :contract

        delegate :guardian, to: :context

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
        attr_reader :steps

        def call(context = {})
          new(context).tap(&:run).context
        end

        def call!(context = {})
          new(context).tap(&:run!).context
        end

        def model(class_name, name: :model, key: :id)
          steps << ModelStep.new(name, key: key, class_name: class_name)
        end

        def contract(name = :default, class_name: self::Contract)
          steps << ContractStep.new(name, class_name: class_name)
        end

        def policy(name = :default, &block)
          steps << PolicyStep.new(name, &block)
        end

        def step(name, &block)
          steps << Step.new(name, &block)
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
        @context = Context.build(initial_context)
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
