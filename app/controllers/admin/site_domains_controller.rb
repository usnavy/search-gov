class Admin::SiteDomainsController < Admin::AdminController
  active_scaffold :site_domain do |config|
    config.actions.exclude :show, :create, :update
    config.action_links.add 'index_into_searchgov', label: 'Index',  type: :member, position: :after
  end

  def index_into_searchgov
    domain = SiteDomain.find(params[:id]).domain
    Resque.enqueue_with_priority(:high, SearchgovIndexer, domain)
    render text: "AWYISS. You are indexing #{domain} into Search.gov. Please be patient..."
  end
end
=begin
  def news_items
    redirect_to admin_news_items_path(rss_feed_url_id: params[:id])
  end
=end
