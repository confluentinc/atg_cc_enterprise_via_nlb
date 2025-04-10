#!/bin/sh

SERVER=$1
PORT=$2
nc -z -v -G5 $SERVER $PORT &> /dev/null
result1=$?

#Do whatever you want

if [  "$result1" != 0 ]; then
  echo  {\"is_connected\": \"false\"}
else
  echo  {\"is_connected\": \"true\"}
fi
