require 'rubygems'
require 'sinatra'
require 'pry'
# require 'sinatra/reloader'

set :sessions, true

helpers do
  def calculate_total(cards)
    arr = cards.map { |element| element[1] }

    total = 0
    arr.each do |a|
      if a == 'A'
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    # correct for Aces
    arr.select { |element| element == 'A' }.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end
end

before do
  @show_hit_or_stay_buttons = true
  @dealer_will_hit = false
  @game_end = false
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  session[:player_name] = params[:player_name]
  redirect '/game'
end

get '/game' do
  # create a deck and put it in session
  suits = %w(H D C S)
  values = %w(2 3 4 5 6 7 8 9 10 J Q K A)
  session[:deck] = suits.product(values).shuffle!

  # deal cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == 21
    @success = 'Congratulation, Blackjack! you win.'
    @show_hit_or_stay_buttons = false
    @game_end = true
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  if calculate_total(session[:player_cards]) == 21
    @success = 'Congratulation, Blackjack! you win.'
    @show_hit_or_stay_buttons = false
    @game_end = true
  end
  if calculate_total(session[:player_cards]) > 21
    @error = "Sorry, it looks like you busted."
    @show_hit_or_stay_buttons = false
    @game_end = true
  end

  erb :game
end

post '/game/player/stay' do
  # @success = 'You have chosen to stay.'
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  # if calculate_total(session[:dealer_cards]) > calculate_total(session[:player_cards])
  #   @error = "dealer has #{ calculate_total(session[:dealer_cards]) }, dealer win"
  #   @show_hit_or_stay_buttons = false
  #   @game_end = true
  # end

  # if dealer_total > player_total
  #   @error = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, dealer win."
  #   @show_hit_or_stay_buttons = false
  #   @game_end = true
  # end


  if dealer_total < 17
    @dealer_will_hit = true
  else
    if player_total > dealer_total
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, player win."
      @game_end = true
    elsif player_total < dealer_total
      @error = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, dealer win."
      @game_end = true
    else
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, it's a tie."
      @game_end = true
    end
  end

  erb :game

end

get '/new_game' do
  session[:player_name] = nil
  redirect '/new_player'
end

get '/game_over' do
  erb :game_over
end

post '/game/dealer/hit' do
  @show_hit_or_stay_buttons = false

  session[:dealer_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total > 21
    @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, player win."
    @game_end = true
  elsif dealer_total < 17
    @dealer_will_hit = true
  else
    if player_total > dealer_total
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, player win."
      @game_end = true
    elsif player_total < dealer_total
      @error = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, dealer win."
      @game_end = true
    else
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, it's a tie."
      @game_end = true
    end
  end

  erb :game

end









