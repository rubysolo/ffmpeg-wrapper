# FFMPEG WRAPPER

Ruby wrapper around ffmpeg CLI to resync audio and video

## INCLUDED UTILITIES

* resync : shift the audio track of a movie file forward or backward

usage:

    resync 5 nsync.mov

This will push the audio track five seconds forward and write the result
to *nsync-fixed.mov*
