module Shoo
  module ConcurrentWorker(T, R)
    def self.run(items : Array(T), concurrency : UInt8 = 10, &block : T -> R) : Array(R)
      return Array(R).new if items.empty?

      semaphore = Channel(Nil).new(concurrency)
      result_channel = Channel(Tuple(Int32, R)).new

      concurrency.times { semaphore.send(nil) }

      items.each_with_index do |item, index|
        spawn do
          semaphore.receive

          result = block.call(item)
          result_channel.send({index, result})

          semaphore.send(nil)
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
  end
end
