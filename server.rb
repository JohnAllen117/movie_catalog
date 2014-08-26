require 'sinatra'
require 'pg'
require 'sinatra/reloader'

def db_connection
  begin
    connection = PG.connect(dbname: 'movies')

    yield(connection)

  ensure
    connection.close
  end
end

# def find_last_page(field)

#  @actor_info = db_connection do |conn|
#   binding.pry
#     conn.exec_params('SELECT $1 FROM movies;',[{ :value => field, :type => 0, :format => 0 }])
#   end

#   @actor_info.ntuples
# end

def find_last_page

 @actor_info = db_connection do |conn|
    conn.exec('SELECT title FROM movies;')
  end
  @actor_info.ntuples
end




get '/' do
  erb :index
end


get '/actors' do

  @last_page_num = find_last_page/20
  # @last_page_num = find_last_page('title') WTFFFFFF
  @page_num = params[:page].to_i*20

  @results = db_connection do |conn|
    conn.exec_params('SELECT name FROM actors
              ORDER BY actors.name
              LIMIT 20 OFFSET $1;',[@page_num])

end

erb :'actors/index'
end


get '/actors/:id' do

  @actor_name = params[:id]

 @actor_info = db_connection do |conn|
  conn.exec_params('SELECT title, actors.name AS actor, cast_members.character FROM movies
    JOIN cast_members ON movies.id = cast_members.movie_id
    JOIN actors ON cast_members.actor_id = actors.id
    WHERE actors.name = $1
    ORDER BY movies.title;',[@actor_name])
end


erb :'/actors/show'
end


#differents orderings (year, rating by /movies?order=year, order=rating)
#paginate! 20 / pg
#search feature for /movies (?query=trool+2 ) LIKE, ILIKE may help
#search feature for actors
# number of movies actor has starred in

get '/movies' do


@last_page_num = find_last_page/20
# @last_page_num = find_last_page('title') WTFFFFFF


  @page_num = params[:page].to_i*20

 @results = db_connection do |conn|
  conn.exec_params('SELECT title, year, rating, genres.name AS genre, studios.name AS studio FROM movies
              JOIN genres ON movies.genre_id = genres.id
              JOIN studios ON movies.studio_id = studios.id
              ORDER BY movies.title
              LIMIT 20 OFFSET $1;',[@page_num])
end



erb :'movies/index'
end

get '/movies/:id' do

@movie_name = params[:id]

 @movie_deets = db_connection do |conn|
  conn.exec_params('SELECT title, year, rating, synopsis, genres.name AS genre, studios.name AS studio, cast_members.character AS character, actors.name AS actor FROM movies
              JOIN genres ON movies.genre_id = genres.id
              JOIN cast_members ON movies.id = cast_members.movie_id
              JOIN actors ON actors.id = cast_members.actor_id
              JOIN studios ON movies.studio_id = studios.id
              WHERE title = $1
              ORDER BY movies.title;',[@movie_name])
  end

erb :'movies/show'
end

post '/movies' do

  @search_movie_ids = []
  @results = []

  @last_page_num = find_last_page/20
# @last_page_num = find_last_page('title') WTFFFFFF


  @page_num = params[:page].to_i*20

@query = params[:query].reverse + '%'
@query = @query.reverse + '%'

@movie_titles = db_connection do |conn|
  conn.exec_params('SELECT movies.id, title, synopsis FROM movies
    WHERE title LIKE $1 OR synopsis LIKE $1;',[@query])
end

@movie_titles.each do |each|
  @search_movie_ids << each['id']

end

 @movie_titles = db_connection do |conn|
  conn.exec_params('SELECT movies.id, title, year, rating, genres.name AS genre, studios.name AS studio FROM movies
              JOIN genres ON movies.genre_id = genres.id
              JOIN studios ON movies.studio_id = studios.id;')
end

@search_movie_ids.each do |id|
  @movie_titles.each do |movie|
    if movie['id'] == id
      @results << movie

    end
  end
end


erb :'movies/index'
end


post '/actors' do

  @search_actor_ids = []
  @results = []

  @last_page_num = find_last_page/20
# @last_page_num = find_last_page('title') WTFFFFFF
  @page_num = params[:page].to_i*20

  @query = params[:query].reverse + '%'
  @query = @query.reverse + '%'

@results = db_connection do |conn|
  conn.exec_params('SELECT name FROM actors
    WHERE name ILIKE $1;',[@query])
end



erb :'actors/index'
end



