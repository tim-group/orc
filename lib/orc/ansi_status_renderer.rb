class Orc::AnsiStatusRenderer
  def render(statuses)
    buffer = ""
    keys = [:host, :application, :group, :present, :version, :participating, :health, :stoppable]
    lengths = {}
    keys.each do |key|
      lengths[key] = key.to_s.length
    end

    statuses.each do |status|
      keys.each do |key|
        len = status[key].to_s.length
        lengths[key] = len if lengths[key] < len
      end
    end

    header_buffer = ""
    keys.each do |key|
      header_buffer << "#{key}"
      rem = lengths[key] - key.to_s.length + 1
      header_buffer << " " * rem
    end

    buffer << Color.new(:text => header_buffer).header.display

    statuses.sort_by { |s| s[:host] }.each do |status|
      color = status[:group]
      status_buffer = ""
      keys.each do |key|
        status_buffer << "#{status[key]}"
        rem = lengths[key] - status[key].to_s.length + 1
        status_buffer << " " * rem
      end
      buffer << Color.new(:text => status_buffer).color(color).display
    end

    buffer
  end

  class Color
    def initialize(args)
      @text = args[:text]
      @colors = { "white" => 37, "cyan" => 36, "pink" => 35, "blue" => 34, "yellow" => 33, "green" => 32, "red" => 31, "grey" => 30 }
    end

    def color(color)
      @text = "\e[1;#{@colors[color]}m#{@text}\e[0m"
      self
    end

    def header
      @text = "\e[1;45m#{@text}\e[0m"
      self
    end

    def display
      "#{@text}\e[0m\n"
    end
  end
end
