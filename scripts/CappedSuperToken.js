const { web3tx } = require("@decentral.ee/web3-helpers")
const { setWeb3Provider } = require("@decentral.ee/web3-helpers/src/config")
const { factory } = require("./utils/constants")
const CappedSuperToken = artifacts.require("CappedSuperToken")

module.exports = async function (callback) {
	const name = "Capped Super Token"
	const symbol = "CST"
	const maxSupply = "1"

	try {
		setWeb3Provider(web3.currentProvider)

		const chainId = await web3.eth.net.getId()
		const superTokenFactory = factory[chainId]

		const cappedSuperToken = await web3tx(
			CappedSuperToken.new,
			"Deploy BurnableSuperToken contract"
		)()

		console.log(`Deployed at: ${cappedSuperToken.address}`)

		await web3tx(
			cappedSuperToken.initialize,
			"Initialize BurnableSuperToken contract"
		)(name, symbol, superTokenFactory, maxSupply)

		callback()
	} catch (error) {
		console.error(error)
		callback(error)
	}
}
