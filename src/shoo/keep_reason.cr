module Shoo
  abstract struct KeepReason
    abstract def label : String
    abstract def colourise(width : Int32) : String

    struct AlwaysKept < KeepReason
      getter reason : GitHub::NotificationReason

      def initialize(@reason : GitHub::NotificationReason)
      end

      def label : String
        reason.description
      end

      def colourise(width : Int32) : String
        label.ljust(width).colorize.white.to_s
      end
    end

    struct Mentioned < KeepReason
      def label : String
        "you were mentioned"
      end

      def colourise(width : Int32) : String
        label.ljust(width).colorize.green.to_s
      end
    end

    struct Author < KeepReason
      getter login : String

      def initialize(@login : String)
      end

      def label : String
        "author: #{login}"
      end

      def colourise(width : Int32) : String
        label.ljust(width).colorize.cyan.to_s
      end
    end

    abstract struct TeamReason < KeepReason
      getter team : String

      def initialize(@team : String)
      end

      def colourise(width : Int32) : String
        label.ljust(width).colorize.blue.to_s
      end
    end

    struct AuthorInTeam < TeamReason
      def label : String
        "author in #{team}"
      end
    end

    struct RequestedTeam < TeamReason
      def label : String
        "review requested: #{team}"
      end
    end

    struct MentionedTeam < TeamReason
      def label : String
        "#{team} mentioned"
      end
    end
  end
end
