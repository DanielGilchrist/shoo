module APIStub
  module GitHub
    resource :notifications do
      def list(specs : Array(Data::NotificationSpec) = [] of Data::NotificationSpec)
        paginated("/notifications", build_payloads(specs))
      end

      def list(*specs : Data::NotificationSpec)
        list(specs.to_a)
      end

      def fail(status = 500, message = "Server Error")
        stub(:get, "/notifications", query: PAGE_1, status: status, body: Data.error(message, status).to_json)
      end

      def mark_as_done(id : String, success = true, message = "Server Error")
        delete("/notifications/threads/#{id}", success, message)
      end

      def unsubscribe(id : String, success = true, message = "Server Error")
        delete("/notifications/threads/#{id}/subscription", success, message)
      end

      private def build_payloads(specs : Array(Data::NotificationSpec))
        Data.resolve_ids(specs).map do |(spec, id)|
          url = nil
          type = "PullRequest"

          if subject = spec.subject
            path = subject.path(spec.repo, id)
            url = GitHub.url(path)
            type = subject.type
            stub(:get, path, status: subject.status, body: subject.body)
          end

          {
            id:         id,
            reason:     spec.reason,
            subject:    {title: spec.title, type: type, url: url},
            repository: {full_name: spec.repo},
          }
        end
      end
    end
  end
end
