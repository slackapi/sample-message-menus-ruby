require 'sinatra/base'
require 'dotenv/load'
require 'slack-ruby-client'
require 'json'
require 'uri'
require 'net/http'
require_relative 'Menu'

Slack.configure do |config|
  config.token = ENV['SLACK_BOT_TOKEN']
  fail 'Missing API token' unless config.token
end

# Slack Ruby client
$client = Slack::Web::Client.new
# Orders object
$orders = {}
# Menu class imported from Menu.rb
Menu.new

class API < Sinatra::Base
  # Send response of message to response_url
  def self.send_response(response_url, msg)
    url = URI.parse(response_url)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(url)
    request['content-type'] = 'application/json'
    request.body = JSON[msg]
    response = http.request(request)
  end

  post '/slack/events' do
    request_data = JSON.parse(request.body.read)

    case request_data['type']
      when 'url_verification'
        # URL Verification event with challenge parameter
        request_data['challenge']
      when 'event_callback'
        # Verify requests
        if request_data['token'] != ENV['SLACK_VERIFICATION_TOKEN']
          return
        end

        team_id = request_data['team_id']
        event_data = request_data['event']
        case event_data['type']
          # Team Join event
          when 'team_join'
            Events.user_join(team_id, event_data)
          # Message IM event
          when 'message'
            if event_data['subtype'] == 'bot_message' || event_data['subtype'] == 'message_changed'
              return
            end
            Events.message(team_id, event_data)
          else
            puts "Unexpected events\n"
        end
        status 200
    end
  end

  post '/slack/attachments' do

    request.body.rewind
    request_data = request.body.read

    # Convert
    request_data = URI.decode_www_form_component(request_data, enc=Encoding::UTF_8)

    # Parse and remove "payload=" from beginning of string
    request_data = JSON.parse(request_data.sub!('payload=', ''))
    url = request_data['response_url']

    case request_data['callback_id']
      # Start order callback
      when 'order:start'
        # Modify message to acknowledge
        msg = request_data['original_message']
        msg['text'] = ':white_check_mark: I\'m getting an order started for you.'
        msg['attachments'] = []
        API.send_response(url, msg)

        Bot.start_order(request_data['user']['id'], request_data['original_message'], url)

      # Select type callback
      when 'order:select_type'
        selected = Bot.find_selected_option(
          request_data['original_message'], 
          'order:select_type', 
          request_data['actions'][0]['selected_options'][0]['value']
        )
        updated = Bot.acknowledge_action_from_message(
          request_data['original_message'], 
          'order:select_type', 
          "You chose a #{selected["text"].downcase}"
        )
        url = request_data['response_url']
        API.send_response(url, updated)

        attach = Bot.select_type_for_order(request_data['user']['id'], selected['value'])
        order = Bot.summarize_order($orders[request_data['user']['id']])
        updated['attachments'].push(attach)
        updated['text'] = "Working on your #{order}"
        API.send_response(url, updated)

      # Select option callback
      when 'order:select_option'
        option_name = request_data['actions'][0]['name']
        selected = Bot.find_selected_option(
          request_data['original_message'], 
          'order:select_option', 
          request_data['actions'][0]['selected_options'][0]['value']
        )
        updated = Bot.acknowledge_action_from_message(
          request_data['original_message'], 
          'order:select_option', 
          "You chose #{selected["text"].downcase}"
        )
        attach = Bot.select_option_for_order(
          request_data['user']['id'], 
          option_name, 
          selected['value']
        )
        order_text = Bot.summarize_order($orders[request_data['user']['id']])

        if !Bot.order_is_complete($orders[request_data['user']['id']])
          updated['text'] = "Working on your #{order_text}"
          updated['attachments'].push(attach)
        else
          updated['text'] = attach
        end

        API.send_response(request_data['response_url'], updated)
      else
    end
    status 200
  end
end


class Events
  # Handle user join event
  def self.user_join(team_id, event_data)
    if event_data['user']['id']
      user_id = event_data['user']['id']
      # Sent intro message via DM
      Bot.intro(user_id)
    end
  end

  # Handle message IM event
  def self.message(team_id, event_data)
    if event_data['user']
      user_id = event_data['user']
      # Handle direct message
      Bot.handle_direct_message(event_data)
    end
    # Handle direct messages
  end
end

