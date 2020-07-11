#!/bin/sh

cp /etc/fstab /etc/fstab.pre-remove-swap
awk '($1 == "#") || ($3 != "swap")' /etc/fstab.pre-remove-swap >/etc/fstab

swapoff -a
