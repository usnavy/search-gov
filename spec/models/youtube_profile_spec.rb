require 'spec/spec_helper'

describe YoutubeProfile do
  fixtures :affiliates
  before do
    @affiliate = affiliates(:basic_affiliate)
    @valid_attributes = {
      :username => 'USAgency',
      :affiliate => @affiliate
    }
  end

  def managed_feeds
    RssFeed.where(:affiliate_id => @affiliate.id,
                  :is_managed => true,
                  :is_video => true)
  end

  it { should validate_presence_of :username }
  it { should validate_presence_of :affiliate_id }

  it "should create a new instance given valid attributes" do
    Kernel.stub(:open) do |arg|
      case arg
      when YoutubeProfile.youtube_url('USAgency')
        File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
      end
    end

    YoutubeProfile.create!(@valid_attributes)
    should validate_uniqueness_of(:username).scoped_to(:affiliate_id).with_message('has already been added')
  end

  it "should strip whitespace from the ends of the username" do
    Kernel.stub(:open) do |arg|
      case arg
      when YoutubeProfile.youtube_url('whitehouse')
        File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
      end
    end

    profile = YoutubeProfile.create!(:username => '    whitehouse   ', :affiliate => @affiliate)
    profile.username.should == 'whitehouse'
  end

  it "should create a corresponding Video RSS feed on create" do
    @affiliate.rss_feeds.destroy_all
    managed_feeds.should be_empty

    Kernel.stub(:open) do |arg|
      case arg
      when YoutubeProfile.youtube_url('USAgency')
        File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
      end
    end

    profile = YoutubeProfile.create!(@valid_attributes)
    managed_feeds.should_not be_empty
    managed_feeds.first.name.should == 'Videos'
    managed_feeds.first.rss_feed_urls.should_not be_empty
    managed_feeds.first.rss_feed_urls.first.url.should == profile.url
  end

  it "should add new YoutubeProfiles for the same affiliate to the Videos rss feed group if it exists" do
    @affiliate.rss_feeds.destroy_all
    managed_feeds.should be_empty

    Kernel.stub(:open) do |arg|
      case arg
      when YoutubeProfile.youtube_url('USAgency'), YoutubeProfile.youtube_url('AnotherUSAgency')
        File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
      end
    end

    profile = YoutubeProfile.create!(@valid_attributes)
    managed_feeds.count.should == 1
    managed_feeds.first.name.should == 'Videos'
    managed_feeds.first.rss_feed_urls.count.should == 1

    managed_feeds.first.update_attributes!(:name => 'YouTube Videos')

    second_profile = YoutubeProfile.create!(:username => 'AnotherUSAgency', :affiliate => @affiliate)
    managed_feeds.count.should == 1
    managed_feeds.first.name.should == 'YouTube Videos'
    urls = managed_feeds.first.rss_feed_urls.collect(&:url)
    urls.count.should == 2
    urls.should include(profile.url, second_profile.url)
  end

  it "should synchronize managed youtube rss feed when the profile is deleted" do
    @affiliate.rss_feeds.destroy_all

    Kernel.stub(:open) do |arg|
      case arg
      when YoutubeProfile.youtube_url('USAgency')
        File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
      end
    end

    profile = YoutubeProfile.create!(@valid_attributes)
    rss_feed = mock_model(RssFeed)

    profile.stub_chain('affiliate.rss_feeds.managed.videos.first').and_return(rss_feed)
    rss_feed.should_receive(:synchronize_youtube_urls!)
    profile.destroy
  end

  it "should synchronize managed youtube rss feed the associated rss feed if the username is changed" do
    @affiliate.rss_feeds.destroy_all

    Kernel.stub(:open) do |arg|
      case arg
      when YoutubeProfile.youtube_url('USAgency'), YoutubeProfile.youtube_url('America')
        File.open(Rails.root.to_s + '/spec/fixtures/rss/youtube.xml')
      end
    end

    profile = YoutubeProfile.create!(@valid_attributes)
    rss_feed = mock_model(RssFeed)

    profile.stub_chain('affiliate.rss_feeds.managed.videos.first').and_return(rss_feed)
    rss_feed.should_receive(:synchronize_youtube_urls!)
    profile.update_attributes!(:username => 'America')
  end
end
