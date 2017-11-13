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

  task :crawl, [:domain, :crawler] => [:environment] do |_t, args|
    @domain = args[:domain]
    @site = "https://#{@domain}"
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
  Spidr.site(@site, { robots: true }) do |spider|
    spider.every_url { |url| puts url }
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
  #crawling options: https://github.com/stewartmckee/cobweb#newoptions
  crawler = CobwebCrawler.new(crawl_id: Time.now.to_i,
                              obey_robots: true,
                              valid_mime_types: SearchgovUrl::SUPPORTED_CONTENT_TYPES #this doesn't seem to work...
                             )

  stats = crawler.crawl(@site) do |page|
    #data/methods per page: https://github.com/stewartmckee/cobweb#data-returned-for-each-page--the-data-available-in-the-returned-hash-are
    if page[:status_code] == 200 && SearchgovUrl::SUPPORTED_CONTENT_TYPES.any?{|type| %r{#{type}} === page[:headers][:'content-type'].first}
      puts page[:url] #{page[:status_code]}"
      @file << [page[:url]]
    end
  end
end

def medusa
  #crawling options:
  #https://github.com/brutuscat/medusa/blob/master/lib/medusa/core.rb#L28
  Medusa.crawl(@site,
               discard_page_bodies: true,
               #delay: 1,
               obey_robots_txt: true,
               skip_query_strings: true,
               #threads: 4
              ) do |medusa|
    medusa.on_every_page do |page|
      #data/methods per page: https://github.com/brutuscat/medusa/blob/master/lib/medusa/page.rb#L8
      if page.code == 200 && page.visited.nil? #&& SearchgovUrl::SUPPORTED_CONTENT_TYPES.any?(page.headers['Content-Type'])
        puts page.url
        @file << [(page.redirect_to || page.url)] #, page.code, page.depth]
      end
    end

    # List count of unique pages
    #medusa.after_crawl do |pages|
     # puts pages.uniq!.size
    #end
  end
end
