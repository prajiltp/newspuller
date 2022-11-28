class WebScrapper < Kimurai::Base
  cattr_accessor :item, :keyword, :searched_key
  @name = "web_scrapper"
  @engine = :mechanize
  @start_urls = ["https://www.indiatoday.in/search/argentina/", "https://english.mathrubhumi.com/search?q=job&lang=1&content=1&sortOrder=date&userSearch=active", "https://www.onmanorama.com/search-results.html?q=Argentina&searchtype=common"]
  @config = {
    user_agent: "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/68.0.3440.84 Safari/537.36",
    before_request: { delay: 2..3 }
  }

  def parse(response, url:, data: {})
    paper_based_parse(response, url)
    REDIS.SETEX(searched_key, 1.hour, item.to_json)
  end

  def paper_based_parse(response, url)
    if url.include? 'mathrubhumi'
      mathrubhumi_parser(response)
    elsif url.include? 'manorama'
      manorama_parser(response)
    elsif url.include? 'indiatoday'
      indiatoday_parser(response)
    end
  end

  def mathrubhumi_parser(response)
    news = []
    response.xpath("//div[contains(@class, 'mpp-section-card')]").each_with_index do |container, i|
      next unless container.at('h1') && container.at('p').text.html_safe != 'News'

      heading = container.at('h1').text.html_safe
      urls = container.at('a').values
      desc = container.at('p').text.html_safe
      news << {heading: heading, desc: desc, url: "https://english.mathrubhumi.com/"+urls.first}
    end
    item[:mathrubhumi] = news
  end

  def manorama_parser(response)
    news = []
    response.xpath("//div[contains(@class, 'storylist-content')]").each_with_index do |container, i|
      next unless container.at('h2')

      heading = container.at('h2').text.html_safe
      urls = container.at('a').values
      desc = container.at('p').text.html_safe
      news << {heading: heading, desc: desc, url: "https://www.onmanorama.com"+urls.first}
    end
    item[:manorama] = news
  end

  def indiatoday_parser(response)
    news = []
    response.xpath("//div[contains(@class, 'B1S3_content__wrap__9mSB6')]").each_with_index do |container, i|
      next unless container.at('h3')

      heading = container.at('h3').text.html_safe
      urls = container.at('a').values
      desc = container.at('p').text.html_safe
      next unless desc.present?

      news << {heading: heading, desc: desc, url: "https://www.indiatoday.in"+urls.last}
    end
    item[:indiatoday] = news
  end

  def self.crawl_data(keyword, forced=false)
    self.keyword = keyword
    self.searched_key = keyword.gsub(' ', '_')
    if !forced && prev_match?
      JSON.parse(@prev_result)
    else
      self.item = {}
      new_urls = []
      @start_urls.each do |url|
        new_urls << query_string_replaced_url(url, keyword)
      end
      @start_urls = new_urls
      crawl!
      JSON.parse(REDIS.get(searched_key))
    end
  end

  def self.query_string_replaced_url(url, keyword)
    begin_with, end_with = domain_based_begin_end(url)
    current_search = url[/#{begin_with}(.*?)#{end_with}/m, 1]
    search_string = (url.include? 'indiatoday') ? keyword.gsub(' ', "%20") : keyword
    url.gsub("#{begin_with}#{current_search}#{end_with}", "#{begin_with}#{search_string}#{end_with}")
  end

  def self.domain_based_begin_end(url)
    if url.include? 'indiatoday'
      ['/search/', '/']
    else
      ['q=', '&']
    end
  end

  def self.prev_match?
    @prev_result = REDIS.get(searched_key)
    @prev_result.present?
  end
end
