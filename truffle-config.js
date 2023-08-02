require("dotenv").config()
const HDWalletProvider = require("@truffle/hdwallet-provider")

module.exports = {
	plugins: ["truffle-plugin-verify"],
	networks: {
		// goerli testnet
		goerli: {
			provider: () =>
				new HDWalletProvider(
					process.env.GOERLI_MNEMONIC,
					process.env.GOERLI_PROVIDER_URL
				),
			network_id: 5, // Goerli's id
			timeoutBlocks: 50, // # of blocks before a deployment times out  (minimum/default: 50)
			skipDryRun: false // Skip dry run before migrations? (default: false for public nets )
		},

		// Optimisim goerli testnet
		opgoerli: {
			provider: () =>
				new HDWalletProvider(
					process.env.OPGOERLI_MNEMONIC,
					process.env.OPGOERLI_PROVIDER_URL
				),
			network_id: 420, // Goerli's id
			timeoutBlocks: 50, // # of blocks before a deployment times out  (minimum/default: 50)
			skipDryRun: false // Skip dry run before migrations? (default: false for public nets )
		},

		// Polygon PoS mainnet
		matic: {
			provider: () =>
				new HDWalletProvider({
					mnemonic: process.env.MATIC_MNEMONIC,
					url: process.env.MATIC_PROVIDER_URL
				}),
			network_id: 137,
			skipDryRun: false
		},

		// Polygon mumbai testnet
		mumbai: {
			provider: () =>
				new HDWalletProvider({
					mnemonic: process.env.MUMBAI_MNEMONIC,
					url: process.env.MUMBAI_PROVIDER_URL
				}),
			network_id: 80001,
			skipDryRun: false
		},

		// can be used for any network, just set ANY_PROVIDER_URL accordingly
		any: {
			provider: () =>
				new HDWalletProvider(
					process.env.ANY_MNEMONIC,
					process.env.ANY_PROVIDER_URL
				),
			network_id: "*",
			// gas price settings: default is undefined -> auto-detected via RPC
			// can be overridden with env vars
			// legacy tx type
			gasPrice: process.env.GAS_PRICE,
			// EIP-1559 tx type
			maxPriorityFeePerGas: process.env.MAX_PRIORITY_FEE,
			maxFeePerGas: process.env.MAX_FEE,
			skipDryRun: false
		}
	},
	mocha: {
		timeout: 100000
	},
	// Configure your compilers
	compilers: {
		solc: {
			version: "0.8.19",
			settings: {
				// See the solidity docs for advice about optimization and evmVersion
				optimizer: {
					enabled: true,
					runs: 200
				}
				// evmVersion: use default
			}
		}
	},
	api_keys: {
		etherscan: process.env.ETHERSCAN_API_KEY,
		polygonscan: process.env.POLYGONSCAN_API_KEY,
		snowtrace: process.env.SNOWTRACE_API_KEY,
		optimistic_etherscan: process.env.OPTIMISTIC_API_KEY,
		bscscan: process.env.BSCSCAN_API_KEY,
		arbiscan: process.env.ARBISCAN_API_KEY,
		gnosisscan: process.env.GNOSISSCAN_API_KEY
	}
}
