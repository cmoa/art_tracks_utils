require 'json'
require 'ruby-progressbar'
require 'damerau-levenshtein'

module ArtTracksUtils

## For a given JSON file, return a list of items that are duplicates, or near duplicates.  
## By default, it will look for objects at a levenshtein distance of 1—by passing in a 
## distance number, it will return objects at that distance.

class Disambiguator

  def Disambiguator.scan(file, distance)
    parties =  File.open( file, "r" ) { |f| JSON.load( f )}.first[1]

    names = []
    name_hash = {}
    index = parties.each do |p| 
      name = p['name'] || p['title']
      next unless name

      name_hash[name] ||= []
      names.push name
    end

    show_bar = $stdout.tty?
    bar = ProgressBar.create(:title => "Scanning records", :starting_at => 0, :total => names.count) if show_bar
    (0...names.count).each do 
      bar.increment if show_bar
      n = names.pop
      names.delete_if do |comp|
        if distance == 0
          if n == comp
            name_hash[n].push(comp) 
            true
          else 
            false
          end
        else
          if DamerauLevenshtein.distance(n, comp, 2, distance) == distance
            name_hash[n].push(comp) 
            true
          else
            false
          end
        end
      end
    end
    
    name_hash.sort.collect do |key,val|
      "#{key} -> #{val}" if val.count > 0
    end.join("\n")
  end
end
end

