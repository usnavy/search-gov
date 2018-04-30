class Admin::SearchgovUrlsController < Admin::AdminController
  active_scaffold :searchgov_url do |config|
    config.label = 'Search.gov URLs'
    config.actions = [:list, :search]
    config.columns = [:url, :last_crawl_status, :last_crawled_at]
    config.search.text_search = :start
    config.search.columns = :url
  end
end
