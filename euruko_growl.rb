require 'rubygems'
require 'open-uri'
require 'twitter'
require 'growl.rb'
require 'daemon.rb'

class EurukoTweetObserver < Daemon::Base
  NOTIFICATION_TYPE = "ruby-growl Notification"
  UPDATE_INTERVAL   = 10 #seconds
  TITLE_PREFIX      = "Euruko Tweet: "
  TMP_DIR           = '/tmp'
  USER_EXCLUSION    = ['euruko_bot']
  
  def self.start
    @growl_engine = GrowlEngine.new
    growl("Starting up", "Hi. I will start to collecting euruko tweets for you.")
    @first_run = true
    @last_tweets = []
    
    loop do
      tweets = []
      Twitter::Search.new('euruko').each {|t| tweets << t unless USER_EXCLUSION.include?(t['from_user'])}
      
      filtered_tweets = filter_new_feeds(tweets)
      
      if @first_run
        growl_tweet(tweets.first) if tweets.first
      else
        filtered_tweets.each {|tweet| growl_tweet(tweet)}
      end
      
      @first_run    = false
      @last_tweets += filtered_tweets
      sleep UPDATE_INTERVAL
    end
  end

  def self.stop
    growl("Exiting", "Bye!")
  end
  
  def self.growl_tweet(tweet)
    growl(tweet['from_user'], tweet['text'], user_image(tweet))
  end
  
  def self.growl(title, body, icon = nil)
    @growl_engine.notify(title, body, icon)
    sleep 1
  end
  
  def self.filter_new_feeds(tweets)
    tweets.select {|t| @last_tweets.select{|lt| lt['id'] == t['id']}.size < 1}
  end
  
  def self.user_image(tweet)
    url = tweet['profile_image_url']
    user_file = "#{TMP_DIR}/__eurukotwitter_#{tweet['from_user']}.#{url.gsub(/.*\.([^\.]*)$/, '\1')}"
    open(user_file,"w").write(open(url).read) unless File.exist?(user_file)
    user_file
  end
end

EurukoTweetObserver.daemonize