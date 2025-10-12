module Shoo
  module Paginator(T)
    def self.paginate(page : Int32 = 1, per_page : Int32 = 50, & : (Int32, Int32) -> Array(T)) : Array(T)
      Array(T).new.tap do |results|
        loop do
          last_results = yield(page, per_page)

          last_results.each do |result|
            results << result
          end

          break if last_results.size < per_page

          page += 1
        end
      end
    end
  end
end
