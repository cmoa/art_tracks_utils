## For a given list of records, return a sorted, ordered list
## of locations that appear in the provenance of those records.

require 'json'
require 'hashie'
require 'ruby-progressbar'
require 'museum_provenance'

# gallery8_irns = ['1011515', '1012310', '1015853', '1004771',  '1000003', '1012274', '1011575', '1016715', '1011959', '1009147', '1012327', '1011873', '1012391', '1011947', '1012247', '1011949', '1012265', '1012527', '1011565']
# irns = "65.31 71.7 00.9 2010.38 2000.20 2006.10 2010.57 53.22 73.3.3 67.2 62.19.1 65.34 69.44 57.17.2 62.37.1 2007.7 68.27 66.24.1 76.57.1 76.57.2 84.8 2001.61.6 22.8 2011.47 2007.53 19.17.2 19.17.3 49.7 50.4.1 2009.42 50.4.3 65.35 65.30.2 62.37.2 54.12.4 99.7 69.11 66.19.2 05.5 2006.58 47.11.4 47.11.16 66.3 68.11 66.4 74.7.53 81.26.10 68.10.1 63.9 2001.61.2 1998.63 66.24.2 66.23 19.10 46.21 2005.75 ".split(" ")
# old_masters = ['1016222', '1011438', '1013007', '1013005', '1011440', '1009117', '1016878', '1011714', '1016596', '92521', '1000586', '1012206', '1017515', '1011470', '1012440', '1010990', '1011866', '1010726', '1009241', '1018027', '1013051', '1011710', '1019240']

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
