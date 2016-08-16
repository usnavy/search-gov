class I14yFormattedQuery < FormattedQuery
  def initialize(user_query, options = {})
    super(options)
    user_query = downcase_except_operators(user_query)
    @query = query_with_sites(user_query)
  end

  private

  def query_with_sites(user_query)
    site_and_no_minus_site = user_query.include?('site:') && !user_query.include?('-site:')
    remaining_chars = QUERY_STRING_ALLOCATION - user_query.length
    domains = site_and_no_minus_site ? '' : fill_included_domains_to_remainder(remaining_chars)
    excluded = user_query.include?('site:') ? nil : fill_excluded_domains_to_remainder(remaining_chars - domains.length)
    sites = [user_query]
    sites << excluded unless excluded.blank?
    sites << domains unless domains.blank?
    sites.join(' ')
  end

  def fill_included_domains_to_remainder(remaining_chars)
    terms = @included_domains.blank? ? [] : domains_to_process.map { |d| "site:#{d}" }
    fill_included_terms_to_remainder(terms, '', remaining_chars)
  end

  def fill_excluded_domains_to_remainder(remaining_chars)
    terms = @excluded_domains.map { |d| "-site:#{d}" }
    fill_included_terms_to_remainder(terms, '', remaining_chars)
  end
end