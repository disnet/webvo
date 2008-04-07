# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def prog_table_header options = {:size => false, :description => false}
    header_html = "<tr>"
    header_html += "<th>Title</th>"
    header_html += "<th>Episode Title</th>"
    header_html += "<th>Episode</th>"
    header_html += "<th>Description</th>" if options[:description]
    header_html += "<th>Start</th>"
    header_html += "<th>End</th>"
    header_html += "<th>Channel</th>"
    header_html += "<th>Size</th>" if options[:size]
    header_html += "<th>Checkbox</th>"
    header_html += "</tr>"
  end

  def prog_table_listing item , start, stop
    def minutes_overlap (start, stop, range_start, range_stop)
      start = range_start if start < range_start
      stop = range_stop if stop > range_stop
      (stop - start).to_i/60
    end
    type = 'listing'
    minutes_in_range = (stop - start).to_i/60
    table_html = "<table id=\"schedule_table\" class=\"schedule_table\"><tr class=\"empty\">"
    (minutes_in_range + 1).times { table_html += "<td/>" }
    table_html += "</tr><tr>"
    table_html += "<th>Ch.</th>"

    hours = []
    hour = start - start.min * 60 - start.sec
    while hour < stop
      hours << hour
      hour += 60 * 60
    end

    hours.each {|hour|
      table_html += "<th colspan=\"30\">#{hour.strftime("%I:00%p")}</th>"
      table_html += "<th colspan=\"30\">#{hour.strftime("%I:30%p")}</th>"
    }
    table_html += '</tr>'

    item.sort {|a,b| a[0].fcc_channel_number <=> b[0].fcc_channel_number}.each do |arr|
      station = arr[0]
      table_html += "<tr><td class=\"channelName\">#{station.display_name}</td>"
      arr[1].each do |prog|
        #TODO: move minutes_overlap/colspan to program controller?
        progcolspan = '"' + minutes_overlap(prog.time, prog.stop_time, start, stop).to_s + '"'
        table_html += "<td id=\"#{type}#{prog.id}\" class=\"#{prog.css_class}\" colspan=#{progcolspan}>#{prog.title}</td>"
      end
      table_html += "</tr>"
    end

    table_html += "</table>"
    table_html.gsub(/'/,"&#39;")
  end

  def prog_json_programs item, options = {:size => false, :description => false}
    progs = []
    item.each do |prog|
      progs << prog_json_row( prog, options )
    end
    progs.to_json
  end

  def prog_json_row item, options = {:size => false, :description => false}
    type = options[:type]
    json = {}
    json[:id] = item.id
    #"{ 'id':'#{prog.id}',"
    json[:html_id] = type + item.id.to_s
    #"'html_id': '#{@type}#{prog.id}',"
    json[:start] = item.time.xmlschema
    #"'start': '#{prog.start_time.xmlschema}',"
    json[:stop] = item.stop_time.xmlschema
    #"'stop': '#{prog.stop_time.xmlschema}',"
    json[:html] = 
        "<tr id=\"#{json[:html_id]}\" class=\"#{item.css_class}\">" +
        "<td>#{item.title}</td>" +
        "<td>#{item.subtitle}</td>" +
        "<td>#{item.syndicated_episode_number}</td>"
    json[:html] += 
        "<td>#{item.description}</td>" if options[:description]
    json[:html] += 
        "<td>#{item.time_readable}</td>" +
        "<td>#{item.stop_time_readable}</td>" +
        "<td>#{item.fcc_channel_number}</td>"
    json[:html] += 
        "<td class=\"filesize\">r{prog.size_readable}</td>" if options[:size]
    json[:html] += 
        "<td><input name=\"#{type}Check\" type=\"checkbox\" value=\"#{item.id}\"/></td></tr>"
    json[:html] = '' if type == 'listing'
    json[:title] = item.title if type == 'listing'
    json[:sub_title] = item.subtitle if type == 'listing'
    json[:episode] = item.syndicated_episode_number if type == 'listing'
    json[:desc] = item.description if type == 'listing'
    json
  end
end
