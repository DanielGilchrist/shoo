module Shoo
  module GitHub
    alias Failure = Error | ::GraphQL::Failure

    def self.describe(failure : Failure) : String
      case failure
      in Error                        then failure.message
      in ::GraphQL::ConnectionFailure then "could not reach GitHub (#{failure.cause.message})"
      in ::GraphQL::HTTPFailure       then describe_http(failure)
      in ::GraphQL::RejectedQuery     then failure.errors.map(&.message).join("; ")
      in ::GraphQL::MalformedResponse then "unexpected response from GitHub: #{failure.reason}"
      end
    end

    private def self.describe_http(failure : ::GraphQL::HTTPFailure) : String
      message = Error.from_json(failure.body).message rescue "HTTP #{failure.status}"
      retry_after = failure.retry_after
      retry_after ? "#{message} (retry after #{retry_after.total_seconds.to_i}s)" : message
    end
  end
end
