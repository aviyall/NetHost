#!/bin/bash

trap 'cleanup; exit 1' SIGINT SIGTERM

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
light_green="\033[38;5;50m"
reset="\033[0m"

option=""
hostname=""
local_port=""
remote_port=""
subdomain=""
alias=""


show_help() {
    echo "A Bash script to establish HTTP, TCP, and SSH tunnels using Serveo."
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -o,  --option       'http' or 'tcp' or 'ssh' "
    echo "  -h,  --hostname     Specify the hostname"
    echo "  -lp, --local-port   Set the local port number"
    echo "  -rp, --remote-port  Set the remote port number"
    echo "  -s,  --subdomain    Coustom subdomain of http tunnel"
    echo "  -a,  --alias        Assign an alias for ssh"
    echo ""
    echo "  -H,  --help         Show this help message "
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--option) 
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -o|--option requires a value."
                exit 1
            fi
            option="$2"
            shift 2
            ;;
        -h|--hostname)  
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -h|--hostname requires a value."
                exit 1
            fi
            hostname="$2"
            shift 2
            ;;
        -lp|-p|--local-port) 
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -lp|--local-port requires a value."
                exit 1
            fi
            local_port="$2"
            shift 2
            ;;
        -rp|--remote-port) 
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -rp|--remote-port requires a value."
                exit 1
            fi
            remote_port="$2"
            shift 2
            ;;
        -s|--subdomain) 
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -s|--subdomain requires a value."
                exit 1
            fi
            subdomain="$2"
            shift 2
            ;;
        -a|--alias) 
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "Error: -a|--alias requires a value."
                exit 1
            fi
            alias="$2"
            shift 2
            ;;
        -H|--help)  
            show_help
            ;;
        *) 
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

cleanup() {
    kill "$req_pid" 2>/dev/null
    kill "$tunnel_pid" 2>/dev/null
    kill "$tcp_pid" 2>/dev/null
    kill "$ssh_pid" 2>/dev/null
    kill "$timer_pid" 2>/dev/null
    sleep 1
    kill $(pgrep -t $(tty | sed 's/\/dev\///') ssh) 2>/dev/null #just for a final command to ensure all process are killed
}

#function to monitor serveo status
serveo_stat(){
    for i in {1..3}; do
        if curl -sf -I --connect-timeout 5 "https://serveo.net" &>/dev/null; then
            return 0  # Success
        fi
    done
    return 1  # Failure
}
# function to check network connection
check_network() {
    local url="https://www.google.com/generate_204"
    curl -sf -I --connect-timeout 5 "$url" &>/dev/null || \
    curl -sf -I --connect-timeout 5 "$url" &>/dev/null
}
# to keep the http tunnel alive by sending periodic requests
keepalive() {
    local url=$(echo "$1" | tr -d '\n\r' | xargs)
    while true; do
        curl -Is $url | head -n 1 &>/dev/null
        sleep 120
    done
}

reg_sshkey() {
    printf "${yellow}To request a particular subdomain, you first need to register your SSH public key.\n\
To register, visit one of the addresses below to log in with your Google or GitHub account.\n\
After registering, you'll be able to request your subdomain the next time you connect to Serveo.${reset}\n"
    if ls ~/.ssh/id_rsa >/dev/null 2>&1; then

        cd ~/.ssh || exit
        fingerprint=$(ssh-keygen -lf id_rsa | awk '{print $2}')
        encodedFingerprint=$(echo "$fingerprint" | sed \
            -e 's/:/%3A/g' \
            -e 's/\//%2F/g' \
            -e 's/+/%2B/g' \
            -e 's/=/ %3D/g')

        echo ""
        echo "register with google account:   https://serveo.net/verify/google?fp=$encodedFingerprint"
        echo "register with github account:   https://serveo.net/verify/github?fp=$encodedFingerprint"
        
        
        exit 1
    else
        echo ""
        printf "A valid SSH key not found. do you want to create one (yes/no): "
        read input
        if [[ "${input,,}" == "yes" || "${input,,}" == "y" ]]; then
            ssh-keygen -t rsa -b 4096

            cd ~/.ssh || exit
            
            fingerprint=$(ssh-keygen -lf id_rsa | awk '{print $2}')
            encodedFingerprint=$(echo "$fingerprint" | sed \
                -e 's/:/%3A/g' \
                -e 's/\//%2F/g' \
                -e 's/+/%2B/g' \
                -e 's/=/ %3D/g')
            echo ""
            echo ""
            echo "register with google account:   https://serveo.net/verify/google?fp=$encodedFingerprint"
            echo "register with github account:   https://serveo.net/verify/github?fp=$encodedFingerprint"
            
            exit 1
        elif [[ "${input,,}" == "no" || "${input,,}" == "n" ]]; then
            exit 1
        else
            echo Invalid input
            exit 1
        fi
    fi
    

    
    
}

