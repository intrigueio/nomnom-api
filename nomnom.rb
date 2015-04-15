require 'yomu'
require 'json'
require 'anemone'

class NomNom

  #attr_reader :result

  def initialize
    @result = {}
    @result[:entities] = []
    @result[:log] = ""
  end

  def log(message)
    puts message
    @result[:log] << message
  end

  def download_and_extract_metadata(uri)

    begin

      #raise "Not Implemented"

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
    log "Crawling: #{uri}"

    # make sure we have an integer
    depth = depth.to_i

    begin
      Anemone.crawl(uri, {
        :obey_robots => false,
        :user_agent => "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_2) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/40.0.2214.111 Safari/537.36",
        :depth_limit => depth,
        :redirect_limit => 5,
        :threads => 1,
        :verbose => false } ) do |anemone|

        #
        # Spider!
        #
        anemone.on_every_page do |page|

          # XXX - Need to set up a recursive follow-redirect function
          if page.code == 301
            log "301 Redirect on #{page.url}"
            #Anemone.crawl(page.redirect_to)
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

            #log "Found filetype: #{filetype}"

            # A list of all filetypes we're capable of doing something with
            interesting_types = [
              "DOC","DOCX","EPUB","ICA","INDD","JPG","JPEG","MP3","MP4","ODG","ODP","ODS","ODT","PDF","PNG","PPS","PPSX","PPT","PPTX","PUB","RDP","SVG","SVGZ","SXC","SXI","SXW","TIF","TXT","WPD","XLS","XLSX"]


            if interesting_types.include? filetype

              result = download_and_extract_metadata page_url

              #@task_log.good "Got result #{result}"
              #_create_entity("Info", :name => "Metadata in #{page_url}", :content => result[:metadata])

              if result

                ###
                ### PDF
                ###
                if result[:content_type] == "application/pdf"

                  _create_entity "File", { :type => "PDF",
                    :name => page_url,
                    :created => result[:metadata]["Creation-Date"],
                    :last_modified => result[:metadata]["Last-Modified"]
                  }

                  _create_entity "Person", { :name => result[:metadata]["Author"], :source => page_url } if result[:metadata]["Author"]
                  _create_entity "SoftwarePackage", { :name => result[:metadata]["producer"], :source => page_url } if result[:metadata]["producer"]
                  _create_entity "SoftwarePackage", { :name => result[:metadata]["xmp:CreatorTool"], :source => page_url } if result[:metadata]["xmp:CreatorTool"]

                end

                _create_entity "Info", :name => "Metadata for #{page_url}",  :content => result[:metadata]

                # Look for entities in the text
                parse_entities_from_content(page_url, result[:text])

              else
                log "No result received. See logs for details"
              end
            else
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

    #rescue Exception => e
    #  log "Encountered error: #{e.class} #{e}"
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
