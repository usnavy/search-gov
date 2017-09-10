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
# - page depth?
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
  crawler = CobwebCrawler.new(crawl_id: Time.now.to_i, obey_robots: true)
  stats = crawler.crawl(@site) do |page|
    puts "#{page[:url]} #{page[:status_code]}"
  end
end

def medusa
  Medusa.crawl(@site,
               discard_page_bodies: true,
               #delay: 1,
               obey_robots_txt: true,
               skip_query_strings: true
              ) do |medusa|
    medusa.on_every_page do |page|
      puts page.url
      @file << [(page.redirect_to || page.url), page.code, page.depth] if page.code == 200
    end
  end
end


=begin
Data Returned For Each Page
The data available in the returned hash are:

:url – url of the resource requested
:status_code – status code of the resource requested
:response_time – response time of the resource requested
:mime_type – content type of the resource
:character_set – character set of content determined from content type
:length – length of the content returned
:body – content of the resource
:location – location header if returned
:redirect_through – if your following redirects, any redirects are stored here detailing where you were redirected through to get to the final location
:headers – hash or the headers returned
:links – hash or links on the page split in to types
:links – urls from a tags within the resource
:images – urls from img tags within the resource
:related – urls from link tags
:scripts – urls from script tags
:styles – urls from within link tags with rel of stylesheet and from url() directives with stylesheets
=end
