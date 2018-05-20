#/!bin/bash

# Bash FCFS Simulation

s=$1
current_time=0
tq=$2


declare -a remaining_time
declare -a arrival_time
declare -a fixed_arrival_time
declare -a completed_at
declare -a processing_time
declare -a name
declare -a out
declare -a lines

# Create array with all the inital processing times of the processes

i=0
for line in `cut $s -d ',' -f3`
do
	processing_time[i]="$line"
	i=$((i+1))
done


# Create array with all the initial arrival times of the processes

i=0
for line in `cut $s -d ',' -f2`
do
	fixed_arrival_time[i]="$line"
	i=$((i+1))
done


# Create array with all the names of the processes

i=0

for line in `cut $s -d ',' -f1`
do
	name[i]="$line"
	i=$((i+1))
done

# Create array with all the remaining times of the processes

i=0

for line in `cut $s -d ',' -f3`
do
	remaining_time[i]="$line"
	i=$((i+1))
done

# Create array with all the arrival times of the processes

i=0

for line in `cut $s -d ',' -f2`
do
	arrival_time[i]="$line"
	i=$((i+1))
done

last=$((${#name[@]} - 1))
while [ true ]
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
	elif [ ${remaining_time[nearest_arrival_index]} -le $tq ]
	then
		current_time=$((current_time + remaining_time[$nearest_arrival_index]))
		for ((i=0 ; i < ${remaining_time[nearest_arrival_index]} ; i++ ))
		do
			out+=($nearest_arrival_index)
		done		
		remaining_time[$nearest_arrival_index]=0
		completed_at[$nearest_arrival_index]=$current_time
	elif [ ${remaining_time[nearest_arrival_index]} -gt $tq ]
	then		
		current_time=$((current_time + tq))
		for ((i=0 ; i < tq ; i++ ))
		do
			out+=($nearest_arrival_index)
		done		
		remaining_time[$nearest_arrival_index]=$((remaining_time[$nearest_arrival_index] - tq))
		arrival_time[$nearest_arrival_index]=$current_time
	fi
done

for i in "${!arrival_time[@]}" 
do
	lines[$i]="$i |"
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

echo

for entry in "${lines[@]}"
do
	echo $entry
done

echo

total_tat=0
total_wt=0
for i in "${!name[@]}"
do
	echo ${name[i]}
	tat=$((${completed_at[$i]} - ${fixed_arrival_time[$i]} ))
	wt=$(($tat - ${processing_time[$i]}))	
	echo 'Turnaround Time: '$tat
	total_tat=$(( tat + total_tat ))
	total_wt=$(( total_wt + wt ))
	echo 'Waiting Time: '$wt
	echo '----------'
	
	if [ $i -eq $last ]
	then
		echo 'Average WT '$(( $total_wt / ${#name[@]} ))
		echo 'Average TAT '$(( $total_tatt / ${#name[@]} ))
	fi
done
