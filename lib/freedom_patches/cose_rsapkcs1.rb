# frozen_string_literal: true

require 'cose'
require 'openssl/signature_algorithm/rsapkcs1'

module COSE
  module Algorithm
    class RSAPKCS1 < SignatureAlgorithm
      attr_reader :hash_function

      def initialize(*args, hash_function:)
        super(*args)

        @hash_function = hash_function
      end

      private

      def valid_key?(key)
        to_cose_key(key).is_a?(COSE::Key::RSA)
      end

      def signature_algorithm_class
        OpenSSL::SignatureAlgorithm::RSAPKCS1
      end

      def to_pkey(key)
        case key
        when COSE::Key::RSA
          key.to_pkey
        when OpenSSL::PKey::RSA
          key
        else
          raise(COSE::Error, 'Incompatible key for algorithm')
        end
      end
    end

    register(RSAPKCS1.new(-257, 'RS256', hash_function: 'SHA256'))
    register(RSAPKCS1.new(-258, 'RS384', hash_function: 'SHA384'))
    register(RSAPKCS1.new(-259, 'RS512', hash_function: 'SHA512'))
  end
end
