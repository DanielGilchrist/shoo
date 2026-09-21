module Shoo
  module GitHub
    record SubjectRef, owner : String, name : String, number : Int32 do
      def self.for(notification : Notification) : SubjectRef?
        number = notification.subject.number
        return unless number

        repository = notification.repository
        new(repository.owner.login, repository.name, number)
      end

      def repository : Tuple(String, String)
        {owner, name}
      end
    end
  end
end
