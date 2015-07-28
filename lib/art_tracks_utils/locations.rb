## For a given list of records, return a sorted, ordered list
## of locations that appear in the provenance of those records.

require 'json'
require 'hashie'
require 'ruby-progressbar'
require 'museum_provenance'

module ArtTracksUtils

  class LocationList

    def LocationList.list(file,data)
      things =  File.open( file, "r" ) { |f| JSON.load( f )}.first[1]
      hashie_things = things.collect{|t| Hashie::Mash.new(t) }.compact

      locations = {}

      source = data

      source_type = source.first.include?(".") ? "accession_number" : "id"

      bar = ProgressBar.create(:title => "Scanning records", :starting_at => 0, :total => hashie_things.count)
      hashie_things.each do |i|
        bar.increment
        next unless source.include? i[source_type].to_s
        begin
          generated_provenance = MuseumProvenance::Provenance.extract(i.provenance)
          generated_provenance.each do |line|
            next unless line.location
            locations[line.location.name] ||= 0
            locations[line.location.name] += 1
          end
        rescue => e
          puts e
          puts "-------"
          puts i.provenance
          puts "-------"
        end
      end


      locations.sort_by{|k,v| v}.reverse.collect do |key,val|
        "#{val} - #{key}"
      end.join("\n")
    end
  end
end
