module Cms
  module TextsUpdater
    def self.remove_styles
      tables = Cms.tables(nil, ["content"])
      tables.each do |t|
        rows = ActiveRecord::Base.connection.execute("SELECT id, content from #{t}")
        rows.each do |r|
          content = r["content"]
          next if content.blank?
          new_content = normalize_content(content)
          if new_content != content
            puts "UPDATE: #{t}: ##{r["id"]}"

            new_content = new_content.gsub(/\'/, "\\'").gsub(/\"/, "\'").html_safe
            minified_new_content = new_content.gsub(/\r\n/, " ").gsub(/\n/, " ")

            q = "UPDATE #{t} SET content=? WHERE id=#{r["id"]}"
            args = [minified_new_content]
            ActiveRecord::Base.connection.execute("UPDATE #{t} SET content=#{ActiveRecord::Base.sanitize(minified_new_content)} WHERE id=#{r["id"]}")
            #st = ActiveRecord::Base.connection.raw_connection.prepare(q)
            #st.execute(*args)
            #st.close

          end
        end
      end


      nil

    end

    def self.normalize_content(content)
      #new_content = content.gsub(/style=\"[a-zA-Z\-\_\:\;0-9\(\)\s\']{0,}\"/, "")
      #new_content = new_content.gsub(/style=\'[a-zA-Z\-\_\:\;0-9\(\)\s\"]{0,}\'/, "")

      require 'nokogiri'


      #doc = Nokogiri::HTML(content)
      doc = Nokogiri::HTML::DocumentFragment.parse(content)
      #puts doc.xpath("//@style").inspect
      #doc.xpath('//@style').remove
      all_elements = doc.css("*")
      elements_with_style_attr = all_elements.select{|e| !e["style"].nil? }
      if elements_with_style_attr.count == 0
        return content
      end
      elements_with_style_attr.each{|e| e.remove_attribute('style')}
      #puts doc.to_s
      doc.to_s
    end
  end
end