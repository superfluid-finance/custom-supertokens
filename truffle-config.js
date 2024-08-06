require("dotenv").config()
const HDWalletProvider = require("@truffle/hdwallet-provider")

module.exports = {
	plugins: ["@d10r/truffle-plugin-verify"],
	networks: {
		// can be used for any network, just set ANY_PROVIDER_URL accordingly
		any: {
			provider: () =>
				new HDWalletProvider({
					mnemonic: process.env.MNEMONIC,
					url: process.env.RPC
				}),
			network_id: "*",
			skipDryRun: false
		}
	},
	mocha: {
		timeout: 100000
	},
	// Configure your compilers
	compilers: {
		solc: {
			version: "0.8.19"
		}
	},
	api_keys: {
		etherscan: process.env.ETHERSCAN_API_KEY,
		polygonscan: process.env.POLYGONSCAN_API_KEY,
		snowtrace: process.env.SNOWTRACE_API_KEY,
		optimistic_etherscan: process.env.OPTIMISTIC_API_KEY,
		bscscan: process.env.BSCSCAN_API_KEY,
		arbiscan: process.env.ARBISCAN_API_KEY,
		gnosisscan: process.env.GNOSISSCAN_API_KEY,
		celoscan: process.env.CELOSCAN_API_KEY,
		basescan: process.env.BASESCAN_API_KEY,
		zkevm_polygonscan: process.env.ZKEVM_POLYGONSCAN_API_KEY,
		scrollscan: process.env.SCROLLSCAN_API_KEY
	}
}
