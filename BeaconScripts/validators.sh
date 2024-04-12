#!/bin/bash

start_time=$(date +%s%3N)

read -p "Enter starting slot : " start
read -p "Enter ending slot : " end

filename="validators$start-$end.json"

echo '{' > $filename
for ((slot = $start; slot <= $end; slot++)); do
	validator_data=$(curl -s http://localhost:3500/eth/v2/beacon/blocks/$slot | jq -r '.data.message.state_root'| xargs -I {} curl -s http://localhost:3500/eth/v1/beacon/states/'{}'/validators | jq)
	
	if [ $? -ne 0 ]; then
		echo "Slot $slot skipped!"
	else
		if [ $slot -gt $start ]; then
  			echo "," >> $filename
  		fi
  
		echo '"'$slot'" : ' >> $filename
	
		statuses=$(echo $validator_data | jq -r '.data[].status')
		declare -A status_count

		for status in $statuses; do
			if [[ -n "${status_count[$status]}" ]]; then
    				((status_count[$status]++))
  			else
    				status_count[$status]=1
  			fi
		done

		status_dict="{"
		for key in "${!status_count[@]}"; do
  			status_dict+="\"$key\": ${status_count[$key]}, "
		done
		status_dict="${status_dict%, }"  # Remove the trailing comma and space
		status_dict+="}"
		echo $status_dict >> $filename

		echo "Slot $slot processed successfully."
	fi
done
echo '}' >> $filename
end_time=$(date +%s%3N)
duration=$((end_time - start_time))
total_slots=$((end - start + 1))

log='{"filename": "'"$filename"'", "start_time": "'"$start_time"'", "end_time" : "'"end_time"'", "total_slots": "'"$total_slots"'", "total_expoprt_time": "'"$duration"'", "avg_export_time": "'"$((duration/total_slots))"'"}'

echo 'Processing completed successfully'

echo $log >> log.json
echo -e "\n" >> log.json
