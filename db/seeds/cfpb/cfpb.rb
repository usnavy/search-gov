cfpb = Affiliate.create!(name: "cfpb_#{Time.now.to_i}", display_name: "cfpb_#{Time.now.to_i}", gets_blended_results: true)
puts "Created affiliate: #{cfpb.name}"

urls = CSV.read("#{Rails.root}/db/seeds/cfpb/cfpb_top_urls.csv").map(&:first)

urls.each { |url| cfpb.indexed_documents.create(url: url) }
puts "Created #{cfpb.indexed_documents.count} indexed documents"

puts "Fetching docs...."
cfpb.indexed_documents.each { |doc| doc.fetch }
