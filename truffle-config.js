require("dotenv").config()

module.exports = {
	plugins: ["truffle-plugin-verify"],

	networks: {
		ganache: {
			host: "127.0.0.1",
			network_id: "*",
			port: process.env.GANACHE_PORT || 8545
		}
	},
	mocha: {
		timeout: 100000
	},

	// Configure your compilers
	compilers: {
		solc: {
			version: "^0.8.0"
		}
	}
}
