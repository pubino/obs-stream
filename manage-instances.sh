#!/bin/bash

# OBS Instance Management Script
# Usage: ./manage-instances.sh [command] [instances...] [--open]
#
# Features:
# - Start/stop/restart individual or all instances
# - Monitor status and resource usage
# - View logs for troubleshooting
# - Automatically open browsers to NoVNC interfaces
# - Cross-platform browser opening (macOS, Linux, Windows)

COMMAND=${1:-status}
shift
INSTANCES=("$@")

# Get number of running instances
get_running_instances() {
    docker ps --filter "name=obs-instance-" --format "{{.Names}}" | wc -l
}

# Get all instance names
get_instance_names() {
    docker ps -a --filter "name=obs-instance" --format "{{.Names}}" | sort
}

# Extract instance number from container name
extract_instance_number() {
    local instance_name=$1
    
    # Handle different naming patterns:
    # obs-stream-obs-instance-1 -> 1
    # obs-stream-obs-instance-4-1 -> 4
    if [[ $instance_name =~ obs-stream-obs-instance-([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ $instance_name =~ obs-instance-([0-9]+) ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        # Fallback: try to extract any number after obs-instance-
        echo "$instance_name" | sed 's/.*obs-instance-\([0-9]\+\).*/\1/'
    fi
}

# Find actual container name for an instance number
find_container_name() {
    local instance_num=$1
    # Look for container names that match the pattern, including stopped containers
    docker ps -a --format "{{.Names}}" | grep -E "obs-instance-${instance_num}(-[0-9]+)?$" | head -1
}

# Detect OS and set browser open command
detect_os() {
    case "$(uname -s)" in
        Darwin)
            OPEN_CMD="open"
            ;;
        Linux)
            OPEN_CMD="xdg-open"
            ;;
        CYGWIN*|MINGW32*|MSYS*|MINGW*)
            OPEN_CMD="start"
            ;;
        *)
            OPEN_CMD="echo"
            ;;
    esac
}

