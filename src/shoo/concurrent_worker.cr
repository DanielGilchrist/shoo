module Shoo
  module ConcurrentWorker(T, R)
    def self.run(items : Array(T), &block : T -> R) : Array(R)
      return Array(R).new if items.empty?

      results = Channel(R).new(items.size)
      items.each { |item| spawn { results.send(block.call(item)) } }
      Array(R).new(items.size) { results.receive }
    end
  end
end
