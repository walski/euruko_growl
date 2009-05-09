require 'rubygems'
require 'growl'
require 'twitter'
require 'daemon.rb'
require 'open-uri'

class Password
  FILE_NAME = "#{File.dirname(__FILE__)}/growl_pass.txt"
  
  def self.from_file
    return nil unless File.exists?(FILE_NAME)
    File.open(FILE_NAME) do |file|
      return file.gets.strip.chomp
    end
  end
end

class EurukoTweetObserver < Daemon::Base
  NOTIFICATION_TYPE = "ruby-growl Notification"
  UPDATE_INTERVAL   = 10 #seconds
  TITLE_PREFIX      = "Euruko Tweet: "
  TMP_DIR           = '/tmp'
  USER_EXCLUSION    = ['euruko_bot']
  
  def self.start
    growl_pass = Password::from_file
    args = ["localhost", "Euruko Twitter", ["ruby-growl Notification"]]
    args += [nil, growl_pass] if growl_pass
    
    @first_run = true
    @last_tweets = []
    
    loop do
      tweets = []
      Twitter::Search.new('euruko').each {|t| tweets << t unless USER_EXCLUSION.include?(t['from_user'])}

      unless @first_run
        filter_new_feeds(tweets).each do |tweet|
          growl_tweet(tweet)
        end
      else
        growl_tweet(tweets.first) if tweets.first
      end
      
      @first_run = false
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