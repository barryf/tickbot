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
# returns array of usernames prefixed with @
def tick_naughty_users(date)
  # find everyone's time tracking entries
  period = { :start_date => date.to_s, :end_date => date.to_s }
  entries = tick_api('entries', period)['entries'].entries.group_by{ |d| d['user_id'] }

  # find users who haven't completed all their time
  users = []
  tick_users.each do |u|
    hours = entries[u['id']] || [{'hours' => 0}]
    total_hours = hours.collect{ |h| h['hours'] }.inject(:+)
    if total_hours < 7.45
      username = u['email'].split('@').first
      users.push "@" + username
    end
  end
  users
end

def slack_message(channel, text)
  url = "https://slack.com/api/chat.postMessage"
  params = { :token => ENV["SLACK_TOKEN"],
             :text => text,
             :link_names => 1,
             :channel => channel,
             :username => "tickbot",
             :icon_url => "http://i.imgur.com/46JvWOZ.png" }
  HTTParty.post(url, :body => params)
end

def remind
  # don't remind for weekends
  return if [0,6].include?(Date.today.wday)

  # don't remind for bank holidays
  BankHolidays.all.each do |h|
    return if h.date.to_s == Date.today.to_s
  end

  # has anyone forgotten?
  users = tick_naughty_users(Date.today)

  users.each do |user|
    msg = "Don't forget to submit your time to <https://#{ENV['TICK_SUBDOMAIN']}.tickspot.com|Tick> for today, #{user}."
    slack_message(user, msg)
  end

  if users.any?
    "These team members still need to complete their Tick: #{users.sort.join(' ')}"
  else
    "There is no one left to remind. Well done, team!"
  end
end

def shame
  # don't shame on sundays and mondays
  return if [0,1].include?(Date.today.wday)

  # don't shame if yesterday was a bank holiday
  BankHolidays.all.each do |h|
    return if h.date.to_s == (Date.today-1).to_s
  end

  # did anyone forget yesterday?
  users = tick_naughty_users(Date.today-1)
  if users.any?
    message = "The following people should be ashamed of themselves for not completing their time on Tick yesterday: #{users.sort.join(' ')}"
  else
    message = "You'll be pleased to hear that yesterday *everyone* completed their time on Tick. Well done, team!"
  end
  slack_message("#" + ENV['SLACK_CHANNEL'], message)

  message
end
