module Shoo
  class Config
    struct Notifications
      def self.parse(raw : Raw::Notifications) : Notifications | Array(Error)
        purge = Purge.parse(raw.purge)
        return purge if purge.is_a?(Array(Error))

        new(purge)
      end

      private def initialize(@purge : Purge)
      end

      getter purge : Purge
    end
  end
end
