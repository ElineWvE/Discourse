# frozen_string_literal: true

SanePatch.patch("ipaddr", "~> 1.2.4") do
  module FreedomPatches
    module IpAddr
      extend ActiveSupport::Concern

      class_methods do
        def handle_wildcards(val)
          return if val.blank?

          num_wildcards = val.count('*')

          return val if num_wildcards == 0

          # strip ranges like "/16" from the end if present
          v = val.gsub(/\/.*/, '')

          return if v[v.index('*')..-1] =~ /[^\.\*]/

          parts = v.split('.')
          (4 - parts.size).times { parts << '*' } # support strings like 192.*
          v = parts.join('.')

          "#{v.tr('*', '0')}/#{32 - (v.count('*') * 8)}"
        end
      end

      def to_cidr_s
        if @addr
          mask = @mask_addr.to_s(2).count('1')
          if mask == 32
            to_s
          else
            "#{to_s}/#{mask}"
          end
        else
          nil
        end
      end

      IPAddr.prepend(self)
    end
  end
end
