class AnsiStatusRenderer
  def render(statuses)
    buffer =""
    keys = [:host,nil,:application,:group,:present,:version,:participating]
    header_buffer = ""
    keys.each do |key|
      header_buffer << "\t#{key}"
    end

    buffer << Color.new(:text=>header_buffer).header().display()

    statuses.instances.each do |status|
      color = status[:group]
      present = status[:present]

      status_buffer = "\n "
      keys.each do |key|
        if (key!=nil)
          status_buffer << "\t#{status[key]}"
        end
      end
      status_buffer << "\n "
      buffer << Color.new(:text=>status_buffer).color(color).highlight(present).display()
    end

    return buffer
  end
end

class Color
  def initialize args
    @text=args[:text]
    @colors= {"blue"=>34,"green"=>32}
  end

  def color color
    @text="\e[1;#{@colors[color]}m#{@text}"
    return self
  end

  def highlight highlight
    if (highlight)
      @text="\e[1;40m#{@text}"
    end
    return self
  end

  def header
    @text="\e[1;45m#{@text}"
    return self
  end

  def display
    return "#{@text}\e[0m\n"
  end
end
