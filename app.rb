require 'rubygems'
require 'bundler/setup'

require 'sinatra'
require 'sequel'
require 'pry' if ENV['RACK_ENV'] == 'development'

DB = Sequel.connect('mysql2://localhost/mydora')

$genre_cache = {}

unless File.exist?('./genre_cache.bin')
  puts "Priming cache for genre, this will take a while..."
  DB[:genres].all.each do |genre|
    puts "caching #{genre[:name]}..."
    $genre_cache[genre[:id]] = DB['select songs.id as id from songs join artists on songs.profile_id=artists.profile_id join artists_genres on artists.id=artists_genres.artist_id where genre_id=?', genre[:id]].all.collect {|s| s[:id]}
  end

  File.write './genre_cache.bin', Marshal.dump($genre_cache)
end

$genre_cache = Marshal.load(File.read('./genre_cache.bin')).freeze
$genre_count_cache = {}
$genre_cache.each do |genre_id, song_ids|
  $genre_count_cache[genre_id] = song_ids.count
end
$genre_count_cache.freeze

SONG_ID_COUNT = DB[:songs].count

get '/' do
  @countries = DB[:countries].order(:name).all
  @genres = DB[:genres].order(:name).all
  erb :index
end

get '/song.json' do
  content_type :json
  # Some of the songs aren't there, loop until we find one
  song = nil
  loop do
    song = DB[
      'select * from songs where id=?',
      (params[:genre_id] && params[:genre_id] != '' ? $genre_cache[params[:genre_id].to_i].sample(1) : rand(DB[:songs].count))
    ].first

    # Using 99.zip for testing locally
    if ENV['RACK_ENV'] == 'development'
      song[:path] = '/99/std_339f8d9afcc248f7afef3ee550b1f038.mp3'
    end
    break if File.exist?('./public/songs'+song[:path])
  end

  artist = DB['select artists.name as name, cities.name as city, states.name as state, countries.name as country, profile_id as myspace_profile_id, location, fans, views, plays, last_update, (select GROUP_CONCAT(name) from genres left join artists_genres on genres.id=artists_genres.genre_id where artist_id=artists.id) as genres from artists left join cities on city_id=cities.id left join states on state_id=states.id left join countries on country_id=countries.id where profile_id=?', song[:profile_id]].first

  artist[:name] = clean_up_title artist[:name]
  song[:name] = clean_up_title song[:name]

  artist[:parsed_location] = clean_up_title [artist[:city], artist[:state], artist[:country]].compact.join(', ')

  if artist[:genres].nil?
    artist[:genres] = ''
  else
    artist[:genres].gsub!(',', ', ')
  end

  {song: song, artist: artist}.to_json
end

def clean_up_title(text)
  res = text.split.map(&:capitalize)*' '
  words = res.split(' ')
  words.collect {|word| %w{And Or Nor To}.include?(word) ? word.downcase : word }
  words.join(' ')
end
