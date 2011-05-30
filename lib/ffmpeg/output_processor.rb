module FFMpeg
  class OutputProcessor
    class << self
      HMS = '\d{2}:\d{2}:\d{2}\.\d{2}'

      def process(converter, output)
        case output
        when /^ffmpeg version ([^,]+), copyright/i
          converter.version = $1

        when /^input.*from/i
          converter.capturing = :input

        when /^output.*to/i
          converter.capturing = :output

        when /Press \[q\] to stop encoding/
          converter.capturing = :progress

        when /^\s*duration: (#{ HMS })/i
          converter.total_time = parse_hms($1) if converter.capturing_input?

        when /^\s*stream.*video:.*\s+([0-9.]+)\s*fps/i
          if converter.capturing_input?
            converter.input_fps = $1.to_f
            converter.total_frames = converter.input_fps * converter.total_time
          end

        when /^frame=\s*(\d+)/i
          converter.frame = $1.to_i
        end
      end

      def parse_hms(hmsms)
        hms, ms = hmsms.split('.')
        h, m, s = hms.split(':')
        s.to_i + (m.to_i * 60) + (h.to_i * 3600) + "0.#{ ms }".to_f
      end
    end
  end
end
