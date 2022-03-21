# frozen_string_literal: true

require 'cose'
require 'openssl/signature_algorithm/rsapkcs1'

# 'cose' gem does not implement all algorithms from the Web Authentication
# (WebAuthn) standard specification. This patch implements one of the missing
# ones, RSASSA-PKCS1-v1_5.

SanePatch.patch("cose", "~> 1.2.0") do
  module FreedomPatches
    module CoseRsapkcs1
      module Algorithm
        def registered_algorithm_ids
          @registered_by_id.keys
        end
      end

      class RSAPKCS1 < COSE::Algorithm::SignatureAlgorithm
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

      COSE::Algorithm.register(RSAPKCS1.new(-257, 'RS256', hash_function: 'SHA256'))
      COSE::Algorithm.register(RSAPKCS1.new(-258, 'RS384', hash_function: 'SHA384'))
      COSE::Algorithm.register(RSAPKCS1.new(-259, 'RS512', hash_function: 'SHA512'))
      COSE::Algorithm.extend(Algorithm)
    end
  end
end
