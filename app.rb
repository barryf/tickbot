require 'sinatra'
require 'httparty'

def tick_api(method, opts={})
  auth = { :email => ENV['TICK_USERNAME'], :password => ENV['TICK_PASSWORD'] }
  url = "https://#{ENV['TICK_SUBDOMAIN']}.tickspot.com/api/"
  HTTParty.get(url + method, :query => auth.merge(opts))
end

def slack_message(text)
  url = "https://#{ENV['SLACK_SUBDOMAIN']}.slack.com/services/hooks/incoming-webhook?parse=full&token=#{ENV['SLACK_TOKEN']}"
  params = { :text => text, :link_names => 1 }
  HTTParty.post(url, { :body => { :payload => params.to_json } })
end

configure do
  # load configuration from .env file
  Dotenv.load
  # store the list of users from tick. TODO: cache this for 24 hours
  @@tick_users = tick_api('users')['users'].find_all{|u| !ENV['TICK_IGNORE'].include?(u['email'])}
end

get '/' do
  puts "I am tickbot."
end

get '/remind' do
  # find everyone's time tracking entries for today
  period = { :start_date => Date.today.to_s, :end_date => Date.today.to_s }
  entries = tick_api('entries', period)['entries'].entries.group_by{ |d| d['user_id'] }

  # find users to remind (who haven't completed all their time)
  remind_users = []
  @@tick_users.each do |u|
    hours = entries[u['id']] || [{'hours' => 0}]
    total_hours = hours.collect{ |h| h['hours'] }.inject(:+)
    if total_hours < 7.5 
      username = u['email'].split('@').first
      remind_users.push "@#{username}"
    end
  end

  # hassle them on slack
  slack_message("Don't forget to submit your time to <https://#{ENV['TICK_SUBDOMAIN']}.tickspot.com|Tick>, #{remind_users.sort.join(' ')}.") if remind_users.any?
end