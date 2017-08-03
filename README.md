# Message Menus API Sample for Ruby

[Message menus](https://api.slack.com/docs/message-menus) are a feature of the Slack Platform
that allow your Slack app to display a set of choices to users within a message.

This sample demonstrates building a coffeebot, which helps you customize a drink order using message menus.

![Demo](support/demo.gif "Demo")

Start by DMing the bot (or it will DM you when you join the team). Coffeebot introduces itself and gives you a message button to start a drink order. Coffees can be complicated so the bot gives you menus to make your drink just right (e.g. mocha, non fat milk, with a triple shot). It sends your completed order off to a channel where your baristas are standing by.

## Technical Requirements

This example is written in Ruby, specifically version 2.4.0. If you'd prefer an example in Node, [we have a version for that](https://github.com/slackapi/sample-message-menus-node).

First, make sure you have the right version of Ruby installed. You can run `ruby -v` to check your version. If it's anything less than 2.4.0, update and install a newer version. If you need to keep your old version and run multiple versions, you can use [rvm](https://github.com/rvm/rvm) or [rbenv](https://github.com/rbenv/rbenv).

We'll be using a few gems for our project:
- [Bundler](https://github.com/bundler/bundler) - the Ruby package manager we'll be using to make sure we have everything we need
- [Sinatra](https://github.com/sinatra/sinatra) - a lightweight web server for Ruby
- [slack-ruby-client](https://github.com/slack-ruby/slack-ruby-client/) - an awesome Ruby Slack client maintained by [dblock](https://github.com/dblock)
- [dotenv](https://github.com/bkeepers/dotenv) - a gem to load environment variables from our `.env`

Once you have the proper Ruby version set up, make sure you're in your project folder and then install [Bundler](https://github.com/bundler/bundler) by running `gem install bundler`.

Then you can install the required gems in our [Gemfile](Gemfile) by running `bundle install`. It should say `Bundle complete!` near the end of of the installation process if the gems were installed successfully.

## Setup
Once you have your Ruby version and gems configured, you should [create a Slack app](https://api.slack.com/slack-apps) and configure it 
with a bot user, event subscriptions, attachments, and an incoming webhook.

### Bot user

Click on the Bot user feature on your app configuration page. Assign it a username (such as
`@coffeebot`), enable it to be always online, and save changes.

### Event subscriptions

Turn on Event Subscriptions for the Slack app. You must input and verify a Request URL, and the easiest way to do this is to [use a development proxy as described in the Events API module](https://github.com/slackapi/node-slack-events-api#configuration). The application listens for events at the path `/slack/events`, so your request URL might look like `https://mymessagemenusample.ngrok.io/slack/events`

Create a subscription to the team event `team_join` and a bot event for `message.im`. Save your changes.

### Interactive Messages

Click on `Interactive Messages` on the left side navigation, and enable it. Input your *Request URL*. The app listens for events at the path `/slack/attachments`, so your URL may look like `https://mymessagemenusample.ngrok.io/slack/attachments`.

Save your changes.

_(there's a more complete explanation of Interactive Message configuration on the [Node Slack Interactive Messages module](https://github.com/slackapi/node-slack-interactive-messages#configuration))._

### Incoming webhook

Create a channel in your development team for finished coffee orders (such as `#coffee`). Add an incoming webhook to your app's configuration and select this team. Complete it by authorizing the webhook on your team.

### Environment variables

You should now have a Slack verification token (basic information), access token, and webhook URL (install app). Clone this application locally. Create a new file named `.env` within the directory and place these values as shown:

```
SLACK_VERIFICATION_TOKEN=xxxxxxxxxxxxxxxxxxx
SLACK_BOT_TOKEN=xoxb-000000000000-xxxxxxxxxxxxxxxxxxxxxxxx
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/xxxxxxxxx/yyyyyyyyy/zzzzzzzzzzzzzzzzzzzzzzzz
```

> 💡 *These environment variables will be loaded into our Sinatra project by one of the gems we installed earlier, [dotenv](https://github.com/bkeepers/dotenv).*

## Start it up

You can run the Sinatra application using `rackup`. When it runs, you should see a `HTTPServer#start` with the `pid` and `port` for your server (the default Port is `9292`).

Go ahead and DM `@coffeebot` to see the app in action!

### Getting Help

If you run into any trouble, take a look at [Slack's API documentation](https://api.slack.com), reach out to our awesome community of developers in the [Bot Developer Hangout](http://dev4slack.xoxco.com), or get in touch with our developer support team at [developers@slack.com](mailto:developers@slack.com). Happy developing! 🎉

