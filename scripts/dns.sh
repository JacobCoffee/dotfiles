#!/bin/bash

# -- Helper script to consume the SSH config file(s)
# -- Attempts to resolve the IP for each HostName and add it and the corresponding Host aliases to /etc/hosts

# add entry to /etc/hosts if not there
function add_to_hosts() {
  local ip=$1
  local hostname=$2

  if ! grep -q "^$ip\s*$hostname" /etc/hosts; then
    echo "Adding $hostname ($ip) to /etc/hosts"
    echo "$ip $hostname" | sudo tee -a /etc/hosts > /dev/null
  else
    #    echo "$hostname already exists in /etc/hosts" >&2
    return 0
  fi
}

# -- Function to process hostnames and IP
function process_host() {
  local alias ip
  local hostnames=$1
  local hostname=$2

  if [[ $hostname == "localhost" || $hostname == "127.0.0.1" || $hostname == "0.0.0.0" ]]; then
    return 0
  fi

  ip=$(dig +short "$hostname" | grep -E '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' | head -n1)

  if [ -n "$ip" ]; then
    #    echo "Resolved IP for $hostname: $ip" >&2
    add_to_hosts "$ip" "$hostname"
    for alias in $hostnames; do
      [ "$alias" != "$hostname" ] && add_to_hosts "$ip" "$alias"
    done
  else
    echo "Could not resolve IP for $hostname" >&2
  fi
}

# -- Process a single SSH config file
function process_config_file() {
  local file=$1
  local line_number=0
  local hostnames hostname line included_file

  echo "Reading SSH config file: $file" >&2
  while IFS= read -r line; do
    ((line_number++))
    #    echo "Line $line_number: $line" >&2
    if [[ $line =~ ^Include ]]; then
      included_file=$(echo "$line" | awk '{print $2}')
      included_file="${included_file/#\~/$HOME}"
      #      echo "Processing included file: $included_file" >&2
      process_config_file "$included_file"
    elif [[ $line =~ ^Host ]]; then
      hostnames=$(echo "$line" | cut -d' ' -f2-)
      #      echo "Found hostnames: $hostnames" >&2
    elif [[ $line =~ ^[[:space:]]*HostName ]]; then
      hostname=$(echo "$line" | awk '{print $2}')
      #      echo "Found HostName: $hostname" >&2
      process_host "$hostnames" "$hostname"
    fi
  done < "$file"
}

# -- Get hostnames and IP from SSH config files
function get_config() {
  process_config_file ~/.ssh/config
  echo "Finished processing SSH config" >&2
}

# -- run it
function main() {
  local entries=$(get_config | grep "Adding")
  local entries_count=$(echo "$entries" | wc -l)

  if [ -n "$entries" ]; then
    echo "The following entries will be added to /etc/hosts:"
    echo "$entries"
    echo ""
    echo "$entries_count entries have been added to /etc/hosts"
  else
    echo "⚠️ No entries were added to /etc/hosts"
  fi
}

main "$@"
