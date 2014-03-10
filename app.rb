require 'sinatra'
require 'httparty'
require 'bank_holidays'

def tick_api(method, opts={})
  auth = { :email => ENV['TICK_USERNAME'], :password => ENV['TICK_PASSWORD'] }
  url = "https://#{ENV['TICK_SUBDOMAIN']}.tickspot.com/api/"
  HTTParty.get(url + method, :query => auth.merge(opts))
end

def tick_users
  tick_api('users')['users'].find_all{|u| !ENV['TICK_IGNORE'].include?(u['email'])}
end

# who hasn't done their 7.5 hours for `date`?
# returns array of usernames
def tick_naughty_users(date)
  # find everyone's time tracking entries
  period = { :start_date => d.to_s, :end_date => date.to_s }
  entries = tick_api('entries', period)['entries'].entries.group_by{ |d| d['user_id'] }

  # find users who haven't completed all their time
  users = []
  tick_users.each do |u|
    hours = entries[u['id']] || [{'hours' => 0}]
    total_hours = hours.collect{ |h| h['hours'] }.inject(:+)
    if total_hours < 7.5 
      username = u['email'].split('@').first
      users.push username
    end
  end
  
  users
end

def slack_message(text)
  url = "https://#{ENV['SLACK_SUBDOMAIN']}.slack.com/services/hooks/incoming-webhook?parse=full&token=#{ENV['SLACK_TOKEN']}"
  params = { :text => text, :link_names => 1 }
  HTTParty.post url, { :body => { :payload => params.to_json } }
end

configure do
  if settings.environment == :development
    # load configuration from .env file
    require 'dotenv'
    Dotenv.load
  end
end

get '/' do
  "I am tickbot."
end

get '/remind' do
  # don't remind for weekends
  return if [0,6].include?(Date.today.wday)

  # don't remind for bank holidays
  BankHolidays.all.each do |h|
    return if h.date.to_s == Date.today.to_s
  end
  
  # has anyone forgotten?
  if tick_naughty_users(Date.today).any?
    message = "Don't forget to submit your time to <https://#{ENV['TICK_SUBDOMAIN']}.tickspot.com|Tick>, #{remind_users.sort.join(' ')}."
    # hassle them on slack
    slack_message(message)
  else
    message = "There is no one left to remind. Well done, team!"
  end
  
  message
end

# will be run the day after to shame
get '/shame' do
  # don't remind on sundays and mondays
  return if [0,1].include?(Date.today.wday)

  # don't remind if yesteday was a bank holiday
  BankHolidays.all.each do |h|
    return if h.date.to_s == (Date.today-1).to_s
  end

  # has anyone forgotten?
  if tick_naughty_users(Date.today-1).any?
    message = "The following people should be ashamed of themselves for not completing their time on Tick yesterday: #{remind_users.sort.join(' ')}."
  else
    message = "You'll be pleased to hear that yesterday *everyone* completed their time on Tick. Well done, team!"
  end
  
  slack_message(message)
  message
end