httptunnel() {
    local port=80
    local temp_file; temp_file=$(mktemp /tmp/tempfileXXXXXX.txt)

    if [[ -z "$subdomain" ]]; then
        printf "${green}Establishing HTTP tunnel with random subdomain...${reset}\n"
        ssh -nT -R "$port:$hostname:$local_port" serveo.net | stdbuf -oL awk 'NR==1 {print $5}' > "$temp_file" &
        tunnel_pid=$!
    else
        printf "${green}Checking availability of subdomain '$subdomain'...${reset}\n"
        if wget -q --spider "https://$subdomain.serveo.net"; then
            printf "${red}Subdomain '$subdomain' is not available. Exiting.${reset}\n"
            rm "$temp_file"
            exit 1
        fi

        printf "${green}Establishing HTTP tunnel with subdomain '$subdomain'...${reset}\n"
        ssh -nT -R "$subdomain:$port:$hostname:$local_port" serveo.net | stdbuf -oL awk 'NR==1 {print $5}' > "$temp_file" &
        tunnel_pid=$!
        
    fi

    while true; do    #put this in a loop for a reson. there might be delay in writing
        if [[ -n "$link" ]]; then
            url=$link
            break
        else
            link=$(<"$temp_file")
        fi
    done
    
    if [[ $link == 'subdomain,' ]]; then
        cleanup
        reg_sshkey
        exit 1
    else
        printf "${green}HTTP tunnel established: ${light_green}$link${reset}\n"
    fi
    
    rm "$temp_file"
    keepalive "$url" &
    req_pid=$!
}

tcptunnel() {
    local port="${remote_port:-0}"

    if [[ "$port" -ne 0 ]] && ncat -zv serveo.net "$remote_port" &>/dev/null; then
        printf "${red}Remote port $port is in use. Try again with other port number or keep it '0' to get assigned a random one  Exiting.${reset}\n"
        exit 1
    fi

    printf "${green}Establishing TCP tunnel on random remote port...${reset}\n"
    ssh -nT -R "$port:$hostname:$local_port" serveo.net &
    tcp_pid=$!

    sleep 5

    if ! ps -p $tcp_pid &>/dev/null; then
        printf "${red}Failed to establish TCP tunnel. Exiting.${reset}\n"
        exit 1
    fi

    printf "${green}TCP tunnel established successfully.${reset}\n"
}

sshtunnel() {
    local port=22
    printf "${green}Establishing SSH tunnel...${reset}\n"
    ssh -T -R "$alias:22:$hostname:22" serveo.net &
    ssh_pid=$!

    sleep 5

    if ! ps -p $ssh_pid &>/dev/null; then
        printf "${red}Failed to establish SSH tunnel. Exiting.${reset}\n"
        exit 1
    fi

    printf "${green}SSH tunnel established successfully.${reset}\n"
}

#a timer function to keep track of time
timer() {
    counter=0
    while true; do
        counter=$((counter + 1))
        sleep 1
        echo "$counter" > /tmp/counter_value
    done
}
 
maintain_tunnel(){

    while true; do
        if [[ -z "$killed" ]]; then
            killed=0
        fi

        if [[ -z "$prob_exp" ]]; then
            prob_exp=0
        fi
        if ! check_network ; then
            printf "${red}Network connection lost.${reset}\n"
            printf "${red}Waiting for connection...${reset}\n"
            until check_network ; do
                timer &
                timer_pid=$!
                prob_exp=1
                if [[ $(cat /tmp/counter_value 2>/dev/null) -gt $1 ]] ; then
                    cleanup
                    killed=1
                else
                    killed=0
                fi
                sleep 3
            done       
            if [[ $killed -ne 1 ]]; then
                cleanup
                killed=1
            fi
        fi
        if ! serveo_stat ; then
            printf "${red}Either serveo.net or Network is down${reset}\n"
            prob_exp=1
            if [[ $killed -ne 1 ]]; then
                cleanup
                killed=1
            fi
            until serveo_stat;do
                if ! check_network; then
                    continue 2
                fi 
                sleep 5
            done
        fi
        if [[ $prob_exp -eq 1 ]] ; then    #run if connection prob(serveo or net down) was there
            printf "${green}Connection restroed.${reset}\n"
            printf "${green}Restarting tunnel...${reset}\n"
            restart_tunnel $option $host $local_port $parameter
            prob_exp=0
            killed=0
        fi
    done
    
}

restart_tunnel() {
    case "$opt" in
        1)
            httptunnel "$@"
            ;;
        2)
            tcptunnel "$@"
            ;;
        3)
            sshtunnel "$@"
            ;;
        *)
            printf "${red}Unknown tunnel option during restart. Exiting.${reset}\n"
            exit 1
            ;;
    esac
}

main() {
    # Check if internet connection is available
    
    if ! check_network; then
        printf "${red}No internet connection. Exiting.${reset}\n"
        exit 1
    fi
    # Check if Serveo is up
    if ! serveo_stat; then
        printf "${red}SERVEO IS DOWN. Exiting.${reset}\n"
        exit 1
    fi

    if [[ -z $option ]]; then
        printf "${red}Protocol not specified. Exiting.${reset}\n"
        exit 1
    fi

    # condition for each case
    case "$option" in
        http)
            opt=1
            [[ -z "$local_port" ]] && { printf "${red}-lp | Local port not specified. Exiting.${reset}\n"; exit 1; }
            httptunnel "$@"
            ;;
        tcp)
            opt=2
            [[ -z "$local_port" ]] && { printf "${red}-lp | Local port not specified. Exiting.${reset}\n"; exit 1; }
            tcptunnel "$@"
            ;;
        ssh)
            opt=3
            [[ -z "$alias" ]] && { printf "${red}-a | Public hostname alias not specified. Exiting.${reset}\n"; exit 1; }
            sshtunnel "$@"
            ;;
        *)
            printf "${red}Invalid protocol specified. use --help for more info ${reset}\n"
            exit 1
            ;;
    esac


    maintain_tunnel 600
}

main "$@"