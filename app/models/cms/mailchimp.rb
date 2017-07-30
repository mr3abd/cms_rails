module Cms
  module Mailchimp
    def self.extended(base)
      base.send(:include)
    end

    def mailchimp_add(email, name = nil)
      begin
        member = mailchimp_list.members.create(
            body: {
                email_address: email,
                name: name,
                status: 'subscribed'
            }
        )
      rescue Exception => e
        if e.repond_to?(:title) && e.title == "Member Exists"
          mailchimp_subscribe(email)
        end
      end
    end

    def mailchimp_subscribe(email)
      lower_case_md5_hashed_email_address = Digest::MD5.hexdigest(email)
      mailchimp_list.members(lower_case_md5_hashed_email_address).update(body: { status: "subscribed" })
    end

    def mailchimp_unsubscribe(email)
      lower_case_md5_hashed_email_address = Digest::MD5.hexdigest(email)
      mailchimp_list.members(lower_case_md5_hashed_email_address).update(body: { status: "unsubscribed" })
    end

    def mailchimp
      api_key = ENV["MAILCHIMP_API_KEY"]
      @_gibbon ||= Gibbon::Request.new(api_key: api_key, debug: false)
    end

    def mailchimp_list
      list_id = ENV["MAILCHIMP_LIST_ID"]
      mailchimp.lists(list_id)
    end

    module InstanceMethods
      def mailchimp
        self.class.mailchimp
      end

      def mailchimp_list
        self.class.mailchimp_list
      end

      def add_to_mailchimp(email = nil, name = nil)
        name = self.try(:name) if name.blank?
        email = self.try(:email) if email.blank?

        self.class.mailchimp_add(email)

        true
      end

      def unsubscribe_from_mailchimp(email = nil)
        email = self.try(:email) if email.blank?
        self.class.mailchimp_unsubscribe(email)
        true
      end
    end
  end
end