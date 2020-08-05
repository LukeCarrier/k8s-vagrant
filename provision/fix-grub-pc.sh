#!/bin/sh

target=''
for dev in /sys/class/block/*; do
    echo "Looking for ${dev}'s device node"
    dev_node="$(awk -F= '$1 == "DEVNAME" {print $2}' ${dev}/uevent)"

    if [ -z "$dev_node" ]; then
        echo 'Failed to determine device node name; skipping'
        continue
    fi
    dev_node_path="/dev/${dev_node}"
    echo "uevent claims it's ${dev_node}; looking for ${dev_node_path}"
    if [ ! -b "$dev_node_path" ]; then
        echo "It's not at ${dev_node_path}; skipping"
        continue
    fi

    echo "Looking for grub on ${dev_node_path}"
    if ! sudo dd if="$dev_node_path" bs=512 count=1 status=none | xxd | grep 'GRUB' >/dev/null; then
        echo "Didn't find grub on ${dev_node_path}"
        continue
    fi

    target="$dev_node_path"
    break
done

if [ -z "$target" ]; then
    echo 'Failed to find grub; aborting' >&2
    exit 1
fi

configured="$(echo "get grub-pc/install_devices" | debconf-communicate | awk '{print $2}')"
if [ "$target" = "$configured" ]; then
    echo "debconf configuration has the correct grub install device"
    exit 0
fi

echo "correcting debconf configuration; grub has moved from ${configured} to ${target}"
echo "set grub-pc/install_devices ${target}" | sudo debconf-communicate >/dev/null
