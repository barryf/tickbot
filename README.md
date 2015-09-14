# tickbot

Tickbot is a simple app to remind your team to complete their time tracking for the day. It also shames (in a friendly way) those who forgot to do so the day before.

We use [Tick](http://www.tickspot.com) for our time tracking and [Slack](https://slack.com) as our team chat room: tickbot was specifically written to work with both.

## Setup

The easiest way to get started is to deploy to [Heroku](http://heroku.com). You'll need to add the following config keys using `heroku config:add KEY=VALUE`.

Key|Description
---|-----------
`TICK_USERNAME`|Tick username/email address
`TICK_PASSWORD`|Tick password (I'd suggest creating a separate non-admin account)
`TICK_SUBDOMAIN`|Subdomain you chose when setting up Tick, e.g. `globalpersonals`
`TICK_IGNORE`|Comma-separated list of email addresses for any Tick accounts you want to ignore, e.g. managers or part-time developers
`SLACK_TOKEN`|Token for your Slack integration, e.g. `xoxp-...`
`SLACK_SUBDOMAIN`|Subdomain for your Slack team, e.g. `globaldev`

Alternatively, if you're hosting it yourself, create a `.env` file and the [Dotenv](https://github.com/bkeepers/dotenv) gem will pick up your config.

## Usage

Every afternoon at 5:30pm (or whenever your team usually leave):

    $ rake remind

Every morning at 7am:

    $ rake shame

Alternatively, you can Curl the /remind or /shame URLs using the Sinatra app.

## Licence

(The MIT License)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
