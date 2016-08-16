class ApiI14yDocsSearch < ApiI14ySearch
  include ApiDocsSearch

  def default_module_tag
    'I14Y'.freeze
  end

  def search
    formatted_query_instance = I14yFormattedQuery.new(@query, domains_scope_options)
    @query = formatted_query_instance.query
    super
  end

  def as_json_result_hash(result)
    {
      title: result.title,
      url: result.link,
      snippet: result.content
    }
  end
end