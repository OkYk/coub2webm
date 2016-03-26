# coub2webm
ffmpeg-based script to re-assemble coubs into webm
that is - multiplies the video defined number of times, combines with audio, cuts and encodes to webm

pre-requirements for windows:
mingw packages: 32base msysbase developer-tools
powershell

for *nix replace the powershell with bc float-point calculation (or make defaule static)

assumes that audio.mp3 and video.mp4 are in the same folder, asks simple questions with defaults available
check details in the comments of the script itself
