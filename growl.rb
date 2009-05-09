require 'ruby-growl'


class GrowlEngine
  PASS_FILE_NAME = "#{File.dirname(__FILE__)}/growl_pass.txt"
  
  def initialize
    
    pass = nil
    File.open(PASS_FILE_NAME, 'r') {|f| pass = f.gets.strip.chomp} if File.exist?(PASS_FILE_NAME)
    
    args =  ["localhost", "ruby-growl", ["ruby-growl Notification"]] + (pass ? [nil, pass] : [])
    @g = Growl.new(*args)
  end
  
  def notify(title, body, icon = nil)
    @g.notify "ruby-growl Notification", title, body
  end
end