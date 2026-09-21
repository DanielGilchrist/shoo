module Shoo
  class Status
    FRAMES   = %w[⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏]
    INTERVAL = 80.milliseconds
    CLEAR    = "\r\e[2K"

    def initialize(@io : IO) : Nil
      @text = ""
      @spinning = false
      @started = Time.instant
    end

    def update(text : String) : Nil
      @text = text
      return if @spinning

      spin if @io.tty?
    end

    def finish(text : String) : Nil
      stop
      return unless @io.tty?

      elapsed = (Time.instant - @started).total_seconds
      @io.puts "#{"✓".colorize.green} #{text} #{"in #{elapsed.round(1)}s".colorize.dark_gray}"
    end

    def clear : Nil
      stop
      @io.print CLEAR if @io.tty?
    end

    private def spin : Nil
      @spinning = true

      spawn do
        FRAMES.cycle.each do |frame|
          break unless @spinning

          @io.print "#{CLEAR}#{frame.colorize.cyan} #{@text}"
          sleep INTERVAL
        end
      end
    end

    private def stop : Nil
      return unless @spinning

      @spinning = false
      @io.print CLEAR
    end
  end
end
