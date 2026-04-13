#!/bin/zsh

os=$(uname -s)

if [[ "$os" == "Darwin" ]]; then
    cpu=$(top -l 1 | awk -F'[:, ]+' '/CPU usage/ {print int($3 + $5)}')
    mem=$(memory_pressure 2>/dev/null | awk -F': ' '/System-wide memory free percentage/ {gsub(/%/, "", $2); print int(100 - $2)}')
elif [[ "$os" == "Linux" ]]; then
    cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print int(100 - $8)}')
    mem=$(free | awk '/Mem:/ {print int($3/$2 * 100)}')
else
    cpu="?"
    mem="?"
fi

printf " %s%%  󰾆 %s%%" "$cpu" "$mem"
