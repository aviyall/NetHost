#!/bin/bash

trap 'cleanup; exiting; exit 1' SIGINT SIGTERM

red="\033[0;31m"
green="\033[0;32m"
yellow="\033[0;33m"
light_green="\033[38;5;50m"
reset="\033[0m"

cleanup() {
    printf "${yellow}Cleaning up processes...${reset}\n"
    kill "$req_pid" 2>/dev/null
    kill "$tcp_pid" 2>/dev/null
    kill "$ssh_pid" 2>/dev/null
    sleep 1
    kill $(pgrep -t $(tty | sed 's/\/dev\///') ssh) 2>/dev/null
}

exiting() {
    kill "$timer_pid" 2>/dev/null
    kill "$mon_serveo_pid" 2>/dev/null
    printf "${yellow}EXITING...${reset}\n"
}

#function to monitor serveo status
serveo_stat(){
    curl -sf -I --connect-timeout 5 "https://serveo.net" &>/dev/null || \
    curl -sf -I --connect-timeout 5 "https://serveo.net" &>/dev/null || \
    curl -sf -I --connect-timeout 5 "https://serveo.net" &>/dev/null
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

httptunnel() {
    local remote_port=80
    local subdomain="$4"
    local temp_file; temp_file=$(mktemp /tmp/tempfileXXXXXX.txt)

    if [[ -z "$subdomain" ]]; then
        printf "${green}Establishing HTTP tunnel with random subdomain...${reset}\n"
        ssh -nT -R "$remote_port:$host:$3" serveo.net | stdbuf -oL awk 'NR==1 {print $5}' > "$temp_file" &
        tunnel_pid=$!
    else
        printf "${green}Checking availability of subdomain '$subdomain'...${reset}\n"
        if wget -q --spider "https://$subdomain.serveo.net"; then
            printf "${red}Subdomain '$subdomain' is not available. Exiting.${reset}\n"
            rm "$temp_file"
            exit 1
        fi

        printf "${green}Establishing HTTP tunnel with subdomain '$subdomain'...${reset}\n"
        ssh -nT -R "$subdomain:$remote_port:$host:$3" serveo.net | stdbuf -oL awk 'NR==1 {print $5}' > "$temp_file" &
        tunnel_pid=$!
    fi

    while true; do
        if [[ -n "$link" ]]; then
            printf "${green}HTTP tunnel established: ${light_green}$link${reset}\n"
            url=$link
            link=""
            break
        else
            link=$(<"$temp_file")
        fi
        sleep 1
    done
    sleep 2

    rm "$temp_file"

    keepalive "$url" &
    req_pid=$!
}

tcptunnel() {
    local remote_port="${4:-0}"

    if [[ "$remote_port" -ne 0 ]] && ncat -zv serveo.net "$remote_port" &>/dev/null; then
        printf "${red}Remote port $remote_port is in use. Exiting.${reset}\n"
        exit 1
    fi

    printf "${green}Establishing TCP tunnel on port $remote_port...${reset}\n"
    ssh -nT -R "$remote_port:$host:$3" serveo.net &
    tcp_pid=$!

    sleep 5

    if ! ps -p $tcp_pid &>/dev/null; then
        printf "${red}Failed to establish TCP tunnel. Exiting.${reset}\n"
        exit 1
    fi

    printf "${green}TCP tunnel established successfully.${reset}\n"
}

sshtunnel() {
    if [[ "$3" -ne 22 ]]; then
        printf "${red}Local port '$3' is not allowed TRY with '22'. Exiting...${reset}\n"
        exit 1
    fi
    
    if [[ "$4" -eq 0 ]]; then
        printf "${red}Public hostname alias not specified. Exiting...${reset}\n"
        exit 1
    fi
    printf "${green}Establishing SSH tunnel...${reset}\n"
    ssh -T -R "$4:22:$host:22" serveo.net &
    ssh_pid=$!

    sleep 5

    if ! ps -p $ssh_pid &>/dev/null; then
        printf "${red}Failed to establish SSH tunnel. Exiting.${reset}\n"
        exit 1
    fi

    printf "${green}SSH tunnel established successfully.${reset}\n"
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

#a timer function to keep track of time
timer() {
    counter=0
    while true; do
        counter=$((counter + 5))
        sleep 5
        echo "$counter" > /tmp/counter_value
    done
}
 
moniter_serveo(){
    while true; do
        if ! serveo_stat; then 
            serveo_status=1
            sleep 5
        else
            serveo_status=0
        fi
    done
}

#function to check network connection and serveo status and restart tunnel accordingly
check_connection(){
    timer &
    timer_pid=$!

    while true; do
        if [[ "$serveo_status" -eq 1 ]]; then
            printf "${yellow}Serveo is down. Waiting to get back ${reset}\n"
            cleanup
            until [[ "$serveo_status" -eq 0 ]]; do
                sleep 5
            done
            printf "${yellow}Serveo is up. Restarting tunnel...${reset}\n"
            restart_tunnel "$@"
        fi

        if ! check_network; then
            printf "${yellow}Internet connection lost. Waiting for internet connection...${reset}\n"
            
            cleanup
            #kill moniterserveo
            kill "$mon_serveo_pid"
            time1=$(cat /tmp/counter_value 2>/dev/null)
            until check_network; do
                sleep 10
            done
            time2=$(cat /tmp/counter_value 2>/dev/null)
            down_time=$(( (time2 - time1) ))
            waiting_sec=$(( $1 - down_time ))
            min=$(( waiting_sec / 60))
            sec=$(( waiting_sec % 60))
            moniter_serveo &
            mon_serveo_pid=$!
            printf "${green}Internet connection restored. Checking Serveo status...${reset}\n"
            ## check if serveo is up
            if [[ "$serveo_status" -eq 1 ]]; then
                echo -e "\n"
                printf "${yellow}Serveo is down. Waiting to come back up...${reset}\n"
                
                time3=$(cat /tmp/counter_value 2>/dev/null)
                until [[ serveo_status -eq 0 ]]; do
                    sleep 10
                done
                printf "${green}Serveo is back UP.${reset}\n"
                time4=$(cat /tmp/counter_value 2>/dev/null)
                serveo_down_time=$(( (time4 - time3) ))
                if [[ "$serveo_down_time" -gt "$waiting_sec" ]]; then
                    :
                else
                    final_waiting_time=$(( (waiting_sec - serveo_down_time) ))
                    if [[ "$final_waiting_time" -gt 0 ]]; then
                        sleep "$final_waiting_time"
                    fi
                fi

            fi
            
            if [[ "$waiting_sec" -gt 0 ]]; then
                echo -e "\n"
                printf "${yellow}Reconencting...Please wait $min minutes and $sec seconds${reset}\n"
                sleep $waiting_sec
            else
                printf "${green}Restarting tunnel...${reset}\n"
            fi
            restart_tunnel "$@"
        
        fi

        #if tunnel process is stopped unexpectedly then restart tunnel
        if  { [[ "$opt" -eq 1 ]] && ! ps -p "$tunnel_pid" &>/dev/null; } || \
            { [[ "$opt" -eq 2 ]] && ! ps -p "$tcp_pid" &>/dev/null; } || \
            { [[ "$opt" -eq 3 ]] && ! ps -p "$ssh_pid" &>/dev/null; }; then
            printf "${yellow}Tunnel process has stopped unexpectedly. Restarting...${reset}\n"
            cleanup
            sleep 5
            restart_tunnel "$@"
        fi 
        
        sleep 5
    done

}
# function to monitor each tunnel case
monitor_tunnels() {
    if [[ "$opt" -eq 1 && -n "$4" ]]; then

        check_connection 600

    elif [[ "$opt" -eq 1 && -z "$4" ]]; then
        
        check_connection 0

    elif [[ "$opt" -eq 2 ]]; then

        check_connection 120

    elif [[ "$opt" -eq 3 ]]; then

        check_connection 120

    fi


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

    if [[ -z $1 ]]; then
        printf "${red}Protocol not specified. Exiting.${reset}\n"
        exit 1
    fi
    # Check if hostname is specified
    if [[ "$2" == "lh" ]]; then
        host="localhost"
    elif [[ -z $2 ]]; then
        printf "${red}Hostname not specified. Exiting.${reset}\n"
        exit 1
    else
        host="$2"
    fi
    # condition for each case
    case "$1" in
        http)
            opt=1
            [[ -z "$3" ]] && { printf "${red}Local port not specified. Exiting.${reset}\n"; exit 1; }
            httptunnel "$@"
            ;;
        tcp)
            opt=2
            [[ -z "$3" ]] && { printf "${red}Local port not specified. Exiting.${reset}\n"; exit 1; }
            tcptunnel "$@"
            ;;
        ssh)
            opt=3
            [[ -z "$3" ]] && { printf "${red}SSH port '22' not specified. Exiting.${reset}\n"; exit 1; }
            sshtunnel "$@"
            ;;
        *)
            printf "${red}Invalid protocol specified. Exiting.${reset}\n"
            exit 1
            ;;
    esac

    moniter_serveo &
    mon_serveo_pid=$!

    monitor_tunnels "$@"
}

main "$@"