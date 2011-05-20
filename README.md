# FFMPEG WRAPPER

Ruby wrapper around ffmpeg CLI to resync audio and video


ffmpeg -i out.ogg -itsoffset 4.267 -i out.ogg -map 1:0 -map 0:1 -ar 22050 video.flv

also check out:

ffmpeg -async
