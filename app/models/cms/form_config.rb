module Cms
  class FormConfig < ActiveRecord::Base
    attr_accessible *attribute_names

    def self.default_emails
      ['p.korenev@voroninstudio.eu']
    end

    def emails
      em = (email_receivers || "").split("\r\n")
      if em.empty?
        return self.class.default_emails
      else
        return em
      end
    end
  end
end