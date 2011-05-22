module FFMpeg
  class Convert
    attr_accessor :input, :output, :version, :frame, :total_time, :total_frames

    def initialize(input, output, options={})
      @input   = input
      @output  = output
      @options = options
    end

    def execute
      # usage: ffmpeg [options] [[infile options] -i infile]...
      #                         {[outfile options] outfile}...

      cmd = if @options[:offset]
        offset_command
      else
        "ffmpeg -i #{ input } #{ output }"
      end

      IO.popen([*cmd.split(/\s+/), :err=>[:child, :out]]) do |out|
        while line = out.gets
          process_output_line(line)
        end
      end
    end

    def offset_command
      # start with just our input video
      cmd = "ffmpeg -i #{ input }"
      # add the amount of shift required (direction doesn't matter yet)
      cmd << " -itsoffset #{ to_hms @options[:offset].abs }"
      # reference our input file again to get the other track
      cmd << " -i #{ input }"

      if @options[:offset] > 0
        # shift audio forward by :offset seconds
        # TODO : this assumes input file has one video and one audio stream.
        # add a way to determine input content and map streams appropriately
        cmd << " -map 0:0 -map 1:1"
      else
        # shift video forward by :offset seconds
        cmd << " -map 1:0 -map 0:1"
      end

      cmd << " #{ output }"

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

__END__

ffmpeg -i test/input.mov test/output.flv

FFmpeg version 0.6.2, Copyright (c) 2000-2010 the FFmpeg developers
  built on May 19 2011 13:02:05 with gcc 4.2.1 (Apple Inc. build 5666) (dot 3)
  configuration: --disable-debug --prefix=/Users/solo/Developer/Cellar/ffmpeg/0.6.2 --enable-shared --enable-pthreads --enable-nonfree --enable-gpl --disable-indev=jack --enable-libx264 --enable-libfaac --enable-libmp3lame --enable-libtheora --enable-libvorbis --enable-libvpx --enable-libxvid --enable-libfaad
  libavutil     50.15. 1 / 50.15. 1
  libavcodec    52.72. 2 / 52.72. 2
  libavformat   52.64. 2 / 52.64. 2
  libavdevice   52. 2. 0 / 52. 2. 0
  libswscale     0.11. 0 /  0.11. 0

Seems stream 0 codec frame rate differs from container frame rate: 600.00 (600/1) -> 12.00 (12/1)
Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'test/input.mov':
  Metadata:
    title           : QuickTime Sample Movie
    title-eng       : QuickTime Sample Movie
    copyright       : © Apple Computer, Inc. 2001
    copyright-eng   : © Apple Computer, Inc. 2001
  Duration: 00:00:05.00, start: 0.000000, bitrate: 131 kb/s
    Stream #0.0(eng): Video: svq1, yuv410p, 190x240, 97 kb/s, 12 fps, 12 tbr, 600 tbn, 600 tbc
    Stream #0.1(eng): Audio: qdm2, 22050 Hz, 2 channels, s16, 32 kb/s
Output #0, flv, to 'test/output.flv':
  Metadata:
    encoder         : Lavf52.64.2
    Stream #0.0(eng): Video: flv, yuv420p, 190x240, q=2-31, 200 kb/s, 1k tbn, 12 tbc
    Stream #0.1(eng): Audio: libmp3lame, 22050 Hz, 2 channels, s16, 64 kb/s
Stream mapping:
  Stream #0.0 -> #0.0
  Stream #0.1 -> #0.1
Press [q] to stop encoding
frame=   60 fps=  0 q=2.0 Lsize=     210kB time=4.99 bitrate= 345.6kbits/s    
video:167kB audio:39kB global headers:0kB muxing overhead 2.041425%
.
Finished in 0.245313 seconds.

