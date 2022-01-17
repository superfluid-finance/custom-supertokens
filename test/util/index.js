async function fastForward(seconds) {
	console.log(`Fast forwarding ${seconds} seconds`)
	await web3.currentProvider.send(
		{
			jsonrpc: "2.0",
			method: "evm_increaseTime",
			params: [seconds],
			id: 0
		},
		() => {}
	)
	await web3.currentProvider.send(
		{
			jsonrpc: "2.0",
			method: "evm_mine",
			params: [],
			id: 0
		},
		() => {}
	)
}

module.exports = { fastForward }
