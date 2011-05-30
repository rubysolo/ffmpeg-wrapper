require File.expand_path('../../lib/ffmpeg', __FILE__)
require 'test/unit'
require 'fileutils'

class TestOutputProcessor < Test::Unit::TestCase
  def test_process_output
    c = FFMpeg::Convert.new("foo", "bar")
    FFMpeg::OutputProcessor.process(c,
      "FFmpeg version 0.6.2, Copyright (c) 2000-2010 the FFmpeg developers"
    )
    assert_equal "0.6.2", c.version

    FFMpeg::OutputProcessor.process(c,
      "Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'test/input.mov':"
    )
    assert c.capturing_input?
    refute c.capturing_output?

    FFMpeg::OutputProcessor.process(c,
      "  Duration: 00:00:05.00, start: 0.000000, bitrate: 131 kb/s"
    )
    assert_equal 5.0, c.total_time

    str = "    Stream #0.0(eng): Video: svq1, yuv410p, 190x240, " +
          "97 kb/s, 12 fps, 12 tbr, 600 tbn, 600 tbc"
    FFMpeg::OutputProcessor.process(c, str)
    assert_equal 60, c.total_frames

    str = "frame=   30 fps=  0 q=2.0 Lsize=     210kB time=2.49 " +
          "bitrate= 345.6kbits/s    "
    FFMpeg::OutputProcessor.process(c, str)
    assert_equal 0.5, c.progress
  end
end
