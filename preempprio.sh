#!/bin/bash
declare -a master

filename="$1"
linecount=`wc -l $filename | awk '{ print $1 }'`
iloop=0
while read -r line
do
    name="$line"
    #echo "Name read from file - $name"
    master[$iloop]=$line
    iloop=$(($iloop+1))
    #echo $iloop
done < "$filename"

declare -a name
declare -a arrival
declare -a burst
declare -a originalBurst
declare -a prio
declare -a active
declare -a waitTime
declare -a turnaroundTime

declare -a outArray
declare -a lineArray

floop=0
for processnum in $(seq 0 $(($linecount-1)))
do
  name[$floop]=`echo ${master[processnum]} | cut -d',' -f 1`
  arrival[$floop]=`echo ${master[processnum]} | cut -d',' -f 2`
  burst[$floop]=`echo ${master[processnum]} | cut -d',' -f 3`
  originalBurst[$floop]=`echo ${master[processnum]} | cut -d',' -f 3`
  prio[$floop]=`echo ${master[processnum]} | cut -d',' -f 4`
  active[$floop]=0
  waitTime[$floop]=0
  floop=$(($floop+1))
done

#currentJobIndex=-1
currentTime=0
finish=0

while [ $finish -eq 0 ]
do
  #echo "Current Time is $currentTime ms"

  #PRINT OUT [PROCESS NAME, BURST TIME]
  #indexTracker=0
  #for n in $(seq 0 $(($linecount-1)))
  #do
  #  outArray[$indexTracker]="[${name[$indexTracker]}, ${burst[$indexTracker]}]"
  #  echo ${outArray[$indexTracker]}
  #  indexTracker=$(($indexTracker+1))
  #done
  #echo "Current Process is $currentJobIndex ms"
  #ARRIVAL CHECKER
  indexTracker=0
  for n in $(seq 0 $(($linecount-1)))
  do
    if [ ${arrival[$indexTracker]} -eq $currentTime ] && [ ${active[$indexTracker]} -eq 0 ]
    then
      active[$indexTracker]=1
      #echo "${name[$indexTracker]} is active"
    fi
    indexTracker=$(($indexTracker+1))
  done

  #Assign current process based on lowest priority

  indexTracker=0
  curPrioIndex=0
  for n in $(seq 0 $(($linecount-1)))
  do
    if [ ${burst[$indexTracker]} -gt 0 ] && [ ${active[$indexTracker]} -eq 1 ]
    then
      ((${prio[$indexTracker]} < ${prio[$curPrioIndex]})) && curPrioIndex=$indexTracker
    fi
    indexTracker=$(($indexTracker+1))
  done
  #HAHA easy way out of this mess
  if [ ${active[$curPrioIndex]} -ne 1 ]
  then
    curPrioIndex=-1
  fi


  #waitTime increment
  indexTracker=0
  for n in $(seq 0 $(($linecount-1)))
  do
    if [ ${burst[$indexTracker]} -gt 0 ] && [ ${active[$indexTracker]} -eq 1 ] && [ $indexTracker -ne $curPrioIndex ]
    then
      waitTime[$indexTracker]=$((${waitTime[$indexTracker]}+1))
    fi
    indexTracker=$(($indexTracker+1))
  done

  #Modify GANTT CHART based on selected process
  indexTracker=0
  for n in $(seq 0 $(($linecount-1)))
  do
    if [ $indexTracker -eq $curPrioIndex ]
    then
      lineArray[$indexTracker]=${lineArray[$indexTracker]}"+"
    else
      lineArray[$indexTracker]=${lineArray[$indexTracker]}"-"
    fi
    indexTracker=$(($indexTracker+1))
  done

  #Decrement burst time of current process

  if [ ${burst[$curPrioIndex]} -gt 0 ] && [ $curPrioIndex -ne -1 ]
  then
    #echo "${name[$curPrioIndex]} is the current Job with ${burst[$curPrioIndex]}ms left!"
    burst[$curPrioIndex]=$((${burst[$curPrioIndex]}-1))
  fi
  if [ ${burst[$curPrioIndex]} -eq 0 ]
  then
    #echo "${name[$curPrioIndex]} is done!"
    active[$curPrioIndex]=2
    curPrioIndex=-1
  fi


  #end the loop
  remainingJobTime=0
  indexTracker=0
  for n in $(seq 0 $(($linecount-1)))
  do
    remainingJobTime=$(($remainingJobTime+${burst[$indexTracker]}))
    indexTracker=$(($indexTracker+1))
  done

  if [ $remainingJobTime -eq 0 ]
  then
   finish=1
  fi

  currentTime=$(($currentTime+1))
done

echo -e "PROCESS\tWAIT\tTURNAROUND"
indexTracker=0
for n in $(seq 0 $(($linecount-1)))
do
  turnaroundTime[$indexTracker]=$((${waitTime[$indexTracker]}+${originalBurst[$indexTracker]}))
  echo -e "${name[$indexTracker]}\t${waitTime[$indexTracker]}\t${turnaroundTime[$indexTracker]}"
  indexTracker=$(($indexTracker+1))
done
totalWaitTime=0
totalTurnaroundTime=0
indexTracker=0
for n in $(seq 0 $(($linecount-1)))
do
  totalWaitTime=$(($totalWaitTime+${waitTime[$indexTracker]}))
  totalTurnaroundTime=$(($totalTurnaroundTime+${turnaroundTime[$indexTracker]}))
  indexTracker=$(($indexTracker+1))
done

indexTracker=0
for n in $(seq 0 $(($linecount-1)))
do
  echo "$indexTracker | ${name[$indexTracker]}"
  indexTracker=$(($indexTracker+1))
done

indexTracker=0
for n in $(seq 0 $(($linecount-1)))
do
  echo ${lineArray[$indexTracker]}
  indexTracker=$(($indexTracker+1))
done

echo "AVG WAIT TIME: $(awk "BEGIN {printf \"%.2f\",$totalWaitTime/$linecount}") "
echo "AVG TURNAROUND TIME: $(awk "BEGIN {printf \"%.2f\",$totalTurnaroundTime/$linecount}")"
