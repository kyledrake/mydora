require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sequel'

DB = Sequel.connect('mysql2://localhost/mydora')

get '/' do
  @countries = DB[:countries].order(:name).all
  @genres = DB[:genres].order(:name).all
  erb :index
end

def clean_up_title(text)
  res = text.split.map(&:capitalize)*' '
  words = res.split(' ')
  words.collect {|word| %w{And Or Nor To}.include?(word) ? word.downcase : word }
  words.join(' ')
end

get '/song.json' do
  content_type :json

  # Some of the songs aren't there, loop until we find one
  loop do
    @song = DB['select * from songs where id=?', rand(DB[:songs].count)].first
    break if File.exist?('./public/songs'+@song[:path])
  end

  @artist = DB['select artists.name as name, cities.name as city, states.name as state, countries.name as country, profile_id as myspace_profile_id, location, fans, views, plays, last_update, (select GROUP_CONCAT(name) from genres left join artists_genres on genres.id=artists_genres.genre_id where artist_id=artists.id) as genres from artists left join cities on city_id=cities.id left join states on state_id=states.id left join countries on country_id=countries.id where profile_id=?', @song[:profile_id]].first

  @artist[:name] = clean_up_title @artist[:name]
  @song[:name] = clean_up_title @song[:name]

  @artist[:parsed_location] = clean_up_title [@artist[:city], @artist[:state], @artist[:country]].compact.join(', ')

  if @artist[:genres].nil?
    @artist[:genres] = ''
  else
    @artist[:genres].gsub!(',', ', ')
  end

  {song: @song, artist: @artist}.to_json
end
