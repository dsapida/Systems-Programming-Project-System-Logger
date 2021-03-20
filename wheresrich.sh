#!/bin/bash

#Programmers: David Sapida and Andre Stillo	

#References/Sources Used: (NOTE: These will be mentioned again in their respective applications in this script)
#https://stackoverflow.com/questions/43736041/bash-script-check-if-user-is-logged-in-or-not
#https://stackoverflow.com/questions/8903239/how-to-calculate-time-elapsed-in-bash-script
#https://unix.stackexchange.com/questions/374990/how-do-i-add-line-numbers-to-text
#https://www.shellhacks.com/linux-ps-command-get-process-start-time-date/

TARGET="myersr"
TARGET_STATUS=1
# TARGET = target user being monitored. Mostly leftover from debugging and testing on users other than Rich.
# TARGET_STATUS = Binary indicator of the targets online status. 1 = online, 0 = offline

clear
echo $(date): Shell Script has started... >> log.txt
# NOTE: There is a slight difference in this line of code during the execution of the log on Andre Stillo's side.
# During the execution of the code and the recording of the log file, Andre Stillo's version of the code was missing the ":" after the date.
# The programs were functionally the same, this just was not noticed during execution. The final version of the code reflects the colon being present.


# NOTE: Crediting this source for this section of code regarding look function created.
# https://stackoverflow.com/questions/43736041/bash-script-check-if-user-is-logged-in-or-not
# This portion of the program takes each unique user from the list of users outputted by the "who" command
# And returns either 0 or 1 depending if the unique user matches with the target user which is a variable initialized above.

function look {
	for user in $(who | awk '{print $1}' | sort | uniq)
        do
            if [ "$user" == "$TARGET" ]; then
                    return 0
            fi
        done
	return 1
}

# NOTE: Crediting the method of using ps -eo in getProcesses to this link here, this allowed us to get the process listing but with a more detailed date output.
# https://www.shellhacks.com/linux-ps-command-get-process-start-time-date/
# This function is responsible for getting the process list via the usage of ps but instead ef, we use -eo, based on the manual page on ps
# -o allows us to mimic the effects of awk in which we can select the specific output based on column name in this case we used user, lstart (which gets the specific date/time) and
# cmd being the process name at the end. 

# Also NOTE: That the last awk statment in getProcesses was heavily influenced by the following source
# https://unix.stackexchange.com/questions/374990/how-do-i-add-line-numbers-to-text
# This allowed us to format the output of the process such that we only output the date of the process and the process name
# Since our original output outputs the user then the date then the process name, but the user information is considered "extraneous" information, hence we only want the
# date of the process started and the process name/command in the log file.

function getProcesses {
	ps -eo user,lstart,cmd | grep -v root | grep -v grep | awk '$1 == "myersr" {print $0}' | awk '{for (i=2; i<NF; i++) printf $i " "; print $NF}' >> log.txt
}


# This function is the deduping process for our log file, it takes the file we append the process list to, sorts it by the unique (-u) instances and writes it (-o) to a target
# file which in this case is itself, we are overwriting the log file with all the unique instances from it to prevent massive duplicates to be generated. This also allows us to record
# new and old processes that were on the list.

function removeDupes {
	sort -u -o log.txt log.txt
}


# This function is ran when the target user changes their status from Online to Offline, we append a timestamp to the log file and we get the search results in our log file
# for any instances where the target user has touched MSU-SECRETS via their process list in the log. We take that output either 0 or 1, if the result is true (0) that meant the user
# has interacted with the file specified (MSU-SECRETS) and that we will reformat the log file for better presentation, and append all instances the user has interacted with the 
# file specified into a file called proof.txt and terminate the program. If the output is false (1) it will resume to check if the user is online or not.

function search {
	echo $(date): Target went offline >> log.txt
	cat log.txt | grep MSU-SECRETS
	if [ $? -eq 0 ]; then
		echo
		echo $(date): Target has touched the forbidden file! Terminating Shell Script... >> log.txt

		awk '$0 {print "["NR"]\t", $0}' log.txt > temp.txt
		cp temp.txt log.txt
		rm temp.txt
		# Number each line of the log once it is in its final form. This is done after the completion of the log rather than progressively througout in order
		# to prevent potential issues with deduping. Also note that this awk is redirected to temp.txt, which is then redirected back to log, as redirecting the file
		# to itself results in a blank file.

		echo "Recording found in log.txt stating Target has touched the forbidden file and has Logged Off!" >> proof.txt
		echo "Here is Proof: " >> proof.txt
		cat log.txt | grep MSU-SECRETS >> proof.txt
		# Store any lines where the target interacted with MSU-SECRETS in another file called proof.txt. This is done to highlight the lines in the log where the activity
                # took place.

		exit 0
	fi
}

# NOTE: The utilization of SECONDS and duration variables/checks is credited to this source
# https://stackoverflow.com/questions/8903239/how-to-calculate-time-elapsed-in-bash-script
# This is used to do the hourly checks, SECONDS is a reserved variable that increments in seconds the moment a script is started.
# We used this to create hourly checks, based on the minutes in duration so that for ever 60 minutes (or by the hour) if Rich is not online then
# append a timestamp to the log file stating that Rich was not online during that previous hour, once that timestamp is logged, we reset the timer to 0
# The resetting of the timer also happens when the user changes status from online to offline to replicate the previous statement.

SECONDS=0

# This while loop utilizes the look function which checks if target user is online or not, and depending on the output, it will either start doing 1 second checks if the
# target user is online or will do 5 second checks if the user is offline.

while true
do	
	look
	if [ $? -eq 0 ]; then
		if [ $TARGET_STATUS == 1 ]; then #If target was offline and came online.
			TARGET_STATUS=0
			last -F myersr | awk 'FNR==1{print $4 " " $5 " " $6 " " $7 " " $8 " !!!!!TARGET IS ONLINE!!!!!"}' >> log.txt
		fi
		echo
		echo "Target is Logged In..."
		echo
		DATE= date
		echo $DATE
		getProcesses
		removeDupes
		sleep 1
	elif [ $? -eq 1 ]; then
		if [ $TARGET_STATUS == 0 ]; then #If target was online and went offline.
			TARGET_STATUS=1
			SECONDS=0
			echo "Target has gone Offline!"
			echo
			search
		fi
		echo
		echo "Target is Offline..."
		echo
		DATE= date
		echo $DATE
		duration=$SECONDS
		
		# This is the portion where we started to use duration in tandem with SECONDS as mentioned in the comments above.

		if [ $(($duration / 60)) -eq 60 ]; then	
			echo
			echo Hourly Check: Target was not online during the previous hour.
			echo $(date) Target was not online during the previous hour. >> log.txt
			SECONDS=0
		fi		

		sleep 5
	fi
done
