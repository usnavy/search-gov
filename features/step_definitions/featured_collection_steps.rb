Given /^the following featured collections exist for the affiliate "([^"]*)":$/ do |affiliate_name, table|
  affiliate = Affiliate.find_by_name(affiliate_name)
  table.hashes.each do |attrs|
    publish_start_on = attrs[:publish_start_on]
    if publish_start_on.blank? || publish_start_on == 'today'
      publish_start_on = Date.current
    elsif publish_start_on =~ /^[a-zA-Z_]+$/
      publish_start_on = Date.current.send(publish_start_on.to_sym)
    end
    attrs[:publish_start_on] = publish_start_on

    publish_end_on = attrs[:publish_end_on]
    if publish_end_on == 'today'
      publish_end_on = Date.current
    elsif publish_end_on =~ /^[a-zA-Z_]+$/
      publish_end_on = Date.current.send(publish_end_on.to_sym)
    end
    attrs[:publish_end_on] = publish_end_on

    attrs[:layout] ||= FeaturedCollection::LAYOUTS[0]

    if attrs[:keywords].present?
      index = -1
      keyword_attributes = attrs[:keywords].split(',').map do |keyword|
        index += 1
        [index.to_s, { value: keyword }]
      end
      attrs[:featured_collection_keywords_attributes] = Hash[keyword_attributes]
    end

    affiliate.featured_collections.create!(attrs.except('keywords'))
  end
end

Then /^I should see "([^"]*)" featured collections$/ do |count|
  page.should have_selector(".featured-collection-list .row-item", :count => count)
end

Then /^the following featured collection keywords exist for featured collection titled "([^"]*)":$/ do |featured_collection_title, table|
  featured_collection = FeaturedCollection.find_by_title(featured_collection_title)
  featured_collection.featured_collection_keywords.delete_all
  table.hashes.each do |hash|
    featured_collection.featured_collection_keywords.build(:value => hash['value'])
  end
  featured_collection.save!
end

Then /^I should see a featured collection title with "([^"]*)" highlighted$/ do |highlighted|
  page.should have_selector(".featured-collection h2 strong", :text => highlighted)
end

Then /^I should see a featured collection link title with "([^"]*)" highlighted$/ do |highlighted|
  page.should have_selector(".featured-collection ul strong", :text => highlighted)
end

Then /^I should see a featured collection image section$/ do
  page.should have_selector(".featured-collection .image")
end

Then /^I should not see a featured collection image section$/ do
  page.should_not have_selector(".featured-collection .image")
end

When /^there are (\d+) featured collections exist with the following attributes:$/ do |count, table|
  table.hashes.each do |hash|
    count.to_i.times do |i|
      featured_collection = FeaturedCollection.new(
          :title => hash['title'] || "random title #{i + 1}",
          :title_url => hash['title_url'] || "http://example/random_content#{i + 1}.html",
          :locale => hash['locale'],
          :status => hash['status'] || "active",
          :layout => hash['layout'] || 'one column',
          :publish_start_on => Date.current)
      featured_collection.featured_collection_keywords.build(:value => "keyword value #{i + 1}")
      featured_collection.save!
    end
  end
end

Given /^there are (\d+) featured collections exist for the affiliate "([^"]*)":$/ do |count, affiliate_name, table|
  affiliate = Affiliate.find_by_name(affiliate_name)
  table.hashes.each do |hash|
    count.to_i.times do |i|
      featured_collection = affiliate.featured_collections.build(
          :title => hash['title'] || "random title #{i + 1}",
          :title_url => hash['title_url'] || "http://example/random_content#{i + 1}.html",
          :locale => hash['locale'],
          :status => hash['status'] || "active",
          :layout => hash['layout'] || 'one column',
          :publish_start_on => Date.current)
      featured_collection.featured_collection_keywords.build(:value => "keyword value #{i + 1}")
      featured_collection.save!
    end
  end
end

Given /^the following featured collection links exist for featured collection titled "([^"]*)":$/ do |featured_collection_title, table|
  featured_collection = FeaturedCollection.find_by_title(featured_collection_title)
  table.hashes.each_with_index do |hash, i|
    featured_collection.featured_collection_links.build(:title => hash[:title], :url => hash[:url], :position => hash[:position] || i)
  end
  featured_collection.save!
end

Given /^all featured collections are indexed$/ do
  FeaturedCollection.reindex
end

Then /^I should see a link to "([^"]*)" with url for "([^"]*)" on the (left|right) featured collection link list$/ do |link_title, url, position|
  page.should have_selector(".featured-collection li.#{position} a", :text => link_title, :href => url)
end

When /^(?:|I )add the following best bets graphics links:$/ do |table|
  links_count = page.all(:css, '.links .title').count
  table.hashes.each_with_index do |hash, index|
    click_link 'Add Another Link'
    link_title_label = "Link Title #{links_count + index + 1}"
    find('label', text: "#{link_title_label}")
    fill_in(link_title_label, with: hash[:title])
    link_url_label = "Link URL #{links_count + index + 1}"
    find('label', text: "#{link_url_label}")
    fill_in(link_url_label, with: hash[:url])
  end
end
