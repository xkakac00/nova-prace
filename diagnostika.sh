#!/bin/bash 
date=$(date +%Y-%m-%d-%M-%H)
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

function is_root(){
	user=$(whoami)
	if [ "$user" == "root" ];then
		main_flow
	else
		echo -e "${RED}To use this script, you must be superuser root.${NC}"
		exit 1
	fi
}

function disk_space(){
	echo "Check free disk space"
	echo "================================"
	df -h | awk 'NR>1 {print $5 " " $1}' | while read line;do
		partition=$(echo "$line" | awk '{print $2}')
		# % pres sed nahranim mezerou
		used=$(echo "$line" | awk '{print $1}' | sed 's/%//')
		
		if [ "$used" -ge 80 ];then
			echo -e "${RED}Warning: partition $partition has less than 20% free space.(Usage:$used%)${NC}"
		else
			echo -e "${GREEN}Disk partition $partition is within safe limits. (Usage: $used%)${NC}" 
		fi
	done 
	echo "================================"
}
function memory(){
	total_memory=$(free -h | grep -i "mem:" | awk '{print $2}')
	used_memory=$(free -h | grep -i "mem:" | awk '{print $3}')
	free_memory=$(free -h | grep -i "mem:" | awk '{print $4}')
	shared_memory=$(free -h | grep -i "mem:" | awk '{print $5}')
	buffer_memory=$(free -h | grep -i "mem:" | awk '{print $6}')
	available_memory=$(free -h | grep -i "mem:" | awk '{print $7}')
	echo "Memory diagnostics"
	echo "================================"
	echo "Total memory size is: $total_memory"
	echo "Used memory size is: $used_memory"
	echo "Free memory size is: $free_memory"
	echo "Shared memory size is: $shared_memory"
	echo "Buffer memory size is: $buffer_memory"	
	echo "Available memory size is: $available_memory"
	echo "================================"
	
	echo "List the top 5 processes with the highest memory:";ps aux --sort=-%mem | head -n5 | awk '{print $4 " " $11}'
	
}
function network_interface(){
	echo "Current network status and ip addresses"
	ifconfig
	echo "Connectivity testing with an external server (napr:8.8.8.8)"
	ping -c4 8.8.8.8
}

function kernel_dist(){
	dist=$(cat /etc/os-release)
	kernel_ver=$(uname -r)
	echo "OS distribution information:$dist"
	echo "Kernel version:$kernel_ver"
}

function system_update(){
	echo  "Check for updates..."
	apt-get update
	if [ "$?" -eq 0 ];then
		echo -e "${GREEN}The package list updated successfully...${NC}"
		apt-get upgrade
		if [ "$?" -eq 0 ];then
			echo -e "${GREEN}The packages have been updated.${NC}"
		else
			echo -e "${RED}Warning: The operation ended with an unexpected error.${NC}"
		fi
	else
		echo -e "${RED}Warning: The operation ended with an unexpected error.${NC}"	
	fi	
}


function generate_report(){
	echo "Generating a report..."
	report_file="system-$date.log"
	disk_space | tee -a "$report_file"
	memory | tee -a "$report_file"
	network_interface | tee -a "$report_file"
	kernel_dist | tee -a "$report_file"
	system_update | tee -a "$report_file"
}




function main_flow(){
	echo "1) Check available disk space."
	echo "2) Memory diagnostics."
	echo "3) Check state network interface."
	echo "4) Check the kernel version and distribution"
	echo "5) System update."
	echo "6) Generating a report"
	read choice
	
	case "$choice" in
		1)
			disk_space		
		;;
		2)
			memory
		;;
		3)
			network_interface			
		;;
		4)
			kernel_dist
		;;
		5)
			system_update			
		;;
		6)
			generate_report
		;;
		*)
			echo -e "${RED}Invalid option, run diagnostics again.${NC}"
			exit 1
		;;
	esac
}

is_root
