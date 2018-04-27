class Admin::SearchgovDomainsController < Admin::AdminController
  active_scaffold :searchgov_domain do |config|
    config.label = 'Search.gov Domains'
    config.actions.exclude :delete
    #config.actions.add :field_search
    config.create.columns = [:domain]
    config.columns = [:domain, :status, :urls_count, :unfetched_urls_count]

  end
end
