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

  def test_custom_ffmpeg_command_from_ENV
    with_custom_ffmpeg do
      assert_equal 'ffmpeg', FFMpeg::Convert.base_command

      with_custom_ffmpeg(`which ffmpeg`) do
        assert_not_equal 'ffmpeg', FFMpeg::Convert.base_command
      end
    end
  end

  def test_catching_missing_ffmpeg_binary
    with_custom_ffmpeg('frabshackle') do
      assert_not_equal 'ffmpeg', FFMpeg::Convert.base_command

      assert_raises(RuntimeError) {
        FFMpeg.convert("in", "out")
      }
    end
  end

  private

  def with_custom_ffmpeg(ffmpeg=nil)
    original = ENV['FFMPEG']
    ffmpeg = ffmpeg.strip unless ffmpeg.nil?
    ENV['FFMPEG'] = ffmpeg
    yield
    ENV['FFPMEG'] = original
  end
end
