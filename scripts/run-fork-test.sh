#!/bin/bash

# usage: run-fork-test.sh <network> <testContract> [<extraArg> ...]

set -eu

network=$1
testContract=$2
shift 2
extraArgs=$@

metadata=$(curl -s "https://raw.githubusercontent.com/superfluid-finance/protocol-monorepo/dev/packages/metadata/networks.json")

# takes the network name as argument
function test_network() {
	rpc=${RPC:-"https://${network}.rpc.x.superfluid.dev"}

	echo "=============== Testing $network... ==================="

	# get current metadata

	host=$(echo "$metadata" | jq -r '.[] | select(.name == "'$network'").contractsV1.host')

	# Print the host address
	echo "Host: $host"

	set -x
	RPC=$rpc HOST_ADDR=$host forge test --match-contract $testContract $extraArgs
}

test_network