#!/bin/bash

# Backup the main sources.list file
cp /etc/apt/sources.list /etc/apt/sources.list.bak

# Replace archive.ubuntu.com and its subdomains with ubuntu.mobinhost.com
sed -i 's|http[s]\?://[a-zA-Z0-9.-]*\.archive\.ubuntu\.com|http://ubuntu.mobinhost.com|g' /etc/apt/sources.list

# Process additional sources in sources.list.d directory
for file in /etc/apt/sources.list.d/*.list; do
    [ -f "$file" ] || continue
    cp "$file" "$file.bak"
    sed -i 's|http[s]\?://[a-zA-Z0-9.-]*\.archive\.ubuntu\.com|http://ubuntu.mobinhost.com|g' "$file"
done

echo "All Ubuntu archive URLs have been updated to ubuntu.mobinhost.com"
