#!/bin/bash

# Exit on error and unset variables
set -euo pipefail

# Validate input
if [ $# -lt 1 ]; then
  echo "Usage: $0 <model-name>"
  exit 1
fi

MODEL="$1"

# Get IP and set PORT
IP=$(kubectl get gateway/inference-gateway -o jsonpath='{.status.addresses[0].value}')
PORT=80

# Debug info
echo "Sending request to ${IP}:${PORT} using model: ${MODEL}"

# Perform the request and capture response
RESPONSE=$(curl -s -i "${IP}:${PORT}/v1/completions" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "model": "${MODEL}",
  "prompt": "Write as if you were a critic: San Francisco",
  "max_tokens": 100,
  "temperature": 0
}
EOF
)

# Check if response contains HTTP/1.1 200 OK
if echo "$RESPONSE" | grep -q "HTTP/1.1 200 OK"; then
  echo "✅ Request succeeded"
  exit 0
else
  echo "❌ Request failed"
  echo "$RESPONSE"
  exit 1
fi