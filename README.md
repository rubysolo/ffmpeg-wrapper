# FFMPEG WRAPPER

Ruby wrapper around ffmpeg CLI for video conversion


## RUBY API

For simple format conversions, simply specify the input and output
filenames:

    FFMpeg.convert("input.flv", "output.mov")

To control the output, pass an options hash:

    FFMpeg.convert("input.flv", "output.mp4", :offset => 5)

Currently, the only option supported is *offset*.  :)


## DEPENDENCIES

* ffmpeg binary in your PATH


## INCLUDED UTILITIES

* resync : shift the audio track of a movie file forward or backward

usage:

    resync 5 nsync.mov

This will push the audio track five seconds forward and write the result
to *nsync-fixed.mov*
