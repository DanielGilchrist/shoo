module Shoo
  enum PurgeReason
    Merged
    Closed
    Filtered

    def label : String
      filtered? ? "not kept" : to_s.downcase
    end

    def paint(text : String) : String
      case self
      in .merged?
        text.colorize.light_magenta
      in .closed?
        text.colorize.red
      in .filtered?
        text.colorize.dark_gray
      end.to_s
    end

    def colourise(width : Int32) : String
      paint(label.ljust(width))
    end
  end
end
