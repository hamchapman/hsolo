require 'sinatra'
require 'bundler'
require 'json'
require 'redis'
require 'pusher'
require 'pusher-client'

redis = Redis.new
current_remaining = 5
time_per_turn = 10
socket = PusherClient::Socket.new("8e13eb33b3d6df4ba979", { secure: true, secret: "b847765e341447f35440" })
socket.connect(true)
socket.subscribe('private-updates')
socket['private-updates'].bind('client-turn-started') do |data|
  puts data.inspect
end
socket['private-updates'].bind('client-turn-ended') do |data|
  player_id = JSON.parse(data)["player_id"]
  redis.lrem("player_queue", 1, player_id)
end
socket['private-updates'].bind('client-turn-tick') do |data|
  current_remaining = JSON.parse(data)["time_remaining"]
end
socket.connect(true)
Pusher.url = "http://8e13eb33b3d6df4ba979:b847765e341447f35440@api.pusherapp.com/apps/116651"

get '/' do
  random_id = rand(36**20).to_s(36)
  @player_id = random_id
  @time_per_turn = time_per_turn

  if current_remaining == 0 && redis.llen('player_queue').to_i == 0
    @players_ahead = []
    @time_to_wait = 0
  else
    @current_remaining = current_remaining
    @players_ahead = redis.lrange('player_queue', 0, -1)
    puts('———————————')
    number_in_queue = (redis.llen('player_queue').to_i - 1) < 0 ? 0 : (redis.llen('player_queue').to_i - 1)
    puts('———————————')
    @time_to_wait = current_remaining + time_per_turn * number_in_queue
    puts '****************************************************************'
    puts @time_to_wait.inspect
    # @current_remaining = current_remaining
    redis.rpush("player_queue", @player_id)
  end

  # @next_player_id = redis.lindex("player_queue", 0)
  erb :index
end

post '/webhooks/pusher' do
  webhook = Pusher.webhook(request)
  if webhook.valid?
    webhook.events.each do |event|
      case event["name"]
      when 'channel_occupied'
        # puts "Channel occupied: #{event["channel"]}"
      when 'channel_vacated'
        player_id = event["channel"].split("presence-")[-1]
        Pusher.trigger('private-updates', 'we-have-a-quitter', { player_id: player_id })
        redis.lrem("player_queue", 1, player_id)
        puts "Channel vacated: #{event["channel"]}"
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