require 'medusa'
require 'csv'

namespace :searchgov do
  desc 'Bulk index urls into Search.gov'
  # Usage: rake searchgov:bulk_index[my_urls.csv,10]

  task :bulk_index, [:url_file, :sleep_seconds] => [:environment] do |_t, args|
    url_file = args.url_file
    line_count = `wc -l < #{url_file}`.to_i
    CSV.foreach(url_file) do |row|
      url = row.first
      begin
        puts "[#{$INPUT_LINE_NUMBER}/#{line_count}] Preparing to index #{url}"
        searchgov_url = SearchgovUrl.create!(url: url)
        sleep(args.sleep_seconds.to_i || 10) #to avoid getting us blacklisted...
        searchgov_url.fetch
        status = searchgov_url.last_crawl_status
        (status == 'OK') ? (puts "Indexed #{searchgov_url.url}".green) : (puts "Failed to index #{url}:\n#{status}".red)
      rescue => error
        puts "Failed to index #{url}:\n#{error}".red
      end
    end
  end

  task :crawl, [:domain, :crawler,:srsly] => [:environment] do |_t, args|
    @domain = args[:domain]
    @site = "http://#{@domain}"
    @srsly = args[:srsly]
    crawler = args[:crawler].to_sym
    @file = CSV.open("crawls/#{@domain}_#{crawler}_#{Time.now.strftime("%m-%e-%y_%H_%M")}", 'w')

    puts "Preparing to to crawl #{@site} with #{crawler}. Output file: #{@file.path}"
    time = Benchmark.realtime { self.send(crawler) }

    @file << ["Elapsed time: #{time}"]

    @file.close
    puts "Crawling complete. Elapsed time: #{time}. Output file: #{@file.path}"
  end
end

# Config settings to be used for each:
# - obey robots.txt
# - only list successfully retrieved URLs (status code 200)
# - only internal urls
# - only pages with our supported mimetypes (SearchgovUrl::SUPPORTED_CONTENT_TYPES)
# - omit query strings
#
def spidr
  # NOTE: to run this crawler, you'll need to comment out the cobweb gem and bundle install
  # to avoid class name conflicts

  # crawling options:
  # https://github.com/postmodern/spidr/blob/a197f2f030a4cf9a00244a3677014dfc633843d4/lib/spidr/agent.rb#L102
  options = {
    robots: true,
    user_agent: 'usasearch',
    #delay:
  }

  Spidr.site(@site, options) do |spider|
    spider.every_ok_page do |page|
      if supported_content_type(page.content_type)
        puts page.url
        @file << [page.url]
      end
    end
  end
end

def spider
  Spider.start_at(@site) do |s|
    s.add_url_check { |url| url =~ %r{^"#{@site}"}  }
    s.on :success do |a_url, resp, prior_url|
      puts "#{a_url}: #{resp.code}"
    end
  end
end

def cobweb
  # crawling options:
  # https://github.com/stewartmckee/cobweb#newoptions
  options = {
    crawl_id: Time.now.to_i,
    obey_robots: true,
    thread_count: 8,
    timeout: 30,
    valid_mime_types: SearchgovUrl::SUPPORTED_CONTENT_TYPES #this doesn't seem to work...
  }

  crawler = CobwebCrawler.new(options)

  stats = crawler.crawl(@site) do |page|
    # data/methods per page: https://github.com/stewartmckee/cobweb#data-returned-for-each-page--the-data-available-in-the-returned-hash-are
    if page[:status_code] == 200 && supported_content_type( page[:headers][:'content-type'].first )
      puts page[:url]
      @file << [page[:url]]
    end
  end
end

def medusa
  # crawling options:
  # https://github.com/brutuscat/medusa/blob/master/lib/medusa/core.rb#L28
  options = {
    discard_page_bodies: true,
    #delay: 1,
    obey_robots_txt: true,
    skip_query_strings: true,
    read_timeout: 30,
    threads: 8, #(default is 4),
    verbose: true
  }

  crawler = Medusa::Core.new(@site, options)
    application_extensions = %w{doc docx pdf xls xlsx ppt}
@doc_links = Set.new
   ##
   Medusa.crawl(@site, options) do |medusa|
     medusa.skip_links_like(/\.(#{(Fetchable::BLACKLISTED_EXTENSIONS + application_extensions ).join('|')})/i)

     medusa.on_every_page do |page|
   #   puts "Links: #{page.links}---------------"
      puts "#{page.url}, #{page.code}, time: #{page.response_time}, depth: #{page.depth}, redirected: #{page.redirect_to}"
      url = (page.redirect_to || page.url).to_s
      #data/methods per page: https://github.com/brutuscat/medusa/blob/master/lib/medusa/page.rb#L8
      if page.code == 200 && page.visited.nil? && supported_content_type(page.headers['content-type'])
        #puts page.url
      #  puts page.links #to file?
        SearchgovUrl.create(url: url) if @srsly
        links = page.links.map(&:to_s)
        links = links.select{|link| /\.(#{application_extensions.join("|")})/i === link }
        links.each{|link| @doc_links << link  }
        links.each{|link| puts "doc: '#{link}'".blue  }

        @file << [url] #, page.code, page.depth]
      end
    end

   end
    ##

   puts "DOC COUNT: #{@doc_links.count}" 
  if @srsly
   @doc_links.each do |link|
       puts "creating SU for '#{link}"
      SearchgovUrl.create(url: link)
    end

   SearchgovUrl.where(last_crawl_status: nil).find_each do |su|
     puts "indexing #{su}".yellow
      su.fetch
   end
  end
end

def supported_content_type(type)
  SearchgovUrl::SUPPORTED_CONTENT_TYPES.any? do |ok_type|
    %r{#{ok_type}} === type
  end
end
