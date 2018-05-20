#! /bin/bash

echo NON-PREEMPTIVE SJF

read -p "File: " filename
chmod 755 ./"$filename"


sorted=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename)
procnos=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 1 -d,  | sed 's/[^0-9]*//g')
arrivals=$(cut -f 2 -d, $filename |  sort -n --field-separator=',' -k2,2 -k3,3)
bursts=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 3 -d, )
sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 3 -d,   > sortedbursts
cut -f 2 -d, $filename |  sort -n --field-separator=',' -k2,2 -k3,3 > sortedarrivals

echo $arrivals
echo $procnos
echo $bursts

list=()
counter=0
for i in ${procnos[@]};
do
	pnumber=$i
	((counter+=1))
	burst=$(cut -d$'\n' -f $(($counter))  sortedbursts)
	list+=("[Process: $pnumber, $burst ]")
done

echo "${list[@]}" > output.txt
echo "${list[@]}"

# GET WAIT AND TURNAROUND
maxarrival=$(echo $arrivals | rev | cut -d" " -f 1)
maxarrival=`expr $(($maxarrival)) + 1`
firstarrival=$(echo $arrivals | cut -d" " -f 1)

currp=0
totaltime=0
counter=0
turnaround=0
waittime=0

for i in ${arrivals[@]};
do
	((counter+=1))
	burst=$(cut -d$'\n' -f $(($counter))  sortedbursts)
	arrival=$(cut -d$'\n' -f $(($counter))  sortedarrivals)
	if [[ $i == $first ]]
		then
			echo "this was fisrt"
			turnaround=$(($burst))
			totaltime=`expr $totaltime + $(($burst))`
	else
		waittime=`expr $waittime + $totaltime - $(($arrival))`
		totaltime=`expr $totaltime + $(($burst))`
		turnaround=`expr $turnaround + $waittime + $(($burst))`
	fi
done

averagewt=`expr $waittime / ${#arrivals}`
averagett=`expr $turnaround / ${#arrivals}`
echo "Average Waiting Time: $averagewt"
echo "Average Turnaround Time: $averagett"
