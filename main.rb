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

  def card_to_image(card)
    suit = suit_str(card[0])
    face = face_str(card[1])
    "#{ suit }_#{ face }.jpg"
  end

  def suit_str(s)
    case s
    when 'C' then 'clubs'
    when 'D' then 'diamonds'
    when 'H' then 'hearts'
    when 'S' then 'spades'
    end
  end

  def face_str(s)
    if s.to_i == 0
      case s
      when 'A' then 'ace'
      when 'J' then 'jack'
      when 'Q' then 'queen'
      when 'K' then 'king'
      end
    else
      s
    end
  end
end

before do
  @show_hit_or_stay_buttons = true
  @dealer_will_hit = false
  @game_end = false
  @in_player_turn = true
end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/bet' do
  session[:total_money] = 500 if session[:total_money] == nil
  erb :bet
end

post '/bet' do
  bm = params[:bet_amount]
  redirect '/bet' if (/^\d+$/ =~ bm) == nil || bm.to_i > session[:total_money] || bm.to_i < 1
  session[:bet_amount] = bm.to_i
  redirect '/game'
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if (/^[A-Za-z]+$/ =~ params[:player_name]) == nil
    redirect '/new_player'
  end
  session[:player_name] = params[:player_name]
  # redirect '/game'
  redirect '/bet'
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
    @in_player_turn = false
  end

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  if calculate_total(session[:player_cards]) == 21
    session[:total_money] += session[:bet_amount]
    @success = "Congratulation, Blackjack! you win. #{ session[:player_name] } now has $#{ session[:total_money]}."
    @show_hit_or_stay_buttons = false
    @in_player_turn = false
    @game_end = true
  end

  if calculate_total(session[:player_cards]) > 21
    session[:total_money] -= session[:bet_amount]
    @error = "Sorry, it looks like you busted. #{ session[:player_name] } now has $#{ session[:total_money]}."
    @show_hit_or_stay_buttons = false
    @in_player_turn = false
    @game_end = true
  end

  erb :game
end

post '/game/player/stay' do
  @show_hit_or_stay_buttons = false
  @in_player_turn = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total < 17
    @dealer_will_hit = true
  else
    if player_total > dealer_total
      session[:total_money] += session[:bet_amount]
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, player win. #{ session[:player_name] } now has $#{ session[:total_money]}."
      @game_end = true
    elsif player_total < dealer_total
      session[:total_money] -= session[:bet_amount]
      @error = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, dealer win. #{ session[:player_name] } now has $#{ session[:total_money]}."
      @game_end = true
    else
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, it's a tie. #{ session[:player_name] } now has $#{ session[:total_money]}."
      @game_end = true
    end
  end

  erb :game

end

get '/new_game' do
  session[:player_name] = nil
  session[:total_money] = nil
  redirect '/new_player'
end

get '/game_over' do
  erb :game_over
end

post '/game/dealer/hit' do
  @show_hit_or_stay_buttons = false
  @in_player_turn = false

  session[:dealer_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total > 21
    session[:total_money] += session[:bet_amount]
    @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, player win. #{ session[:player_name] } now has $#{ session[:total_money]}."
    @game_end = true
  elsif dealer_total == 21
    session[:total_money] -= session[:bet_amount]
    @error = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, dealer win. #{ session[:player_name] } now has $#{ session[:total_money] }."
    @game_end = true
  elsif dealer_total < 17
    @dealer_will_hit = true
  else
    if player_total > dealer_total
      session[:total_money] += session[:bet_amount]
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, player win. #{ session[:player_name] } now has $#{ session[:total_money]}."
      @game_end = true
    elsif player_total < dealer_total
      session[:total_money] -= session[:bet_amount]
      @error = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, dealer win. #{ session[:player_name] } now has $#{ session[:total_money]}."
      @game_end = true
    else
      @success = "player stay at #{ player_total }, dealer stay at #{ dealer_total }, it's a tie. #{ session[:player_name] } now has $#{ session[:total_money]}."
      @game_end = true
    end
  end

  erb :game

end









