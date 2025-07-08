#!/bin/bash

for file in /etc/yum.repos.d/*.repo; do
    section=""
    enabled=0
    already_modified=0

    # Check if 'mirrorlist' is already commented out, meaning file was modified before
    if grep -q '^#mirrorlist' "$file"; then
        already_modified=1
    fi

    while read -r line; do
        if [[ $line =~ ^\[(.*)\] ]]; then
            section=${BASH_REMATCH[1]}
            enabled=0
        elif [[ $line =~ ^enabled[[:space:]]*=[[:space:]]*1 ]]; then
            enabled=1
            echo "$file: section [$section] is enabled"

            if [[ $already_modified -eq 0 ]]; then
                # Only apply changes if not already modified
                sed -i 's,mirrorlist,#mirrorlist,g' "$file"
                sed -i 's,# baseurl,baseurl,g' "$file"
                sed -i 's,repo.almalinux.org/almalinux,almalinux.mobinhost.com,g' "$file"
                already_modified=1
                echo "Changes applied to $file"
            else
                echo "$file already modified. Skipping..."
            fi
        fi
    done < "$file"
done

# ------------------------------------------------------------------
# Now handle epel-cisco-openh264.repo and epel.repo edits smartly
# ------------------------------------------------------------------

repo_dir="/etc/yum.repos.d"
cisco_repo="$repo_dir/epel-cisco-openh264.repo"
epel_repo="$repo_dir/epel.repo"

if [ -f "$cisco_repo" ]; then
    if grep -q "^enabled=1" "$cisco_repo"; then
		sed -i 's/enabled=1/enabled=0/g' "$cisco_repo"
        echo "Disabled epel-cisco-openh264.repo."
    else
        echo "epel-cisco-openh264.repo is already disabled."
    fi

    if grep -q "^baseurl=https://epel.mobinhost.com" "$epel_repo"; then
        echo "epel.repo is already modified."
    else
        sed -i 's/#baseurl/baseurl/g' "$epel_repo"
        sed -i 's|download.example/pub/epel|epel.mobinhost.com|g' "$epel_repo"
        sed -i 's/metalink/#metalink/g' "$epel_repo"
        echo "Modified epel.repo."
    fi
else
    echo "epel-cisco-openh264.repo not found, skipping."
fi
