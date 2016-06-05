
# clean it up from temporary files
function clear_workspace {
	rm -f video.txt audio.txt mylist.txt stream_audio.mp3 stream_video.mp4 stream_video_cut.mp4 output.mp4 ffmpeg2pass-0.log
}

trap clear_workspace EXIT

# mask results of previous encode to avoid prompts for overwrite
[ -e "res.webm" ] && mv res.webm res`ls -l | wc -l`.webm
clear_workspace

if [[ "$1" =~ "^http" ]]; then
	curl -sO $1 &
fi

if [[ "$2" =~ "^http" ]]; then
	curl -sO $2 &
fi

if [[ "$3" != "" ]]; then 
	filename="$3"
fi
filename=${filename:-res.webm}

wait

audio="`ls -1t *.mp3 | head -n1`"
video="`ls -1t *.mp4 | head -n1`"

# reads data on audio/video
audiodata=`ffprobe.exe "$audio" 2>&1 | tee audio.txt`
videodata=`ffprobe.exe "$video" 2>&1 | tee video.txt`

# extracts defaults
audio_duration=`echo $audiodata | grep -oE "Duration: [^ ]+" | grep -oE "[0-9]+\.[0-9]+"`
video_duration=`echo $videodata | grep -oE "Duration: [^ ]+" | grep -oE "[0-9]+\.[0-9]+"`

num_def=1
rate_def=1200

# outputs basic information, video duration being the most valuable
cat audio.txt | grep -iE "(Duration)|(Stream)|(Input)"
cat video.txt | grep -iE "(Duration)|(Stream)|(Input)"

read -p "Video repeat [$num_def]:" num
num=${num:-$num_def}

# powershell for float math as I do have mingw, but bc not part of it yet
duration_def=`powershell ${video_duration} \* ${num}`
scale_def=`echo "$videodata" | grep -E "Stream" | grep -oE " [0-9]+x[0-9]+ "| grep -oE "x[0-9]+" | grep -oE "[0-9]+"`

read -p "Duration [$duration_def]:" duration
duration=${duration:-$duration_def}

read -p "Scale [$scale_def]:" scale
scale=${scale:-$scale_def}

read -p "Rate [$rate_def]:" rate
rate=${rate:-$rate_def}

# creating the config for repeated video assembly and invoking it
if [ "$num" -eq 1 ]
then
  cp "$video" stream_video.mp4
else
  for i in $(seq 1 ${num}); do printf "file '%s'\n" "$video" >> mylist.txt; done
  ffmpeg -ss 0 -t ${duration} -f concat -i mylist.txt -c copy stream_video.mp4 &
fi

# cutting audio/video to setup length
ffmpeg -ss 0 -t ${duration} -i "$audio" stream_audio.mp3 &
wait
if [[ $duration == $video_duration ]]; then
	mv stream_video.mp4 stream_video_cut.mp4
else
	ffmpeg -ss 0 -t ${duration} -i stream_video.mp4 stream_video_cut.mp4
fi

# combining audio+video
ffmpeg -i stream_video_cut.mp4 -i stream_audio.mp3 -c:v copy -c:a aac -strict experimental -map 0:v:0 -map 1:a:0 output.mp4

# 2-pass encoding with everything in place to $filename.webm
ffmpeg -i output.mp4 -codec:v libvpx -quality good -cpu-used 0 -b:v ${rate}k -maxrate ${rate}k -bufsize `expr ${rate} \* 2`k -qmin 10 -qmax 42 -vf scale=-1:${scale} -threads 4 -strict -2 -codec:a vorbis -b:a 128k -an -pass 1 -f webm -y /dev/null
ffmpeg -i output.mp4 -codec:v libvpx -quality good -cpu-used 0 -b:v ${rate}k -maxrate ${rate}k -bufsize `expr ${rate} \* 2`k -qmin 10 -qmax 42 -vf scale=-1:${scale} -threads 4 -strict -2 -codec:a vorbis -b:a 128k -pass 2 $filename.webm
clear_workspace

