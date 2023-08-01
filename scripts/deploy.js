const { web3tx } = require("@decentral.ee/web3-helpers")
const { setWeb3Provider } = require("@decentral.ee/web3-helpers/src/config")
const sfMeta = require("@superfluid-finance/metadata")

/*
 * Truffle script for deploying a custom Super Token
 * New contracts can be easily added.
 * Constructor arguments are to be set via ENV vars.
 *
 * ENV vars:
 * - CONTRACT: the name of the contract, e.g. "MintableSuperToken"
 * - CTOR_ARGS: comma-delimited arguments to the constructor of the token proxy contract
 * - INIT_ARGS: comma-delimited arguments (excluding factory) to the initialize function of the token contract
 * - FACTORY: address of the SuperTokenFactory, needed on dev networks
 *
 * Example use:
 * CONTRACT=MintableSuperToken INIT_ARGS="my token","MTK" npx truffle exec --network goerli scripts/deploy.js
 *
 * If used to deploy on a development network, you also need to set FACTORY to a Super Token Factory address.
 */
module.exports = async function (callback) {
	const contractName = process.env.CONTRACT

	const ctorArgsStr = process.env.CTOR_ARGS
	const initArgsStr = process.env.INIT_ARGS

	const ctorArgs = ctorArgsStr
		? ctorArgsStr.split(",").map(e => e.trim())
		: []
	const initArgs = initArgsStr
		? initArgsStr.split(",").map(e => e.trim())
		: []

	try {
		if (contractName === undefined) {
			throw "ERR: ENV var CONTRACT not set"
		}

		// will throw if not found
		const Contract = artifacts.require(contractName)

		console.log("contructor args:", ctorArgs)
		console.log("initialize args:", initArgs)

		setWeb3Provider(web3.currentProvider)

		const chainId = await web3.eth.net.getId()

		const network = sfMeta.getNetworkByChainId(chainId)

		const factoryAddr =
			process.env.FACTORY || network.contractsV1.superTokenFactory
		if (factoryAddr === undefined) {
			throw "ERR: No SuperTokenFactory address provided of found for the connected chain"
		}

		console.log("SuperTokenFactory address", factoryAddr)

		const proxy = await web3tx(
			Contract.new,
			"Deploy Proxy contract"
		)(...ctorArgs)

		console.log(`Proxy deployed at: ${proxy.address}`)

		await web3tx(proxy.initialize, "Initialize Token contract")(
			factoryAddr,
			...initArgs
		)

		console.log(
			"All done, token deployed and initialized at:",
			proxy.address
		)
		callback()
	} catch (error) {
		callback(error)
	}
}
