#!/bin/bash

# usage: test.sh <network>

set -eu

network=$1

metadata=$(curl -s "https://raw.githubusercontent.com/superfluid-finance/protocol-monorepo/dev/packages/metadata/networks.json")

# takes the network name as argument
function test_network() {
	network=$1

	rpc=${RPC:-"https://${network}.rpc.x.superfluid.dev"}

	echo "=============== Testing $network... ==================="

	# get current metadata

	host=$(echo "$metadata" | jq -r '.[] | select(.name == "'$network'").contractsV1.host')

	# Print the host address
	echo "Host: $host"

	RPC=$rpc HOST_ADDR=$host forge test -vvv
}

test_network $network
