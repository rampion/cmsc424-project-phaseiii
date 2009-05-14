#!/usr/bin/env ruby
require 'set'
require 'yaml'
require 'fileutils'

FileUtils.cd( File.dirname(__FILE__) )

MOVIES_H = {}
puts "reading in movies"
File.open('movies.list.reduced.80s') do |m_f|
  m_f.each_line do |line|
    if line =~ /^([^\t]+)\t+(\d{4})$/
      uid = $1
      year = $2.to_i
      MOVIES_H[$1] = { 
        :title => uid.sub(/ +\(\d{4}\)$/,''), 
        :year => year,
        :stars => Set.new, 
        :directors => Set.new,
        :producers => Set.new,
        :genres => Set.new,
        :list_price => rand(10).to_f + 10.99,
        :copies => 10 * (rand(10)+1)
      }
    end
  end
end
[ [ 'actors.list.trim', :stars ],
  [ 'actresses.list.trim', :stars ],
  [ 'directors.list.trim', :directors ],
  [ 'producers.list.trim', :producers ] ].each do |filename, type|

  puts "reading in #{type.to_s} from #{filename}"
  File.open(filename) do |f|
    name = nil
    f.each_line do |line|
      line.chomp!
      if line =~ /^(\S[^\t]*)/
        name = $1
      end
      if line =~ /\t+([^\t]+ \(\d{4}\))[^\t]*$/ and movie = MOVIES_H[$1]
        movie[type] << name
      end
    end
  end
end
puts "reading in genres from genres.list.trim"
File.open('genres.list.trim') do |f|
  f.each_line do |line|
    line.chomp!
    if line =~ /^([^\t]+ \(\d{4}\))[^\t]*\t+([^\t]+)$/ and movie = MOVIES_H[$1]
      movie[:genres] << $2
    end
  end
end

MOVIES = MOVIES_H.values.find_all do |movie| 
  not( movie[:genres].empty? or 
       movie[:stars].empty?  or
       movie[:producers].empty? or
       movie[:directors].empty? )
end
MOVIES.each do |movie|
  [:genres, :stars, :producers, :directors].each do |type|
    movie[type] = movie[type].to_a
  end
end
WIDTH = 1000
n = ?A - 1
(0...MOVIES.size).step(WIDTH) do |min|
  n += 1
  filename = "input-#{n.chr}.yaml"
  puts "writing out #{filename}"
  File.open(filename, 'w') do |f|
    f.puts YAML::dump( MOVIES[min,WIDTH] )
  end
end
