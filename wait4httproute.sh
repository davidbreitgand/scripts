#!/bin/bash

# Usage: ./wait4httproute.sh <route-name> <namespace> <timeout-seconds>

ROUTE="$1"
NAMESPACE="$2"
TIMEOUT="$3"

if [[ -z "$ROUTE" || -z "$NAMESPACE" || -z "$TIMEOUT" ]]; then
  echo "Usage: $0 <route-name> <namespace> <timeout-seconds>"
  exit 1
fi

START=$(date +%s)

while true; do
  ACCEPTED=$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}' 2>/dev/null)
  RESOLVED=$(kubectl get httproute "$ROUTE" -n "$NAMESPACE" -o jsonpath='{.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}' 2>/dev/null)

  if [[ "$ACCEPTED" == "True" && "$RESOLVED" == "True" ]]; then
    echo "✅ HTTPRoute '$ROUTE' is Accepted and ResolvedRefs is True"
    exit 0
  fi

  NOW=$(date +%s)
  ELAPSED=$((NOW - START))
  if [ "$ELAPSED" -ge "$TIMEOUT" ]; then
    echo "❌ Timeout waiting for conditions on HTTPRoute '$ROUTE'"
    exit 1
  fi

  sleep 2
done