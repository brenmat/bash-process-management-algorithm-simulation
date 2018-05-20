#/!bin/bash

# Bash FCFS Simulation

s=test.csv

declare -a remaining_time
declare -a arrival_time
declare -a completed_at
declare -a name
declare -a out

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

current_time=0

tq=3

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
	elif [ ${remaining_time[nearest_arrival_index]} -lt $tq ]
	then
		current_time=$((current_time + remaining_time[$nearest_arrival_index]))
		for ((i=0 ; i < ${remaining_time[nearest_arrival_index]} ; i++ ))
		do
			out+=($nearest_arrival_index)
		done		
		remaining_time[$nearest_arrival_index]=0
		completed_at[$nearest_arrival_index]=$current_time
	elif [ ${remaining_time[nearest_arrival_index]} -ge $tq ]
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

for output in ${out[@]} 
do
	echo $output
done



