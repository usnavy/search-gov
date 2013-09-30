Given /^the following Boosted Content Keywords exist for the entry titled "([^\"]*)"$/ do |title, table|
  boosted_content = BoostedContent.find_by_title title
  boosted_content.boosted_content_keywords.delete_all
  table.hashes.each do |hash|
    boosted_content.boosted_content_keywords.build(:value => hash['value'])
  end
  boosted_content.save!
  boosted_content.index
  Sunspot.commit
end

Given /^the following Boosted Content entries exist for the affiliate "([^\"]*)"$/ do |aff_name, table|
  affiliate = Affiliate.find_by_name aff_name
  sites = table.hashes.collect do |hash|
    hash[:affiliate] = affiliate
    hash[:status] = 'active' if hash[:status].blank?
    publish_start_on = hash[:publish_start_on]
    publish_start_on = Date.current if publish_start_on == 'today'
    publish_start_on = Date.current.send(publish_start_on.to_sym) if publish_start_on.present? and publish_start_on =~ /^[a-zA-Z_]*$/
    publish_start_on = Date.current if publish_start_on.blank?
    hash[:publish_start_on] = publish_start_on

    publish_end_on = hash[:publish_end_on]
    publish_end_on = Date.current if publish_end_on == 'today'
    publish_end_on = Date.current.send(publish_end_on.to_sym) if publish_end_on.present? and publish_end_on =~ /^[a-zA-Z_]*$/
    hash[:publish_end_on] = publish_end_on

    BoostedContent.create! hash
  end
  Sunspot.index(sites) # because BoostedContent has auto indexing turned off for saves/creates
end

When /^I press "([^\"]*)" on the (\d+)(?:st|nd|rd|th) boosted content entry$/ do |button, pos|
  within(".boosted-content-list table tbody tr.row-item:nth-child(#{pos.to_i + 1})") { click_button(button) }
end

When /^there are (\d+) Boosted Content entries exist for the affiliate "([^\"]*)":$/ do |count, affiliate_name, table|
  affiliate = Affiliate.find_by_name(affiliate_name)
  boosted_contents = []
  table.hashes.each do |hash|
    publish_start_on = hash['publish_start_on']
    publish_start_on = Date.current if publish_start_on == 'today'
    publish_start_on = Date.current.send(publish_start_on.to_sym) if publish_start_on.present? and publish_start_on =~ /^[a-zA-Z_]*$/
    publish_start_on = Date.current if publish_start_on.blank?

    publish_end_on = hash['publish_end_on']
    publish_end_on = Date.current if publish_end_on == 'today'
    publish_end_on = Date.current.send(publish_end_on.to_sym) if publish_end_on.present? and publish_end_on =~ /^[a-zA-Z_]*$/

    count.to_i.times do |i|
      boosted_contents << affiliate.boosted_contents.create!(:title => hash["title"] || "title #{i + 1}",
                                                             :description => hash["description"] || "description#{i + 1}",
                                                             :url => hash["url"] || "http://aff.gov/#{i + 1}/#{Time.now.to_f}.html",
                                                             :status => hash['status'] || 'active',
                                                             :publish_start_on => publish_start_on,
                                                             :publish_end_on => publish_end_on)
    end
  end
  Sunspot.index(boosted_contents) # because BoostedContent has auto indexing turned off for saves/creates
end

Then /^I should see (\d+) Boosted Content Entries$/ do |count|
  page.should have_selector(".boosted-content-list .row-item", :count => count)
end

And /^I should see boosted content keyword "([^\"]*)"$/ do |keyword|
  page.should have_selector(".keywords span", :text => keyword)
end
