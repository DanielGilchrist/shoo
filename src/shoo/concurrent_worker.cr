module Shoo
  module ConcurrentWorker(T, R)
    def self.run(items : Array(T), concurrency : UInt8 = 10, &block : T -> R) : Array(R)
      return Array(R).new if items.empty?

      semaphore = Semaphore.new(concurrency)
      result_channel = Channel(Tuple(Int32, R)).new

      items.each_with_index do |item, index|
        # TODO: Avoid spawning a fiber per item, consider a pool
        spawn do
          semaphore.synchronise do
            result = block.call(item)
            result_channel.send({index, result})
          end
        end
      end

      items
        .size
        .times
        .map { result_channel.receive }
        .to_a
        .sort_by(&.first)
        .map(&.last)
    end

    private struct Semaphore
      def initialize(concurrency : UInt8)
        @channel = Channel(Nil).new(concurrency)
        concurrency.times { release }
      end

      def synchronise(&)
        acquire
        yield
      ensure
        release
      end

      private def acquire
        @channel.receive
      end

      private def release
        @channel.send(nil)
      end
    end
  end
end
