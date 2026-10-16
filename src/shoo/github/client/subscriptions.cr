require "../queries/update_subscription_payload_fragment"

module Shoo
  module GitHub
    struct Client
      # Unsubscribes from issues and pull requests by node id, many per request.
      struct Subscriptions
        CHUNK_SIZE          = 50
        FIELD               = "updateSubscription"
        UNSUBSCRIBED        = ::GraphQL::Document::EnumValue.new("UNSUBSCRIBED")
        INSUFFICIENT_SCOPES = "INSUFFICIENT_SCOPES"

        alias Payload = Queries::UpdateSubscriptionPayloadFragment
        alias Outcomes = Hash(String, Unresolved?)

        record MissingScope, message : String

        def initialize(@graphql : ::GraphQL::Client) : Nil
        end

        def unsubscribe(subject_ids : Array(String)) : Outcomes | MissingScope
          subject_ids.uniq.each_slice(CHUNK_SIZE).each_with_object(Outcomes.new) do |chunk, outcomes|
            case result = unsubscribe_chunk(chunk)
            in MissingScope then return result
            in Outcomes     then outcomes.merge!(result)
            end
          end
        end

        private def unsubscribe_chunk(subject_ids : Array(String)) : Outcomes | MissingScope
          aliases = subject_ids.each_with_index.to_h { |subject_id, index| {"u#{index}", subject_id} }

          text = ::GraphQL::Document.mutation do
            aliases.each do |alias_name, subject_id|
              field(FIELD, Payload, as: alias_name, input: ::GraphQL::Document::Input{"subscribableId" => subject_id, "state" => UNSUBSCRIBED})
            end
          end

          case envelope = @graphql.execute(text, Hash(String, Payload?))
          in ::GraphQL::Envelope(Hash(String, Payload?))
            aliases.each_with_object(Outcomes.new) do |(alias_name, subject_id), outcomes|
              outcomes[subject_id] =
                if envelope.data[alias_name]?
                  nil
                else
                  Unresolved.new(envelope.error_at?(alias_name).try(&.message) || "subscription to #{subject_id} was not updated")
                end
            end
          in ::GraphQL::Failure
            if envelope.is_a?(::GraphQL::RejectedQuery) && (error = envelope.errors.find { |rejection| rejection.type == INSUFFICIENT_SCOPES })
              return MissingScope.new(error.message)
            end

            unresolved = Unresolved.new(GitHub.describe(envelope))
            subject_ids.to_h { |subject_id| {subject_id, unresolved.as(Unresolved?)} }
          end
        end
      end
    end
  end
end
