require 'xml/libxml'

class DataLoader < ActiveRecord::Base
  def self.find_xml_content(xml, name, namespace)
    found = xml.find('urn:' + name, 'urn:' + namespace).first
    if found.nil?
      nil
    else
      found.content
    end
  end
  def self.load_data
    file_name = "#{RAILS_ROOT}/tmp/dd-data.xml"
    system( "tv_grab_na_dd --config-file " + XMLTV_CONFIG + 
      " --dd-data #{file_name} --download-only --days 1 ")

    namespace = 'urn:TMSWebServices'
    search_ns = 'urn:' + namespace
    puts "loading file"
    xmldoc = XML::Document.file(file_name)
    puts "file loaded"

    xmldoc.find('//urn:station', search_ns).each do |st|
      station = Station.find_or_create_by_id st.property('id')
      station.callsign = find_xml_content(st, 'callSign', namespace)
      station.name = find_xml_content(st, 'name', namespace)
      station.affiliate = find_xml_content(st, 'affiliate', namespace)
      station.fcc_channel_number = 
        find_xml_content(st, 'fccChannelNumber', namespace)
      
      station.save
    end

    xmldoc.find('//urn:lineup', search_ns).each do |lnup|
      lineup = Lineup.find_or_create_by_id lnup.property('id')
      lineup.name = lnup.property 'name'
      lineup.location = lnup.property 'location'
      lineup.device = lnup.property 'device'
      lineup.media_type = lnup.property 'type'
      lineup.postal_code = lnup.property 'postalCode'

      if lineup.save
        lnup.find('urn:map', search_ns).each do |map|
          station_id = map.property 'station'
          mapped_station = MappedStation.find_or_initialize_by_lineup_id_and_station_id(
            lineup.id, station_id)
          mapped_station.channel = map.property 'channel'
          mapped_station.channel_minor = map.property 'channelMinor'
          mapped_station.from = map.property 'from'
          mapped_station.to = map.property 'to'

          lineup.mapped_stations << mapped_station
        end
      end

    end

    xmldoc.find('//urn:schedule', search_ns).each do |sched|
      #TODO: deal with overlapping shows
      schedule = Schedule.find_or_initialize_by_program_id_and_station_id_and_time(
        sched.property('program'), 
        sched.property('station'), 
        Time.xmlschema(sched.property('time')))
      schedule.duration = sched.property 'duration'
      dur = schedule.duration.match /PT(\d\d)H(\d\d)M/
      schedule.stop_time = schedule.time + dur[1].to_i*60*60 + dur[2].to_i*60
      schedule.new = sched.property 'new'
      schedule.stereo = sched.property 'stereo'
      schedule.subtitled = sched.property 'subtitled'
      schedule.hdtv = sched.property 'hdtv'
      schedule.close_captioned = sched.property 'closeCaptioned'
      schedule.tv_rating = sched.property 'tvRating'
      part = sched.find('urn:part', search_ns).first
      unless part.nil?
        schedule.part_number = part.property 'number'
        schedule.part_total = part.property 'total'
      end
      
      schedule.save
    end

    xmldoc.find('//urn:program', search_ns).each do |prog|
      program = Program.find_or_initialize_by_id( prog.property('id'))
      program.title = find_xml_content(prog, 'title', namespace)
      program.subtitle = find_xml_content(prog, 'subtitle', namespace)
      program.description = find_xml_content(prog, 'description', namespace)
      program.mpaa_rating = find_xml_content(prog, 'mpaaRating', namespace)
      program.star_rating = find_xml_content(prog, 'starRating', namespace)
      program.runtime = find_xml_content(prog, 'runTime', namespace)
      program.year = find_xml_content(prog, 'year', namespace)
      program.show_type = find_xml_content(prog, 'showType', namespace)
      program.color_code = find_xml_content(prog, 'colorCode', namespace)
      program.original_air_date = 
        find_xml_content(prog, 'originalAirDate', namespace)
      program.syndicated_episode_number = 
        find_xml_content(prog, 'syndicatedEpisodeNumber', namespace)

      if program.save
        prog.find('urn:advisories/urn:advisory', search_ns).each do |advis|
          program.advisories << Advisory.find_or_create_by_program_id_and_advisory(
            program.id, advis.content)
        end
      end
    end

    xmldoc.find('//urn:crew', search_ns).each do |crew|
      program_id = crew.property 'program'
      crew.find('urn:member', search_ns).each do |member|
        role = find_xml_content(member, 'role', namespace)
        given_name = find_xml_content(member, 'givenname', namespace)
        surname = find_xml_content(member, 'surname', namespace)
        Crew.find_or_create_by_program_id_and_role_and_given_name_and_surname(
          program_id, role, given_name, surname)
      end
    end

    xmldoc.find('//urn:programGenre', search_ns).each do |prog_genre|
      program_id = prog_genre.property 'program'
      prog_genre.find('urn:genre', search_ns).each do |gen|
        classification = find_xml_content(gen, 'class', namespace)
        relevance = find_xml_content(gen, 'relevance', namespace)
        Genre.find_or_create_by_program_id_and_classification_and_relevance(
          program_id, classification, relevance)
      end
    end

    xmldoc.find('//message').each do |message|
      puts "Message: #{message.content}"
    end
  end
end
