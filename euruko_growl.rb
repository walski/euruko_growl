require 'rubygems'
require 'open-uri'
require 'twitter'
#Gem: http://github.com/visionmedia/growl/tree/master
require 'growl'
require 'daemon.rb'

class EurukoTweetObserver < Daemon::Base
  NOTIFICATION_TYPE = "ruby-growl Notification"
  UPDATE_INTERVAL   = 60 #seconds
  TITLE_PREFIX      = "Euruko Tweet: "
  TMP_DIR           = '/tmp'
  USER_EXCLUSION    = ['euruko_bot']
  
  def self.start
    @first_run = true
    @last_tweets = []
    
    loop do
      tweets = []
      Twitter::Search.new('euruko').each {|t| tweets << t unless USER_EXCLUSION.include?(t['from_user'])}
      if @first_run
        growl_tweet(tweets.first) if tweets.first
      else
        filter_new_feeds(tweets).each {|tweet| growl_tweet(tweet)}
      end
      
      @first_run    = false
      @last_tweets += tweets
      sleep UPDATE_INTERVAL
    end
  end

  def self.stop
    Growl.notify "Bye!", :title => "#{TITLE_PREFIX}Exiting"
  end
  
  def self.growl_tweet(tweet)
    Growl.notify tweet['text'], :icon => user_image(tweet), :title => "#{TITLE_PREFIX}#{tweet['from_user']}"
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