#!/bin/env bash
# get the api Token
TOKEN="$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)"
# GET /api/v1/events
EVENT_API="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/events"
# GET /api/v1/nodes
NODE_API="https://${KUBERNETES_SERVICE_HOST}:${KUBERNETES_PORT_443_TCP_PORT}/api/v1/nodes"

while true
do
  # Get the number of nodes that are currently running
  CURRENT_NODE=$(curl -s -k -H "Authorization: Bearer ${TOKEN}" ${NODE_API} | jq '.items | length')
  # Listen for RegisterNode events
  NODE_REGISTER_EVENT=$(curl -k -s -H "Authorization: Bearer ${TOKEN}" ${EVENT_API} | jq -r '.items[]|select(.reason=="RegisteredNode")|.lastTimestamp' | tail -n 1)
  # Listen for RemovingNode events
  NODE_DELETE_EVENT=$(curl -k -s -H "Authorization: Bearer ${TOKEN}" ${EVENT_API} | jq -r '.items[]|select(.reason=="RemovingNode")|.lastTimestamp' | tail -n 1)
  
  if [ -z "${NODE_REGISTER_EVENT}" ]
  then
    echo "[$(date)] no events for NodeRegister"
  else

      REGISTER_EVENT_TIME_DIFFERENCE="$(($(date +%s) - $(date -d ${NODE_REGISTER_EVENT} +%s)))"
      
      if [ ${REGISTER_EVENT_TIME_DIFFERENCE} -lt "70" ]
      then
          echo Scaling UP to ${CURRENT_NODE} nodes
          curl -X POST -H 'Content-type: application/json; charset=utf-8' --data "{ 'text': '↑↑↑↑↑ Scaling UP to ${CURRENT_NODE} nodes' }"
      else
          echo "[$(date)] NodeRegister: Last event occurred $(($(echo ${REGISTER_EVENT_TIME_DIFFERENCE}) / 60 )) minutes ago "
      fi
  fi

  if [ -z "${NODE_DELETE_EVENT}" ]
  then
      echo "[$(date)] no events for NodeDelete"
  else
      DELETE_EVENT_TIME_DIFFERENCE="$(($(date +%s) - $(date -d ${NODE_DELETE_EVENT} +%s)))"
      
      if [ ${DELETE_EVENT_TIME_DIFFERENCE} -lt "70" ]
      then
          echo Scaling DOWN to ${CURENT_NODE} nodes
          curl -X POST -H 'Content-type: application/json; charset=utf-8' --data "{ 'text': '↓↓↓↓↓ Scaling DOWN to ${CURRENT_NODE} nodes' }" 
      else
        echo "[$(date)] NodeDelete: Last event occurred $(($(echo ${DELETE_EVENT_TIME_DIFFERENCE}) / 60 )) minutes ago "
      fi
  fi

  sleep 60

done
