module FFMpeg
  class Convert
    attr_reader :version, :total_time, :frame, :total_frames

    def initialize(input, output, options={})
      @input   = input
      @output  = output
      @options = options
    end

    def self.base_command
      ENV['FFMPEG'] || 'ffmpeg'
    end

    def execute
      # usage: ffmpeg [options] [[infile options] -i infile]...
      #                         {[outfile options] outfile}...

      cmd = if @options[:offset]
        offset_command
      else
        ["ffmpeg", "-i", @input, @output]
      end

      IO.popen([*cmd, :err=>[:child, :out]]) do |out|
        while line = out.gets
          process_output_line(line)
        end
      end
    end

    def offset_command
      # start with just our input video
      cmd = ["ffmpeg", "-i", @input]

      # add the amount of shift required (direction doesn't matter yet)
      cmd += ["-itsoffset", to_hms(@options[:offset].abs)]

      # reference our input file again to get the other track
      cmd += ["-i", @input]

      if @options[:offset] > 0
        # shift audio forward by :offset seconds
        # TODO : this assumes input file has one video and one audio stream.
        # add a way to determine input content and map streams appropriately
        cmd += %w(-map 0:0 -map 1:1)
      else
        # shift video forward by :offset seconds
        cmd += %w(-map 1:0 -map 0:1)
      end

      cmd << @output

      cmd
    end

    def progress
      return nil if frame.nil? || total_frames.nil?
      frame / total_frames.to_f
    end

    def capturing_input?
      @capturing == :input
    end

    def capturing_output?
      @capturing == :output
    end

    private

    HMS = '\d{2}:\d{2}:\d{2}\.\d{2}'

    def process_output_line(line)
      case line
      when /^ffmpeg version ([^,]+), copyright/i
        @version = $1

      when /^input.*from/i
        @capturing = :input

      when /^output.*to/i
        @capturing = :output

      when /Press \[q\] to stop encoding/
        @capturing = :progress

      when /^\s*duration: (#{ HMS })/i
        @total_time = parse_hms($1) if capturing_input?

      when /^\s*stream.*video:.*\s+([0-9.]+)\s*fps/i
        if capturing_input?
          @input_fps = $1.to_f
          @total_frames = @input_fps * @total_time
        end

      when /^frame=\s*(\d+)/i
        @frame = $1.to_i
      end
    end

    def to_hms(seconds)
      seconds, ms      = seconds.divmod 1
      minutes, seconds = seconds.divmod 60
      hours, minutes   = minutes.divmod 60

      '%02d:%02d:%02d.%03d' % [hours, minutes, seconds, ms.round(10) * 1000]
    end

    def parse_hms(hmsms)
      hms, ms = hmsms.split('.')
      h, m, s = hms.split(':')
      s.to_i + (m.to_i * 60) + (h.to_i * 3600) + "0.#{ ms }".to_f
    end
  end

  def self.convert(input, output, options={})
    Convert.new(input, output, options).execute
  end
end
