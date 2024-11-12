#!/bin/bash
trap 'kill ${tunnel_pid:-} ${http_pid:-} ${tcp_pid:-} ${ssh_pid:-} ${req_pid:-} 2>/dev/null; exit' SIGINT SIGTERM

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
reset="\033[0m"

network() {
    ping -c 4 -W 1 google.com > /dev/null 2>&1
    return $?
}


serveo_status() {
    wget -q --spider https://serveo.net/
    return $?
}

send_req() {
    while true; do
        url=$(echo "$1" | tr -d '\n\r' | xargs)
        wget -q --spider $url
        echo "Request sent"
        sleep 120
    done
}


http() {
    remote_port=80
    temp_file=$(mktemp /tmp/tempfileXXXXXX.txt)

    if [ -z "$4" ]; then
        echo -e "${green}Establishing SSH tunnel...${reset}"
        echo "Forwarding HTTP traffic with a randomly assigned subdomain..."
        ssh -nT -R "$remote_port:$host:$3" serveo.net | stdbuf -oL awk 'NR==1 {print $5}' | tee "$temp_file" &
        tunnel_pid=$!
    else
        wget -q --spider "$4.serveo.net"
        if [ $? -eq 0 ]; then
            echo -e "${red}The requested subdomain '$4' is not available. Please choose a different subdomain.${reset}"
            exit 1
        else
            echo -e "${green}Establishing SSH tunnel...${reset}"
            echo "Forwarding HTTP traffic with subdomain '$4'..."
            ssh -nT -R "$4.serveo.net:$remote_port:$host:$3" serveo.net | stdbuf -oL awk 'NR==1 {print $5}' | tee "$temp_file" &
            tunnel_pid=$!
        fi
    fi
    sleep 30
    link=$(<"$temp_file")
    send_req "$link" &
    req_pid=$!
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
    ssh -nT -R "$remote_port:$host:$3" serveo.net
    sleep 2
}

ssh_opt() {
    ssh -T -R "$3:22:$host:22" serveo.net
}

while true; do
    if ! network; then
        echo -e "${red}Internet connection not detected. Exiting the script...${reset}"
        exit 1
    fi

    if [ "$1" == "http" ]; then
        if [ "$2" == "lh" ] || [ "$2" == "local" ]; then
            echo "Setting host to 'localhost'."
            host=localhost
        elif [ -z "$2" ]; then
            echo -e "${red}Host not specified. Exiting the script...${reset}"
            exit 1
        else
            echo "Setting host to '$2'."
            host=$2
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
            echo "Setting host to 'localhost'."
            host=localhost
        elif [ -z "$2" ]; then
            echo -e "${red}Host not specified. Exiting the script...${reset}"
            exit 1
        else
            echo "Setting host to '$2'."
            host=$2
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
            echo -e "${red}Host not specified. Exiting the script...${reset}"
            exit 1
        elif [ "$2" == "lh" ] || [ "$2" == "local" ]; then
            echo "Setting host to 'localhost'."
            host=localhost
        else
            echo "Setting host to '$2'."
            host=$2
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

    if [ $opt -eq 1 ]; then
        pid=$http_pid
    elif [ $opt -eq 2 ]; then
        pid=$tcp_pid
    else
        pid=$ssh_pid
    fi

    while true ; do
        if ! network; then
            [ "$opt" -eq 1 ] && kill $tunnel_pid
            kill $pid
            [ "$opt" -eq 1 ] && kill $req_pid
            echo -e "${yellow}Lost internet connection. Terminating processes...${reset}"
            echo -e "${yellow}Waiting for internet connection to be restored...${reset}"

            until network; do
                sleep 2
            done
            echo -e "${green}Internet connection restored. Restarting SSH tunnels...${reset}"
            break
        elif ! serveo_status; then
            [ "$opt" -eq 1 ] && kill $tunnel_pid
            kill $pid
            [ "$opt" -eq 1 ] && kill $req_pid
            echo -e "${yellow}Serveo is currently down.${reset}"
            echo -e "${yellow}Waiting for Serveo to recover...${reset}"

            until serveo_status; do
                sleep 2
            done

            echo -e "${green}Serveo is back up. Restarting SSH tunnels...${reset}"
            break

        fi
        sleep 10
    done
    continue
done
