#! /bin/bash

echo NON-PREEMPTIVE SJF

read -p "File: " filename
chmod 755 ./"$filename"

#Sort according to priority: k2,2(arrival) and k3,3(burst)
sorted=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename)
procnos=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 1 -d,  | sed 's/[^0-9]*//g')
arrivals=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 2 -d,)
bursts=$(sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 3 -d, )
sort -n --field-separator=',' -k2,2 -k3,3 $filename | cut -f 3 -d,   > sortedbursts
cut -f 2 -d, $filename |  sort -n --field-separator=',' -k2,2 -k3,3 > sortedarrivals

# echo $arrivals
# echo $procnos
# echo $bursts

#Loop process numbers and their bursts to list
list=()
counter=0
for i in ${procnos[@]};
do
	pnumber=$i
	((counter+=1))
	burst=$(cut -d$'\n' -f $(($counter))  sortedbursts)
	list+=("[Process: $pnumber, $burst ]")
done

#Print List
# echo "${list[@]}" > output.txt
# echo "${list[@]}"

#Print Gantt
s=$filename
declare -a remaining_time
declare -a arrival_time
declare -a completed_at
declare -a name
declare -a out
declare -a lines

# Create array with all the names of the processes

i=0
for line in `sort -n --field-separator=',' -k2,2 -k3,3 $s | cut -d ',' -f1`
do
	name[i]="$line"
	i=$((i+1))
done

# Create array with all the remaining times of the processes

i=0
for line in `sort -n --field-separator=',' -k2,2 -k3,3 $s | cut -d ',' -f3`
do
	remaining_time[i]="$line"
	i=$((i+1))
done

# Create array with all the arrival times of the processes

i=0
for line in `sort -n --field-separator=',' -k2,2 -k3,3 $s | cut -d ',' -f2`
do
	arrival_time[i]="$line"
	i=$((i+1))
done

end=false
current_time=0
while [ end != true ]
do

	# Loop through all, determine if any processes have a Remaining Burst Time > 0, else break out of the loop
	is_done=true
	is_done=$(for time_left in "${remaining_time[@]}"
		do
			if [ $time_left -gt 0 ] 
			then
				echo false
				break
			fi  
		done)
	if [ "$is_done" != false ] 
	then	
		break
	fi

	# Return the process number of the first process in the ready queue, else wait
	nearest_arrival=999999
	nearest_arrival_index=-1
	array_end_index=$((${#arrival_time[@]}-1))
	nearest_arrival_index=$(
	for i in "${!arrival_time[@]}"
		do
			if [ ${arrival_time[i]} -lt $nearest_arrival ] && [ ${remaining_time[i]} -gt 0 ] 
			then	

				nearest_arrival=${arrival_time[i]}
				nearest_arrival_index=$i			
			fi
			if [ $i -eq $array_end_index ]
			then
				echo $nearest_arrival_index
				break
			fi 
			i=$((i+1))			
		done
	)

	if [ ${arrival_time[nearest_arrival_index]} -gt $current_time ] 
	then
		current_time=$((current_time+1))
		out+=(-1)
	else
		current_time=$((current_time+remaining_time[$nearest_arrival_index]))
		for ((i=0 ; i < ${remaining_time[nearest_arrival_index]} ; i++ ))
		do
			out+=($nearest_arrival_index)
		done		
		remaining_time[$nearest_arrival_index]=0
		completed_at[$nearest_arrival_index]=$current_time
	fi
done


for i in "${!arrival_time[@]}" 
do
	lines[$i]=' '
	for output in ${out[@]} 
	do
		if [ "$output" -eq "$i" ]
		then
			lines[$i]=${lines[$i]}'+' 
		else
			lines[$i]=${lines[$i]}'-'
		fi	
	done
done


for i in "${!name[@]}"
do
	echo $i '|' ${name[i]}
done

for entry in "${lines[@]}"
do
	echo $entry
done


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

averagewt=$(($waittime / ${#arrivals}))
averagett=$(($turnaround / ${#arrivals}))

echo "Average Waiting Time: $averagewt"
echo "Average Turnaround Time: $averagett"
