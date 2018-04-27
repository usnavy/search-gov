class Admin::SearchgovUrlsController < Admin::AdminController
  active_scaffold :searchgov_url do |config|
    config.label = 'Search.gov URLs'
   # config.actions.exclude :delete
    config.columns = [:url, :last_crawl_status, :last_crawled_at]
    config.actions.exclude :search
    config.actions.add :field_search
    #config.field_search.text_search = :start
    config.field_search.columns = :url

  end
end
