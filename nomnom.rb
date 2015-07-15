require 'yomu'
require 'json'
require 'polipus'
require 'polipus/plugins/cleaner'
require 'redis'

class NomNom

  def initialize
    @result = {}
    @result[:entities] = []
    @result[:log] = ""

    log "Nomnom initialized!"

    @options = {
      # Redis connection
      redis_options: {
        host: 'localhost',
        db: 5,
        driver: 'hiredis'
      },
      # Page storage: pages is the name of the collection where
      # pages will be stored
      #storage: Polipus::Storage.mongo_store(@mongo, 'pages'),
      # Use your custom user agent
      user_agent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9) AppleWebKit/537.71 (KHTML, like Gecko) Version/7.0 Safari/537.71',
      # Use 5 threads
      workers: 5,
      # Queue overflow settings:
      #  * No more than 5000 elements on the Redis queue
      #  * Exceeded Items will stored on Mongo into 'rubygems_queue_overflow' collection
      #  * Check cycle is done every 60 sec
      #queue_items_limit: 5_000,
      #queue_overflow_adapter: Polipus::QueueOverflow.mongo_queue(mongo, 'rubygems_queue_overflow'),
      #queue_overflow_manager_check_time: 60,
      # Logs goes to the stdout
      logger: Logger.new(STDOUT)
    }

    Polipus::Plugin.register Polipus::Plugin::Cleaner, reset: true
  end

  def log(message)
    puts "[ ] #{message}\n"
    @result[:log] << "[ ] #{message}\n"
  end

  def download_and_extract_metadata(uri)

    begin

      yomu = Yomu.new uri

      result = {
        :metadata => yomu.metadata,
        :text => yomu.text,
        :content_type => yomu.mimetype.content_type,
        :extensions => yomu.mimetype.extensions
      }

    rescue JSON::ParserError => e
      log "Error parsing uri: #{uri} #{e}"
    rescue URI::InvalidURIError => e
      #
      # XXX - This is an issue. We should catch this and ensure it's not
      # due to an underscore / other acceptable character in the URI
      # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
      #
      log "Unable to request URI: #{uri} #{e}"
    rescue OpenSSL::SSL::SSLError => e
      log "SSL connect error : #{e}"
    rescue Errno::ECONNREFUSED => e
      log "Unable to connect: #{e}"
    rescue Errno::ECONNRESET => e
      log "Unable to connect: #{e}"
    rescue Net::HTTPBadResponse => e
      log "Unable to connect: #{e}"
    rescue Zlib::BufError => e
      log "Unable to connect: #{e}"
    rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
      log "Unable to connect: #{e}"
    rescue EOFError => e
      log "Unable to connect: #{e}"
    rescue SocketError => e
      log "Unable to connect: #{e}"
    rescue Encoding::InvalidByteSequenceError => e
      log "Encoding error: #{e}"
    rescue Encoding::UndefinedConversionError => e
      log "Encoding error: #{e}"
    rescue EOFError => e
      log "Unexpected end of file, consider looking at this file manually: #{url}"
    end
  result
  end

  ###
  ### Entity Parsing
  ###

  def parse_entities_from_content(source_uri, content, optional_strings=nil)

    log "Parsing text from #{source_uri}"

    # Make sure we have something to parse
    unless content
      log "No content to parse, returning"
      return nil
    end


    # Scan for email addresses
    addrs = content.scan(/[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,8}/)
    addrs.each do |addr|
      _create_entity("EmailAddress", {:name => addr, :source => source_uri})
    end

    # Scan for dns records
    dns_records = content.scan(/^[A-Za-z0-9]+\.[A-Za-z0-9]+\.[a-zA-Z]{2,6}$/)
    dns_records.each do |dns_record|
      _create_entity("DnsRecord", {:name => dns_record, :source => source_uri})
    end

    # Scan for phone numbers
    phone_numbers = content.scan(/((\+\d{1,2}\s)?\(?\d{3}\)?[\s.-]\d{3}[\s.-]\d{4})/)
    phone_numbers.each do |phone_number|
      _create_entity("PhoneNumber", { :name => "#{phone_number[0]}", :source => source_uri })
    end

    # Scan for Links
    #urls = content.scan(/https?:\/\/[\S]+/)
    #urls.each do |url|
    #  _create_entity("Url", {:name => url, :source => source_uri })
    #end

    if optional_strings
      optional_strings.each do |string|
        found = content.scan(/#{string}/)
        found.each do |x|
          _create_entity("String", { :name => "#{x[0]}", :source => source_uri })
        end
      end
    end

  end


  def crawl_and_parse(uri, depth=3)
    log "crawling: #{uri}"

    # make sure we have an integer
    depth = depth.to_i

    begin
      Polipus.crawler("polipus", uri, @options) do |crawler|

        #
        # Spider!
        #
        crawler.on_page_downloaded do |page|

          # XXX - Need to set up a recursive follow-redirect function
          if page.code == 301
            log "301 Redirect on #{page.url}"
          end

          #
          # Create an entity for this uri
          #
          #_create_entity("Url", { :name => page_url}) if opt_create_urls

          ###
          ### XXX = UNTRUSTED INPUT. VERY LIKELY TO BREAK THINGS!
          ### http://po-ru.com/diary/fixing-invalid-utf-8-in-ruby-revisited/
          ###

          # Extract the url
          page_url = ("#{page.url}").encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

          # If we don't have a body, we can't do anything here.
          next unless page.body

          # Extract the body
          page_body = page.body.encode('UTF-8', {:invalid => :replace, :undef => :replace, :replace => '?'})

          parse_metadata = true
          if parse_metadata

            # Get the filetype for this page
            filetype = "#{page_url.split(".").last.gsub("/","")}".upcase

            # A list of all filetypes we're capable of doing something with
            interesting_types = [ "DOC","DOCX","EPUB","ICA","INDD","JPG","JPEG",
              "MP3","MP4","ODG","ODP","ODS","ODT","PDF","PNG","PPS","PPSX","PPT",
              "PPTX","PUB","RDP","SVG","SVGZ","SXC","SXI","SXW","TIF","TXT","WPD",
              "XLS","XLSX"]

            if interesting_types.include? filetype

              result = download_and_extract_metadata page_url

              if result

                _create_entity "Info", :name => "Metadata for #{page_url}",  :content => result[:metadata]


                ###
                ### PDF
                ###
                if result[:content_type] == "application/pdf"

                  #
                  # Create a file entity
                  #
                  _create_entity "File", {
                    :type => "PDF",
                    :name => page_url,
                    :created => result[:metadata]["Creation-Date"],
                    :last_modified => result[:metadata]["Last-Modified"]
                  }

                  _create_entity "Person", { :name => result[:metadata]["Author"], :source => page_url } if result[:metadata]["Author"]
                  _create_entity "SoftwarePackage", { :name => result[:metadata]["producer"], :source => page_url } if result[:metadata]["producer"]
                  _create_entity "SoftwarePackage", { :name => result[:metadata]["xmp:CreatorTool"], :source => page_url } if result[:metadata]["xmp:CreatorTool"]

                end

                #
                # Look in the content
                #
                _create_entity "Info", :name => "Metadata for #{page_url}",  :content => result[:metadata]

                # Look for entities in the text
                parse_entities_from_content(page_url, result[:text])

              else
                log "No result received. See logs for details"
              end

            else # not a recognized type
              parse_entities_from_content(page_url, page_body)
            end

          else

            log "Parsing as a regular file"
            parse_entities_from_content(page_url, page_body)
          end

        end #end .on_every_page
      end # end .crawl

    # For now, we catch everything. Parsing is a messy messy beast
    # XXX - ugh
    rescue JSON::ParserError => e
      log "Error parsing uri: #{uri} #{e}"
    rescue URI::InvalidURIError => e
      #
      # XXX - This is an issue. We should catch this and ensure it's not
      # due to an underscore / other acceptable character in the URI
      # http://stackoverflow.com/questions/5208851/is-there-a-workaround-to-open-urls-containing-underscores-in-ruby
      #
      log "Unable to request URI: #{uri} #{e}"
    rescue OpenSSL::SSL::SSLError => e
      log "SSL connect error : #{e}"
    rescue Errno::ECONNREFUSED => e
      log "Unable to connect: #{e}"
    rescue Errno::ECONNRESET => e
      log "Unable to connect: #{e}"
    rescue Net::HTTPBadResponse => e
      log "Unable to connect: #{e}"
    rescue Zlib::BufError => e
      log "Unable to connect: #{e}"
    rescue Zlib::DataError => e # "incorrect header check - may be specific to ruby 2.0"
      log "Unable to connect: #{e}"
    rescue EOFError => e
      log "Unable to connect: #{e}"
    rescue SocketError => e
      log "Unable to connect: #{e}"
    rescue Encoding::InvalidByteSequenceError => e
      log "Encoding error: #{e}"
    rescue Encoding::UndefinedConversionError => e
      log "Encoding error: #{e}"
    rescue EOFError => e
      log "Unexpected end of file, consider looking at this file manually: #{url}"
    end #end begin

  @result
  end # crawl_and_parse

  private

    # This is a helper method, use this to create entities
    def _create_entity(type, attributes)
      log "Creating entity: #{type}, #{attributes.inspect}"
      entity = { :type => type, :attributes => attributes } #:parent => {:task => _canonical_name, :entity => @entity }
      @result[:entities] << entity
    entity
    end


end
