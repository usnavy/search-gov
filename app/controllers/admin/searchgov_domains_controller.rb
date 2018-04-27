class Admin::SearchgovDomainsController < Admin::AdminController
  active_scaffold :searchgov_domain do |config|
    config.label = 'Search.gov Domains'
    config.actions.exclude :delete
    #config.actions.add :field_search
    config.create.columns = [:domain]
    config.columns = [:domain, :status, :clean_urls]

  end
end
