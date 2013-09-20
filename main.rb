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

  def win_info
    "#{ session[:player_name] } stay at #{ calculate_total(session[:player_cards]) }, dealer stay at #{ calculate_total(session[:dealer_cards]) }. #{ session[:player_name] } win! #{ session[:player_name] } now has $#{ session[:total_money] }."
  end

  def lose_info
    "#{ session[:player_name] } stay at #{ calculate_total(session[:player_cards]) }, dealer stay at #{ calculate_total(session[:dealer_cards]) }. Dealer win! #{ session[:player_name] } now has $#{ session[:total_money] }."
  end

  def tie_info
    "#{ session[:player_name] } stay at #{ calculate_total(session[:player_cards]) }, dealer stay at #{ calculate_total(session[:dealer_cards]) }. It's a tie! #{ session[:player_name] } now has $#{ session[:total_money] }."
  end

  def compare_hands
    player_total = calculate_total(session[:player_cards])
    dealer_total = calculate_total(session[:dealer_cards])

    if player_total > dealer_total
      session[:total_money] += session[:bet_amount]
      @success = win_info
    elsif player_total < dealer_total
      session[:total_money] -= session[:bet_amount]
      @error = lose_info
    elsif player_total == dealer_total
      @success = tie_info
    end

    @game_end = true
  end

  def player_balckjack?
    if calculate_total(session[:player_cards]) == 21
      session[:total_money] += session[:bet_amount]
      @success = win_info
      @in_player_turn = false
      @game_end = true
    end
  end

  def player_busted?
    if calculate_total(session[:player_cards]) > 21
      session[:total_money] -= session[:bet_amount]
      @error = lose_info
      @in_player_turn = false
      @game_end = true
    end
  end

end

before do
  @in_player_turn = true
  @game_end = false
  @dealer_will_hit = false
end

get '/' do
  if session[:player_name]
    redirect '/bet'
  else
    redirect '/new_player'
  end
end

get '/bet' do
  session[:total_money] = 500 if session[:total_money].nil?
  erb :bet
end

post '/bet' do
  bm = params[:bet_amount]
  redirect '/bet' if (/^\d+$/ =~ bm).nil? || bm.to_i > session[:total_money] || bm.to_i < 1
  session[:bet_amount] = bm.to_i
  redirect '/game'
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  redirect '/new_player' if (/^[A-Za-z]+$/ =~ params[:player_name]).nil?

  session[:player_name] = params[:player_name]
  redirect '/bet'
end

get '/new_game' do
  session[:player_name] = nil
  session[:total_money] = nil
  redirect '/new_player'
end

get '/game_over' do
  erb :game_over
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

  player_balckjack?

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

  player_balckjack?

  player_busted?

  erb :game
end

post '/game/player/stay' do
  @in_player_turn = false

  dealer_total = calculate_total(session[:dealer_cards])

  compare_hands if dealer_total >= 17

  @dealer_will_hit = true if dealer_total < 17

  erb :game
end

post '/game/dealer/hit' do
  @in_player_turn = false

  session[:dealer_cards] << session[:deck].pop
  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total > 21
    session[:total_money] += session[:bet_amount]
    @success = win_info
    @game_end = true
  elsif dealer_total == 21
    session[:total_money] -= session[:bet_amount]
    @error = lose_info
    @game_end = true
  elsif dealer_total < 21 && dealer_total >= 17
    compare_hands
  elsif dealer_total < 17
    @dealer_will_hit = true
  end

  erb :game
end
