require File.expand_path('../../lib/ffmpeg', __FILE__)
require 'test/unit'
require 'fileutils'

class TestFFMPegConvert < Test::Unit::TestCase
  def setup
    FileUtils.rm_f "test/output.flv"
  end

  def teardown
    FileUtils.rm_f "test/output.flv"
  end

  def test_ffmpeg_execution
    assert_nothing_raised {
      FFMpeg.convert("test/fixtures/input.mov", "test/output.flv")
      assert File.exist?("test/output.flv")
    }
  end

  def test_filenames_with_spaces
    assert_nothing_raised {
      FFMpeg.convert(
        "test/fixtures/filename with spaces.mov",
        "test/output.flv"
      )
      assert File.exist?("test/output.flv")
    }
  end

  def test_process_output
    c = FFMpeg::Convert.new("foo", "bar")
    c.send(
      :process_output_line,
      "FFmpeg version 0.6.2, Copyright (c) 2000-2010 the FFmpeg developers"
    )
    assert_equal "0.6.2", c.version

    c.send(
      :process_output_line,
      "Input #0, mov,mp4,m4a,3gp,3g2,mj2, from 'test/input.mov':"
    )
    assert c.capturing_input?
    refute c.capturing_output?

    c.send(
      :process_output_line,
      "  Duration: 00:00:05.00, start: 0.000000, bitrate: 131 kb/s"
    )
    assert_equal 5.0, c.total_time

    str = "    Stream #0.0(eng): Video: svq1, yuv410p, 190x240, " +
          "97 kb/s, 12 fps, 12 tbr, 600 tbn, 600 tbc"
    c.send(:process_output_line, str)
    assert_equal 60, c.total_frames

    str = "frame=   30 fps=  0 q=2.0 Lsize=     210kB time=2.49 " +
          "bitrate= 345.6kbits/s    "
    c.send(:process_output_line, str)
    assert_equal 0.5, c.progress
  end

  def test_offset_command
    c = FFMpeg::Convert.new("foo", "bar", :offset => 5.3)
    cmd = c.offset_command * ' '

    assert_match %r{-itsoffset 00:00:05.300}, cmd
    assert_match %r{-map 0:0 -map 1:1}, cmd

    c = FFMpeg::Convert.new("foo", "bar", :offset => -83)
    cmd = c.offset_command * ' '

    assert_match %r{-itsoffset 00:01:23.000}, cmd
    assert_match %r{-map 1:0 -map 0:1}, cmd
  end
end
