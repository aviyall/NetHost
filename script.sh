#!/bin/bash

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
reset="\033[0m"

network() {
    wget -q --spider google.com
    return $?
}

serveo_stat() {
    wget -q --spider serveo.net
    return $?
}

send_req() {
    local url="$1"
    if [ -n "$url" ]; then
        while true; do
            wget -q --spider "$url"
            sleep 120
        done
    fi
}

http() {
    remote_port=80
    temp_file=$(mktemp)

    if [ -z "$4" ]; then
        echo -e "${green}Establishing SSH tunnel...${reset}"
        echo "Forwarding HTTP traffic with a randomly assigned subdomain..."
        ssh -nT -R "$remote_port:$hostname:$3" serveo.net | tee "$temp_file" | awk 'NR==1 {print $5}'
    else
        wget -q --spider "$4.serveo.net"
        if [ $? -eq 0 ]; then
            echo -e "${red}The requested subdomain '$4' is not available. Please choose a different subdomain.${reset}"
            exit 1
        else
            echo -e "${green}Establishing SSH tunnel...${reset}"
            echo "Forwarding HTTP traffic with subdomain '$4'..."
            ssh -nT -R "$4.serveo.net:$remote_port:$hostname:$3" serveo.net | tee "$temp_file" | awk 'NR==1 {print $5}'
        fi
    fi

    sleep 1
    link=$(<"$temp_file")
    rm "$temp_file"
}
  
tcp() {
    if [ -z "$4" ]; then
        echo "No remote port specified. A random remote port will be chosen."
        remote_port=0
    else
        echo "Checking availability of the specified remote port..."
        ncat -zv serveo.net "$4" &> /dev/null
        if [ $? -eq 0 ]; then
            echo -e "${red}The specified remote port number is currently in use. Please select a different port number.${reset}"
            exit 1
        else
            remote_port="$4"
            echo "The specified remote port number is available."
        fi
    fi

    echo -e "${green}Establishing SSH tunnel...${reset}"
    ssh -nT -R "$remote_port:$hostname:$3" serveo.net
    sleep 2
}

ssh_opt() {
    ssh -T -R "$3:22:$hostname:22" serveo.net
}

while true; do
    if ! network; then
        echo -e "${red}Internet connection not detected. Exiting the script...${reset}"
        exit 1
    fi

    if [ "$1" == "http" ]; then
        if [ "$2" == "lh" ] || [ "$2" == "local" ]; then
            echo "Setting hostname to 'localhost'."
            hostname=localhost
        elif [ -z "$2" ]; then
            echo -e "${red}Hostname not specified. Exiting the script...${reset}"
            exit 1 
        else
            echo "Setting hostname to '$2'."
            hostname=$2
        fi

        if [ -z "$3" ]; then
            echo -e "${red}Local port not specified. Exiting the script...${reset}"
            exit 1
        fi
        http "$@" & 
        http_pid=$!
        opt=1 
        
    elif [ "$1" == "tcp" ]; then 
        if [ "$2" == "lh" ] || [ "$2" == "local" ]; then
            echo "Setting hostname to 'localhost'."
            hostname=localhost
        elif [ -z "$2" ]; then
            echo -e "${red}Hostname not specified. Exiting the script...${reset}"
            exit 1 
        else
            echo "Setting hostname to '$2'."
            hostname=$2
        fi

        if [ -z "$3" ]; then
            echo -e "${red}Local port not specified. Exiting the script...${reset}"
            exit 1
        fi
        tcp "$@" & 
        tcp_pid=$!
        opt=2
        
    elif [ "$1" == "ssh" ]; then
        if [ -z "$2" ]; then
            echo -e "${red}Hostname not specified. Exiting the script...${reset}"
            exit 1
        elif [ "$2" == "lh" ] || [ "$2" == "local" ]; then
            echo "Setting hostname to 'localhost'."
            hostname=localhost
        else
            echo "Setting hostname to '$2'."
            hostname=$2
        fi
        if [ -z "$3" ]; then
            echo -e "${red}Public hostname alias not specified. Please provide it as the third positional parameter.${reset}"
            exit 1
        fi
        ssh_opt "$@" & 
        ssh_pid=$!
        opt=3
        
    else 
        echo -e "${red}Invalid protocol specified. Exiting the script...${reset}"
        exit 1
    fi

    send_req "$link" &

    if [ $opt -eq 1 ]; then
        pid=$http_pid
    elif [ $opt -eq 2 ]; then
        pid=$tcp_pid
    else
        pid=$ssh_pid
    fi

    while ps -p "$pid" > /dev/null ; do
        if ! serveo_stat; then
            kill "$pid"
            echo -e "${yellow}Serveo is currently down.${reset}"
            echo -e "${yellow}Waiting for Serveo to recover...${reset}"

            until serveo_stat; do
                sleep 2
            done

            echo -e "${green}Serveo is back up. Restarting SSH tunnels...${reset}"
            break
        fi

        if ! network; then
            kill "$pid"
            echo -e "${yellow}Lost internet connection. Terminating processes...${reset}"
            echo -e "${yellow}Waiting for internet connection to be restored...${reset}"

            until network; do
                sleep 2
            done
            echo -e "${green}Internet connection restored. Restarting SSH tunnels...${reset}"
            break
        fi
    done
    
    wait 
done
