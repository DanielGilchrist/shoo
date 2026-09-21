module Shoo
  module ConcurrentWorker(T, R)
    def self.run(items : Array(T), &block : T -> R) : Array(R)
      return Array(R).new if items.empty?

      results = Channel(R | Exception).new(items.size)

      items.each do |item|
        spawn do
          results.send(block.call(item))
        rescue error : Exception
          results.send(error)
        end
      end

      Array(R).new(items.size) do
        case result = results.receive
        in Exception then raise result
        in R         then result
        end
      end
    end
  end
end
