class Admin::SearchgovDomainsController < Admin::AdminController
  active_scaffold :searchgov_domain do |config|
    config.label = 'Search.gov Domains'
    config.actions =[:create, :list, :search, :show, :export]
    config.create.columns = [:domain]
    config.columns = [:domain, :status, :urls_count, :unfetched_urls_count, :created_at, :updated_at]
  end
end
