ActiveRecord::Base.logger = nil

cfpb = Affiliate.create!(name: "cfpb_#{Time.now.to_i}", display_name: "cfpb_#{Time.now.to_i}", gets_blended_results: true)
puts "Created affiliate: #{cfpb.name}"

urls = CSV.read("#{Rails.root}/db/seeds/cfpb/cfpb_top_urls.csv").map(&:first)


urls.each do |url|
 begin
   cfpb.indexed_documents.create!(url: url)
 rescue StandardError => e
   puts "Unable to create doc for #{url}\nError: #{e}"
 end
end

puts "Created #{cfpb.indexed_documents.count} indexed documents"

cfpb.indexed_documents.each do |doc| 
  doc.fetch
end
