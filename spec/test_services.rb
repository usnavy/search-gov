module TestServices
  extend self

  REDIS_TEST_PID = "#{Rails.root}/tmp/pids/redis-test.pid".freeze
  REDIS_CACHE_PATH = "#{Rails.root}/tmp/cache".freeze
  REDIS_PIDS_PATH = "#{Rails.root}/tmp/pids".freeze
  TEST_DUMP_RDB = 'dump.rdb'.freeze

  def create_es_indexes
    Dir[Rails.root.join('app/models/elastic_*.rb').to_s].each do |filename|
      klass = File.basename(filename, '.rb').camelize.constantize
      klass.recreate_index if klass.kind_of?(Indexable) and klass != ElasticBlended
    end
    logstash_index_range.each do |date|
      ES::client_reader.indices.delete(index: "logstash-#{date.strftime("%Y.%m.%d")}") rescue Elasticsearch::Transport::Transport::Errors::NotFound
      ES::client_reader.indices.create(index: "logstash-#{date.strftime("%Y.%m.%d")}")
      ES::client_reader.indices.put_alias(index: "logstash-#{date.strftime("%Y.%m.%d")}", name: "human-logstash-#{date.strftime("%Y.%m.%d")}")
    end
  end

  def delete_es_indexes
    ES::client_reader.indices.delete(index: "test-usasearch-*")
    ES::client_reader.indices.delete(index: "test-i14y-*")
    logstash_index_range.each do |date|
      ES::client_reader.indices.delete(index: "logstash-#{date.strftime("%Y.%m.%d")}")
    end
  rescue Exception => e
  end

  def logstash_index_range
    end_date = Date.current
    start_date = end_date - 10.days
    start_date..end_date
  end
end