# Open browsers to instances
open_browsers() {
    detect_os
    echo "Opening browsers to OBS instances..."

    if [ ${#INSTANCES[@]} -eq 0 ]; then
        # Open all running instances
        for container_name in $(get_instance_names); do
            if instance_num=$(extract_instance_number "$container_name"); then
                novnc_port=$((6080 + instance_num))
                url="http://localhost:${novnc_port}"
                echo "Opening $container_name at $url"
                $OPEN_CMD "$url" 2>/dev/null &
                sleep 2
            fi
        done
    else
        # Open specified instances
        for instance_num in "${INSTANCES[@]}"; do
            if container_name=$(find_container_name "$instance_num"); then
                novnc_port=$((6080 + instance_num))
                url="http://localhost:${novnc_port}"
                echo "Opening $container_name at $url"
                $OPEN_CMD "$url"
            else
                echo "Warning: Instance $instance_num is not running"
            fi
        done
    fi

    echo "Browser tabs opened. Check your browser for the OBS instances."
}

# Show status of instances
show_status() {
    echo "OBS Instances Status:"
    echo "===================="

    if [ "$(get_running_instances)" -eq 0 ]; then
        echo "No OBS instances are currently running."
        return
    fi

    printf "%-15s %-10s %-15s %-15s %-15s\n" "Instance" "Status" "NoVNC Port" "WS Port" "Resolution"
    printf "%-15s %-10s %-15s %-15s %-15s\n" "--------" "------" "----------" "-------" "----------"

    for instance in $(get_instance_names); do
        if docker ps --format "{{.Names}}" | grep -q "^${instance}$"; then
            status="Running"
        else
            status="Stopped"
        fi

        # Extract instance number
        num=$(extract_instance_number "$instance")

        # Calculate ports
        novnc_port=$((6080 + num))
        ws_port=$((4454 + num))

        # Get resolution from labels (if available)
        resolution=$(docker inspect $instance 2>/dev/null | grep -A 5 "Labels" | grep "resolution" | cut -d'"' -f4 || echo "Unknown")

        printf "%-15s %-10s %-15s %-15s %-15s\n" "$instance" "$status" "$novnc_port" "$ws_port" "$resolution"
    done

    echo ""
    echo "Detailed Port Information:"
    echo "=========================="

    for container_name in $(get_instance_names); do
        if instance_num=$(extract_instance_number "$container_name"); then
            novnc_port=$((6080 + instance_num))
            websocket_port=$((4454 + instance_num))
            vnc_port=$((5900 + instance_num))
            echo "Instance $instance_num ($container_name):"
            echo "  NoVNC: http://localhost:$novnc_port"
            echo "  WebSocket: ws://localhost:$websocket_port"
            echo "  VNC: localhost:$vnc_port"
            echo ""
        fi
    done
}

# Start specific instances or all
start_instances() {
    if [ ${#INSTANCES[@]} -eq 0 ]; then
        echo "Starting all OBS instances..."
        docker-compose up -d
    else
        echo "Starting instances: ${INSTANCES[*]}"
        for instance in "${INSTANCES[@]}"; do
            docker-compose up -d obs-instance-$instance
        done
    fi

    # Check if --open flag was used
    if [[ "${INSTANCES[*]}" == *"--open"* ]]; then
        echo "Opening browsers to started instances..."
        sleep 5  # Wait for instances to fully start
        # Remove --open from instances array for browser opening
        local clean_instances=()
        for inst in "${INSTANCES[@]}"; do
            if [[ "$inst" != "--open" ]]; then
                clean_instances+=("$inst")
            fi
        done
        INSTANCES=("${clean_instances[@]}")
        open_browsers
    fi
}

# Stop specific instances or all
stop_instances() {
    if [ ${#INSTANCES[@]} -eq 0 ]; then
        echo "Stopping all OBS instances..."
        docker-compose down
    else
        echo "Stopping instances: ${INSTANCES[*]}"
        for instance_num in "${INSTANCES[@]}"; do
            if container_name=$(find_container_name "$instance_num"); then
                echo "Stopping $container_name..."
                docker stop "$container_name"
            else
                echo "Warning: Instance $instance_num is not running"
            fi
        done
    fi
}

# Restart instances
restart_instances() {
    if [ ${#INSTANCES[@]} -eq 0 ]; then
        echo "Restarting all OBS instances..."
        docker-compose restart
    else
        echo "Restarting instances: ${INSTANCES[*]}"
        for instance_num in "${INSTANCES[@]}"; do
            if container_name=$(find_container_name "$instance_num"); then
                echo "Restarting $container_name..."
                docker restart "$container_name"
            else
                echo "Warning: Instance $instance_num is not running"
            fi
        done
    fi
}

# Show logs for instances
show_logs() {
    if [ ${#INSTANCES[@]} -eq 0 ]; then
        echo "Showing logs for all instances..."
        docker-compose logs -f
    else
        echo "Showing logs for instances: ${INSTANCES[*]}"
        for instance_num in "${INSTANCES[@]}"; do
            if container_name=$(find_container_name "$instance_num"); then
                echo "=== Logs for $container_name ==="
                docker logs "$container_name"
                echo ""
            else
                echo "Warning: Instance $instance_num is not running"
            fi
        done
    fi
}

# Show resource usage
show_resources() {
    echo "OBS Instances Resource Usage:"
    echo "============================"

    for instance in $(get_instance_names); do
        if docker ps --format "{{.Names}}" | grep -q "^${instance}$"; then
            echo "=== $instance ==="
            docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $instance
            echo ""
        fi
    done
}

# Open shell to instances
open_shell() {
    echo "Opening shell to OBS instances..."

    if [ ${#INSTANCES[@]} -eq 0 ]; then
        # Open shell to all running instances
        for container_name in $(get_instance_names); do
            if instance_num=$(extract_instance_number "$container_name"); then
                echo "Opening shell for $container_name..."
                docker exec -it "$container_name" /bin/bash
            fi
        done
    else
        # Open shell to specified instances
        for instance_num in "${INSTANCES[@]}"; do
            if container_name=$(find_container_name "$instance_num"); then
                echo "Opening shell for $container_name..."
                docker exec -it "$container_name" /bin/bash
            else
                echo "Warning: Instance $instance_num is not running"
            fi
        done
    fi
}

# Remove instances (delete containers)
remove_instances() {
    if [ $# -eq 0 ]; then
        echo "Removing all stopped instances..."
        for container_name in $(docker ps -a --format "{{.Names}}" | grep obs-instance); do
            if ! docker ps --format "{{.Names}}" | grep -q "^${container_name}$"; then
                echo "Removing $container_name..."
                docker rm "$container_name"
            fi
        done
    else
        echo "Removing instances: $@"
        for instance_num in "$@"; do
            if container_name=$(find_container_name "$instance_num"); then
                echo "Removing $container_name..."
                docker rm "$container_name"
            else
                echo "Warning: Instance $instance_num not found"
            fi
        done
    fi
}

# Main command handling
case $COMMAND in
    status)
        show_status
        ;;
    start)
        start_instances
        ;;
    stop)
        stop_instances
        ;;
    restart)
        restart_instances
        ;;
    logs)
        show_logs
        ;;
    resources)
        show_resources
        ;;
    open)
        open_browsers
        ;;
    shell)
        open_shell
        ;;
    remove)
        remove_instances
        ;;
    *)
        echo "Usage: $0 {status|start|stop|restart|logs|resources|open|shell|remove} [instance_numbers...] [--open]"
        echo ""
        echo "Commands:"
        echo "  status     - Show status of all instances"
        echo "  start      - Start instances (all or specified)"
        echo "  stop       - Stop instances (all or specified)"
        echo "  restart    - Restart instances (all or specified)"
        echo "  logs       - Show logs for instances"
        echo "  resources  - Show resource usage for running instances"
        echo "  open       - Open browsers to NoVNC interfaces (all or specified)"
        echo "  shell      - Open shell to OBS instances (all or specified)"
        echo "  remove     - Remove instances (delete containers, all stopped or specified)"
        echo ""
        echo "Flags:"
        echo "  --open     - Automatically open browsers when starting instances"
        echo ""
        echo "Examples:"
        echo "  $0 status"
        echo "  $0 start 1 3 5"
        echo "  $0 start 1 2 --open    # Start instances and open browsers"
        echo "  $0 stop"
        echo "  $0 logs 2"
        echo "  $0 open 1 2"
        echo "  $0 open                # Opens all running instances"
        echo "  $0 shell 1 2           # Opens shell to instances 1 and 2"
        echo "  $0 shell                # Opens shell to all running instances"
        echo "  $0 remove 1 2           # Removes instances 1 and 2"
        echo "  $0 remove                # Removes all instances"
        exit 1
        ;;
esac