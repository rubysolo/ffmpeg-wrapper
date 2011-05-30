module FFMpeg
  class Convert
    attr_accessor :version, :total_time, :frame, :total_frames, :capturing,
                  :input_fps

    def initialize(input, output, options={})
      @input   = input
      @output  = output
      @options = options

      failure_msg = "FATAL:  cannot find ffmpeg command"
      failure_msg << " (#{ self.class.base_command })"

      self.class.system_command(failure_msg) do
        cmd = "#{ self.class.base_command } --version 2> /dev/null"
        system cmd
      end
    end

    def self.base_command
      ENV['FFMPEG'] || 'ffmpeg'
    end

    def self.system_command(message)
      begin
        yield
      rescue Errno::ENOENT => e
        raise message
      end
    end

    def execute
      # usage: ffmpeg [options] [[infile options] -i infile]...
      #                         {[outfile options] outfile}...

      cmd = if @options[:offset]
        offset_command
      else
        [self.class.base_command, "-i", @input, @output]
      end


      self.class.system_command("could not find #{ self.class.base_command }") do
        IO.popen([*cmd, :err=>[:child, :out]]) do |out|
          while line = out.gets
            process_output_line(line)
          end
        end
      end
    end

    def offset_command
      # start with just our input video
      cmd = [self.class.base_command, "-i", @input]

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


    def process_output_line(line)
      OutputProcessor.process(self, line)
    end

    def to_hms(seconds)
      seconds, ms      = seconds.divmod 1
      minutes, seconds = seconds.divmod 60
      hours, minutes   = minutes.divmod 60

      '%02d:%02d:%02d.%03d' % [hours, minutes, seconds, ms.round(10) * 1000]
    end
  end

  def self.convert(input, output, options={})
    Convert.new(input, output, options).execute
  end
end
