#!/bin/bash
mkdir -p arch
curl -so hot.json https://coub.com/api/v1/timeline/hot.json?page=17&per_page=120
wait
grep -oE "(permalink...[0-9a-z]{5}\")|([^\"]+mp4)|([^\"]+mp3)" hot.json | grep -v version > proc.txt

code=
while read p; do
 if [[ "$p" =~ "perm" ]]; then
    if [[ "$code" != "" ]]; then
	  echo "$code - $mp4 - $mp3" >> log.txt
	  `curl -O $mp4`
	fi
    code=`echo $p | grep -oE ".....\"" | grep -oE "....."`
	mp4=
	mp3=
 elif [[ "$p" =~ ".mp3" ]]; then
	mp3=${mp3:-$p}
 elif [[ "$p" =~ ".mp4" ]]; then
	mp4=${mp4:-$p}
 fi
done < proc.txt

for file in ./*.mp4
do
	echo "$file"
	ffplay $file
	save_def="n"
	read -p "Save? [n]:" save
	save=${save:-$save_def}
	if [ "$save" == "n" ]; then
	  rm $file
	  echo "rm $file" >> log.txt
	fi
done

mv *.mp4 ./arch/
cat log.txt >> arch/log.txt
rm log.txt
