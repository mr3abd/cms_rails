module Cms
  class RobotsController < ::Cms::BaseController
    PREDEFINED_USER_AGENTS = {
      google: 'Googlebot',
      apple: 'Applebot',
      baidu: 'baiduspider',
      bing: 'Bingbot',
      archive: 'ia_archiver',
      msn: 'msnbot',
      naver: 'Naverbot',
      seznam: 'seznambot',
      slurp: 'Slurp',
      teoma: 'teoma',
      twitter: 'Twitterbot',
      yandex: 'Yandex',
      yeti: 'Yeti'
    }

    if respond_to?(:caches_page)
      caches_page :robots_txt
    end

    def robots_txt
      #@lines = lines

      configure_robots_txt do
        if robots_txt_production?
          user_agent :google do
            disallow ''
            sitemap
          end
        end

        user_agent '*' do
          disallow '/'
        end
      end

      render inline: render_robots_txt_to_string
    end

    def lines
      arr = []

      if robots_txt_production? && robots_txt_disable_web_archive?
        arr << 'User-agent: ia_archiver'
        arr << 'Disallow: /'
        arr << ''
      end

      arr << "User-agent: *"
      if robots_txt_production?
        arr << "Disallow: "
      else
        arr << "Disallow: /"
      end
      if robots_txt_production?
        arr << "Sitemap: #{absolute_url("/sitemap.xml")}"
      end

      arr
    end

    def test
      configure_robots_txt do
        user_agent :google do
          disallow ''
          sitemap absolute_url('/sitemap.xml')
        end

        user_agent '*' do
          disallow '/'
        end
      end
    end

    protected

    def configure_robots_txt(&block)
      block.call
    end

    def user_agent(string_or_key, &block)
      @robots_txt_ua_entries ||= []
      @robots_txt_entry_index = @robots_txt_ua_entries.length
      if string_or_key.is_a?(Symbol)
        ua_name = PREDEFINED_USER_AGENTS[string_or_key] || string_or_key.to_s
      else
        ua_name = string_or_key
      end

      @robots_txt_ua_entries << { ua: ua_name, lines: [] }

      block.call
    end

    def allow(string)
      @robots_txt_ua_entries[@robots_txt_entry_index][:lines] << "Allow: #{string}"
    end

    def disallow(string)
      @robots_txt_ua_entries[@robots_txt_entry_index][:lines] << "Disallow: #{string}"
    end

    def sitemap(string = absolute_url("/sitemap.xml"))
      @robots_txt_ua_entries[@robots_txt_entry_index][:lines] << "Sitemap: #{string}"
    end

    def robots_txt_production?
      robots_txt_mode = ENV['ROBOTS_TXT_MODE']
      robots_txt_mode == 'production' || (Rails.env.production? && robots_txt_mode.blank?)
    end

    def robots_txt_disable_web_archive?
      ENV["ROBOTS_TXT_DISABLE_WEB_ARCHIVE"].to_s != 'false'
    end

    def render_robots_txt_to_string
      (@robots_txt_ua_entries || []).map do |ua_entry|
        lines = []
        lines << "User-agent: #{ua_entry[:ua]}"
        lines += ua_entry[:lines]

        lines.join("\r\n")
      end.join("\r\n\r\n")
    end
  end
end