class Bot

  # Send intro message to start order
  def self.intro(user_id)
    # Open IM
    res = $client.im_open(user: user_id)
    # Attachment with order:start callback ID
    attachments = [{
      color: '#5A352D',
      title: 'How can I help you?',
      callback_id: 'order:start',
      actions: [
        {
          name: 'start',
          text: 'Start a coffee order',
          type: 'button',
          value: 'order:start',
         }]}]
    if !res.channel.id.nil?
      # Send message
      $client.chat_postMessage(
        channel: res.channel.id, 
        text: 'I am coffeebot, and I\'m here to help bring you fresh coffee :coffee:, made to order.', 
        attachments: attachments.to_json
      )
    end
  end

  def self.start_order(user_id, msg, url)
    # Check if order already exists
    if $orders[user_id].nil?
      # Starts new order
      options_list = Menu.list_of_types
      $orders[user_id] = {
        options: {}
      }
      # Sends menu with order:select_type callback
      msg = {
        text: 'Great! What can I get started for you?',
        attachments: [{
          color: '#5A352D',
          callback_id: 'order:select_type',
          text: '',
          actions: [{
            name: 'select_type',
            type: 'select',
            options: options_list
          }]
        }]
      }
    else
      # Order already exists, don't start new one
      msg = {
        text: "I\'m already working on an order for you, please be patient",
        replace_original: false
      }
    end
    # Send message
    API.send_response(url, msg)
  end

  # Find next option for order item
  def self.next_option_for_order(order)
    item = Menu.items.find { |i| i[:id] == order['type']}
    if item.nil?
      return
    end
    return item[:options].find {|o| !order[:options].key?(o) }
  end

  # Send user options to select from
  def self.option_selection_for_order(user_id)
    order = $orders[user_id]
    option_id = self.next_option_for_order(order)
    type_list = Menu.list_of_choices_for_option(option_id)
    attach = {
        color: '#5A352D',
        callback_id: 'order:select_option',
        text: "Which #{option_id} would you like?",
        actions: [{
          name: option_id,
          type: 'select',
          options: type_list
        }]
    }
    return attach
  end

  # Determine whether option is done or needs option selection
  def self.select_type_for_order(user_id, item_id)
    order = $orders[user_id]
    if order.nil?
      return
    end

    order['type'] = item_id
    if !order_is_complete(order)
      return self.option_selection_for_order(user_id)
    end
    
    return self.finish_order(order)
  end

  # Select option for user_id order
  def self.select_option_for_order(user_id, option_id, option_value)
    order = $orders[user_id]
    if order.nil?
      return
    end

    order[:options][option_id] = option_value

    if !order_is_complete(order)
      return self.option_selection_for_order(user_id)
    end
    return self.finish_order(user_id)
  end

  # Finish order for user_id
  def self.finish_order(user_id)
    order = $orders[user_id]
    order_item = Menu.items.find { |i| i[:id] == order['type']}[:name]

    msg_fields = [{
        title: 'Drink',
        value: "#{order_item}"
      }]

    order[:options].map { |c, n| 
      choice_name = Menu.choice_name_for_id(c, n)
      msg_fields.push({ title: c.capitalize, value: choice_name })
    }

    order_str = summarize_order($orders[user_id])
    final_order = {
        text: "<@#{user_id}> has submitted a new coffee order.",
        attachments: [{
            color: '#5A352D',
            title: 'Order details',
            text: "#{order_str}",
            fields: msg_fields
          }]
      }

    API.send_response(ENV['SLACK_WEBHOOK_URL'], final_order)
    return "Your order of #{order_str} is coming right up!"
  end

  # Find attachment with action_callback_id
  def self.find_attachment(message, action_callback_id)
    message['attachments'].find { |a| a['callback_id'] == action_callback_id}
  end

  # Find option that was selected
  def self.find_selected_option(original_message, action_callback_id, selected_value)
    attachment = self.find_attachment(original_message, action_callback_id)
    return attachment['actions'][0]['options'].find { |o| o['value'] == selected_value}
  end

  # Check if user has order to handle dm
  def self.handle_direct_message(msg)
    user = msg['user']
    if $orders[user].nil?
      self.intro(user)
    else
      $client.chat_postMessage(
        channel: msg['channel'], 
        text: 'Let\'s keep working on the open order'
      )
    end
  end

  # Check if order is complete
  def self.order_is_complete(order)
    !next_option_for_order(order)
  end

  # Update attachment with acknowledgement
  def self.acknowledge_action_from_message(original_message, action_callback_id, ack_text)
    msg = original_message
    attachment = self.find_attachment(msg, action_callback_id)
    attachment['actions'] = ''
    attachment['text'] = ":white_check_mark: #{ack_text}"
    return msg
  end

  # Create string summary of order
  def self.summarize_order(order)
    item = Menu.items.find { |i| i[:id] == order['type'] }
    summary = item[:name].to_s
    options_text = order[:options].map { |c, n| "#{n} #{c}" }

    if !options_text.empty?
      summary.concat(" with #{options_text.join(" and ")}")
    end
    return summary.downcase
  end
end