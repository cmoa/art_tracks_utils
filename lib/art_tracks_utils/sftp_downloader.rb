require 'net/sftp'
require 'art_tracks'
require 'tempfile'

module ArtTracksUtils

  class SftpDownloader
    def self.download(directory, opts)
      Net::SFTP.start(opts.host, opts.user, :password => opts.password) do |sftp|

        files = {}
        # find the most recent version of each type of file
        sftp.dir.entries("/#{opts.directory}").sort_by{|e| e.attributes.createtime}.reverse!.each do |entry|
          path = "/#{opts.directory}/#{entry.name}"
          file = sftp.file.open(path)
          begin
            str =  file.gets
          end until str.include? "<table name=\""
          type =  str[/"(.*)?"/,1]
          type = KEmu::XMLTransformer.lookup_type(type)
          
          # hack below to detect archives.
          if type == :thing
            3.times {file.gets}
            str = file.gets
            type = :archive   if str.include?("EADUnitID")
          end          
          file.close
          
          if opts.type.nil? || opts.type == type.to_s
            if files[type].nil?
              files[type] = path
              files[:teenie] = path if type == :thing
              files[:accessioned] = path if type == :thing
            end
          end
        end

        # download those most recent files to tempfiles
        art = ArtTracks::ArtTracks.new({verbose: $stdout.tty?, internal_images:  false})
        to_be_processed = {}
        files.each do |key,val|
          output_file = nil
          if opts.xml
            output_file = File.new("#{directory}/#{key.to_s}.xml", "wb")
          else
            output_file = Tempfile.new(key.to_s)
          end
          sftp.download!(val, output_file) do |event, downloader, *args|
            case event
            when :open then
              # args[0] : file metadata
              puts "starting download: #{args[0].remote} -> #{args[0].local} (#{args[0].size} bytes}"
            when :get then
              # args[0] : file metadata
              # args[1] : byte offset in remote file
              # args[2] : data that was received
              puts "writing #{args[2].length} bytes to #{args[0].local} starting at #{args[1]}"
            when :close then
              # args[0] : file metadata
              puts "finished with #{args[0].remote}"
            when :mkdir then
              # args[0] : local path name
              puts "creating directory #{args[0]}"
            when :finish then
              puts "all done!"
            end
          end
          to_be_processed[key] = output_file
        end
        to_be_processed.each do |key,output_file|
          art.kemu_xml_to_json(output_file, nil, directory, {type: key})
        end
      end
    end
  end
end
