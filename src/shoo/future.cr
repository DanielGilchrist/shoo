module Shoo
  struct Future(T)
    def self.all(items : Array(I), &block : I -> T) : Array(T) forall I
      return Array(T).new if items.empty?

      results = Channel(T | Exception).new(items.size)
      items.each { |item| compute(results) { block.call(item) } }
      Array(T).new(items.size) { settle(results.receive) }
    end

    protected def self.compute(results : Channel(T | Exception), &block : -> T) : Nil
      spawn do
        results.send(block.call)
      rescue error : Exception
        results.send(error)
      end
    end

    protected def self.settle(result : T | Exception) : T
      case result
      in Exception then raise result
      in T         then result
      end
    end

    def initialize(&block : -> T) : Nil
      @result = Channel(T | Exception).new(1)
      Future.compute(@result, &block)
    end

    def await : T
      Future.settle(@result.receive)
    end
  end
end
