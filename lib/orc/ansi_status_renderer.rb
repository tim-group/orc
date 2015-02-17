class Orc::AnsiStatusRenderer
  def render(statuses)
    buffer =""
    keys = [:host,:application,:group,:present,:version,:participating,:health]
    lengths = {}
    keys.each do |key|
      lengths[key] = key.to_s.length
    end

    statuses.each do |status|
      keys.each do |key|
         len = status[key].to_s.length
         if lengths[key] < len
           lengths[key] = len
         end
      end
    end

    header_buffer = ""
    keys.each do |key|
      header_buffer << "#{key}"
      rem = lengths[key] - key.to_s.length + 1
      (1..rem).to_a.each { |x| header_buffer << " "}
    end

    buffer << Color.new(:text=>header_buffer).header().display()

    statuses.each do |status|
      color = status[:group]
      present = status[:present]
      status_buffer = ""
      keys.each do |key|
        status_buffer << "#{status[key]}"
        rem = lengths[key] - status[key].to_s.length + 1
        (1..rem).to_a.each { |x| status_buffer << " "}
      end
      status_buffer << "\n "
      buffer << Color.new(:text=>status_buffer).color(color).highlight(present).display()
    end

    return buffer
  end

  class Color
    def initialize args
      @text=args[:text]
      @colors= {"cyan"=>36,"pink"=>35,"blue"=>34,"yellow"=>33,"green"=>32,"red"=>31,"grey"=>30}
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
end
