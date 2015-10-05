#! /usr/bin/env ruby

require 'json'
require 'elasticsearch'
require 'ruby-progressbar'
require 'hashie'
require 'museum_provenance'

module ArtTracksUtils

  class ElysaImport
    def initialize

      @event_thing_index = {}
      @event_index = {}
      @parties = []
      @things = []
      @events = []

      @prov_settings = Hashie::Mash.new
      @prov_settings.mappings!.artwork!.include_in_all = false     
      @prov_settings.mappings!.artwork!.properties = {
        title: {
          type: "string",
          analyzer: "english",
          include_in_all: true
        },
        artist: {
          type: "string",
          analyzer: "english",
          include_in_all: true
        },
        accession_number: {
          type: "string",
          index: "not_analyzed",
          include_in_all: true
        },
        medium: {
          type: "string",
          index: "not_analyzed",
          include_in_all: true
        },
        acqisition_method: {
          type: "string",
          index: "not_analyzed",
        },
        images: {
          type: "string",
          index: "no"
        },
        provenance: {
          type: "string",
          index: "no",
          include_in_all: true
        },
        creation_earliest: {
          type: "string",
          index: "no",
        },
        creation_latest: {
          type: "string",
          index: "no",
        },
        exhibitions: {
          type: "string",
          analyzer: "english",
          include_in_all: true
        },
        exhibition_details: {
          type: "string",
          index: "no"
        },
        artist_details: {
          type: "string",
          index: "no"
        }
      }
#     @client = Elasticsearch::Client.new log: false
      @client = Elasticsearch::Client.new(log: false, host: 'http://paas:0f20bafabb05ae834c10a54b02ae955b@fili-us-east-1.searchly.com')

    end

    def import(json_location = "data/", purge = false)
      # Delete current DB
      if purge && @client.indices.exists(index: 'cmoa_provenance')
        @client.indices.delete index: 'cmoa_provenance'
      end

      ## (Re)create DB
      unless @client.indices.exists(index: 'cmoa_provenance')
        @client.indices.create index: 'cmoa_provenance', body: @prov_settings.to_h
      end

      import_things(json_location+"thing.json")
      import_parties(json_location+"party.json")
      import_events(json_location+"event.json")

      denormalize()

      # Load 'em up.
      bar = ProgressBar.create(:title => "Generating Search", :starting_at => 0, :total => @things.count)
      @things.each do |val|
        @client.index index: 'cmoa_provenance',
                     type: 'artwork',
                     id: val['id'],
                     body: val
        bar.increment
      end
    end

    protected

    #--------------------------------------------------------------------------

    # Denormalize people's names, exhibitions
    def denormalize
      bar = ProgressBar.create(:title => "Denormalizing", :starting_at => 0, :total => @things.count)
      @things.each do |v|
        unless v["creators"].nil?
          v["artist"] = v["creators"].collect do |p|
            @party_index[p]['name'] if @party_index[p]
          end.compact.join(", ")
          
          v["artist_details"] = @party_index[p].to_json
        end

        exhibitions = @event_thing_index[v["id"]]
        
        if exhibitions
          v["exhibitions"] = exhibitions.collect{ |e| @event_index[e]["title"] }.join(", ")
          begin
            v['exhibition_details'] = exhibitions.collect{ |e| @event_index[e]}.compact.to_json
          rescue TypeError
            puts exhibitions.collect{ |e| @event_index[e]}
          end
        end
        bar.increment
      end
    end


    # Find all the things
    def import_things(file)
      @things = File.open( file, "r" ) { |f| JSON.load( f )}["thing"].compact rescue nil

      #things =  File.open( file, "r" ) { |f| JSON.load( f )}["thing"]
      # bar = ProgressBar.create(:title => "Parsing Things", :starting_at => 0, :total => things.count)
      
      # things.collect.with_index do |thing, i|
      #   bar.increment
      #   thing
      # end.compact
    end


    #--------------------------------------------------------------------------
    # Find all the people
    def import_parties(file)
      @parties =  File.open( file, "r" ) { |f| JSON.load( f )}["party"]  rescue nil
      @party_index = {}
      return unless @parties
      bar = ProgressBar.create(:title => "Indexing Parties", :starting_at => 0, :total => @parties.count)
      @parties.each do |p| 
         id = p["id"]
         @party_index[id] = p
         bar.increment
      end
    end

    #--------------------------------------------------------------------------
    # Find all the events
    def import_events(file)
      @events =  File.open( file, "r" ) { |f| JSON.load( f )}["event"] rescue {}
      return unless @events.count
      bar = ProgressBar.create(:title => "Indexing Events", :starting_at => 0, :total => @events.count)
      @events.each do |event| 
        id = event["id"]
        event["formatted_date"] = MuseumProvenance::TimeSpan.new(event["commencement"],event["completion"]).to_s
        # Link venues to parties
        if event["venues"]
          event['venues'] = event['venues'].collect do |v|
            begin
              v["name"] = @party_index[v["id"]]["name"] #if party_index[v["id"]]
              v["formatted_date"] = MuseumProvenance::TimeSpan.new(v["commencement"],v["completion"]).to_s
              v
            rescue NoMethodError
              puts "Could not find the venue party for event IRN #{id}.  Please make sure that all three imports are up to date."
              nil
            end
          end.compact
        end
        # link organizers to parties
        if event['organizers'] 
          event['organizers'] = event['organizers'].collect do |organizer_id|
            begin
              obj = {id: organizer_id}
              obj["name"] = @party_index[organizer_id]["name"]# if party_index[organizer_id]
              obj
            rescue NoMethodError
              puts "Could not find the organizer party for event IRN #{id}.  Please make sure that all three imports are up to date."
              nil
            end
          end.compact
        end
        # index the events by object
        if event["things"]
          event["things"].each do |thing|
            @event_thing_index[thing["id"]] ||= []
            @event_thing_index[thing["id"]].push id
          end
        end
        @event_index[id] = event
        bar.increment
      end
    end
  end
end

