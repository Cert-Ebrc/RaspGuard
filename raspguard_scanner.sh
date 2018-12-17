#!/bin/bash

#pull config settings
. /home/raspguard/RaspGuard/raspguard.config

while true
do
	sleep 2
	#if we detect a new usb key
	if [[ $(ls -l /media/raspguard | wc -l) -gt 1 ]]; then
		for usbstick in /media/raspguard/*
		do
			#ask for the company name using a popop
			if companyname=$(zenity --entry --title "company" --text "What is the company name of the Provider?" --display=:0.0); then
				yes | zenity --progress --pulsate --display=:0.0 &
				zpid=$!
				clamscan -r $usbstick/ > /home/raspguard/log
				kill $zpid
				#Look for infected word in the clamav output which means the usbkey is infected
				if [[ $(grep "Infected" /home/raspguard/log | grep -oE '[[:digit:]]') -gt 0 ]]; then
				        zenity --warning --text="!!!ALERT!!! The USB Stick is Infected !!!ALERT!!! Please Contact the CCC (555)" --display=:0.0 &
					#text manipulation for the infected email
					echo "Provider name:"$companyname > /home/raspguard/infectedlog
                                        echo "\n" >> /home/raspguard/infectedlog
                                        echo "Scanned by:" >> /home/raspguard/infectedlog
					echo $scanneranme >> /home/raspguard/infectedlog
                                        echo -e "\n" >> /home/raspguard/infectedlog
					grep "FOUND" /home/raspguard/log >> /home/raspguard/infectedlog
					#Send to all the mails in the raspguard-email-alert file
					while read  EmailAlert; do
						swaks --to $EmailAlert --from "Raspguard@cert.lu" --server $EmailGateway --header "Subject: Please create a security incident" --body /home/raspguard/infectedlog
					done < /home/raspguard/RaspGuard/raspguard-email-alert
				else
        				zenity --info --text="The USB Stick is Clean" --display=:0.0 &
				fi
				umount $usbstick
				#Text manipulation for clean email
                                echo "Provider name:"$companyname > /home/raspguard/cleanlog
                                echo "\n" >> /home/raspguard/cleanlog
                                echo "Scanned by:" >> /home/raspguard/cleanlog
				echo $scannername >> /home/raspguard/cleanlog
                                echo -e "\n" >> /home/raspguard/cleanlog
                                cat /home/raspguard/log | tail -n 10 >> /home/raspguard/cleanlog
                                echo -e "\n" >> /home/raspguard/cleanlog
				#Add information for  db update and the status of the service
                                echo -e "-----SCAN-DEFINITIONS-----" >> /home/raspguard/cleanlog
                                systemctl status clamav-freshclam.service >> /home/raspguard/cleanlog
				#Send to all the mails in raspguard-email-info
				while read Email; do
					swaks --to $Email --from "Raspguard@cert.lu" --server $EmailGateway --header "Subject:Provider: $companyname" --body /home/raspguard/cleanlog
				done < /home/raspguard/RaspGuard/raspguard-email-info
			fi
		done
	fi
done
