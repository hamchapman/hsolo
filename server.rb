require 'sinatra'
require 'bundler'
require 'json'
require 'redis'
require 'pusher'
require 'pusher-client'

redis = Redis.new
time_per_turn = 100
socket = PusherClient::Socket.new("8e13eb33b3d6df4ba979", { secure: true, secret: "b847765e341447f35440" })
socket.connect(true)
socket.subscribe('private-updates')

socket['private-updates'].bind('client-turn-ended') do |data|
  player_id = JSON.parse(data)["player_id"]
  redis.lrem("player_queue", 1, player_id)
end

socket.connect(true)
Pusher.url = "http://8e13eb33b3d6df4ba979:b847765e341447f35440@api.pusherapp.com/apps/116651"

get '/' do
  random_id = rand(36**20).to_s(36)
  @player_id = random_id
  @time_per_turn = time_per_turn
  erb :index
end


post '/play' do
  content_type :json

  redis.rpush("player_queue", params[:player_id])
  @player_queue = redis.lrange('player_queue', 0, -1)
  { players_ahead: @player_queue }.to_json
end

post '/webhooks/pusher' do
  webhook = Pusher.webhook(request)
  if webhook.valid?
    webhook.events.each do |event|
      case event["name"]
      when 'channel_vacated'
        player_id = event["channel"].split("presence-")[-1]
        Pusher.trigger('private-updates', 'we-have-a-quitter', { player_id: player_id })
        redis.lrem("player_queue", 1, player_id)
      end
    end
  else
    puts "Webhook invalid"
  end
  200
end

post '/pusher/auth' do
  content_type :json
  Pusher[params[:channel_name]].authenticate(params[:socket_id], {
    user_id: params[:channel_name].split("presence-")[-1]
  }).to_json
end