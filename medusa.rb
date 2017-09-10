require 'medusa'
Medusa.crawl('https://www.uscis.gov', :discard_page_bodies => true) do |medusa|

  medusa.on_every_page do |page|
   # if options.relative
      
   # else
      puts page.url
   # end
  end

end
