#!/bin/bash
# File: networker-port-ck.sh
# Purpose: Check the port numbers used by networker

# Check if networker client is installed.
NC=$(rpm -q lgtoclnt 2>/dev/null)
if [ "$NC" = "package lgtoclnt is not installed" ]
then
	echo "Networker is not installed."
	exit 0
fi
RCFILE=/tmp/networker-port-ck.txt
SPORT=$(sudo nsrports|grep "Service ports"|awk '{print $3}'|awk -F"-" '{print $1}')
EPORT=$(sudo nsrports|grep "Service ports"|awk '{print $3}'|awk -F"-" '{print $2}')

if [ -f /usr/sbin/nsrrpcinfo ]
then
	CMD=/usr/sbin/nsrrpcinfo
	declare -i PORT=0
	sudo $CMD -p|grep -v PROGRAM|while read PRG VER PROTO PORT SERVICE D1 D2
	do
        	if [ "$PORT" -lt "$SPORT" -o "$PORT" -gt "$EPORT" ]
        	then
                	echo "Bad Networker Port: $PORT - $ST $PP"
			RC=1
			echo "$RC" > $RCFILE	
        	fi
	done
elif [ -f /usr/bin/netstat ]
then
	CMD=/usr/bin/netstat
	sudo $CMD -tulpn|grep nsr|while read PROTO RQ SQ LADDR FADDR ST PP
	do
        	declare -i PORT=0
		RC=0
        	PORT=$(echo $LADDR|tr -d ":")
        	if [ "$PORT" -lt "$SPORT" -o "$PORT" -gt "$EPORT" ]
        	then
                	echo "Bad Networker Port: $PORT - $ST $PP"
			RC=1
			echo "$RC" > $RCFILE	
        	fi
	done
elif [ -f /usr/bin/lsof ]
then
	CMD=/usr/bin/lsof
	sudo $CMD -i -P -n|grep nsr|while read CMD1 PID USER FD TYPE DEV SZ PROTO NAME ST
	do
        	declare -i PORT=0
		RC=0
        	PORT=$(echo $NAME|awk -F":" '{print $2}')
        	if [ "$PORT" -lt "$SPORT" -o "$PORT" -gt "$EPORT" ]
        	then
                	echo "Bad Networker Port: $PORT - $ST $PP"
			RC=1
			echo "$RC" > $RCFILE	
        	fi
	done
elif [ -f /usr/sbin/lsof ]
then
	CMD=/usr/sbin/lsof
	sudo $CMD -i -P -n|grep nsr|grep -v '\->'|while read CMD1 PID USER FD TYPE DEV SZ PROTO NAME ST
	do
        	declare -i PORT=0
		RC=0
        	PORT=$(echo $NAME|awk -F":" '{print $2}')
        	if [ "$PORT" -lt "$SPORT" -o "$PORT" -gt "$EPORT" ]
        	then
                	echo "Bad Networker Port: $PORT - $ST $PP"
			RC=1
			echo "$RC" > $RCFILE	
        	fi
	done
else
	echo "netstat or lsof not found"
	exit 1
fi

if [ -f $RCFILE ]
then
	RC=$(cat $RCFILE)
	rm $RCFILE
else
	echo "Networker Ports are in Range."
	RC=0
fi
exit $RC
