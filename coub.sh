id=$1
if [[ "$1" =~ "^[0-9a-z]{5}$" ]]; then
	coubData=`curl -s https://coub.com/api/v2/coubs/$id.json`
	wait
	videoname=`echo $coubData | grep -oE "http[^\"]+\.mp4" | head -n1`
	audioname=`echo $coubData | grep -oE "http[^\"]+\.mp3" | head -n1`
	sh encode.sh $videoname $audioname $id
else
	echo "Id expected [0-9a-z]{5}";
	exit;
fi
