#!/bin/bash

# Usage: ./wait4gateway.sh <gateway-name> <namespace> <timeout-seconds>

GATEWAY="$1"
NAMESPACE="$2"
TIMEOUT="$3"

# Validate arguments
if [[ -z "$GATEWAY" || -z "$NAMESPACE" || -z "$TIMEOUT" ]]; then
  echo "❌ Error: Missing arguments."
  echo "Usage: $0 <gateway-name> <namespace> <timeout-seconds>"
  exit 1
fi

START=$(date +%s)

while true; do
  PROGRAMMED=$(kubectl get gateway "$GATEWAY" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Programmed")].status}' 2>/dev/null)
  IP=$(kubectl get gateway "$GATEWAY" -n "$NAMESPACE" -o jsonpath='{.status.addresses[0].value}' 2>/dev/null)

  if [[ "$PROGRAMMED" == "True" && -n "$IP" ]]; then
    echo "✅ Gateway '$GATEWAY' is programmed and has IP: $IP"
    exit 0
  fi

  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "❌ Timeout waiting for Gateway '$GATEWAY' to be programmed and assigned an IP"
    exit 1
  fi

  sleep 2
done