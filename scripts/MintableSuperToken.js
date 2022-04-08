const { web3tx } = require("@decentral.ee/web3-helpers")
const { setWeb3Provider } = require("@decentral.ee/web3-helpers/src/config")
const { factory } = require("./utils/constants")
const MintableSuperToken = artifacts.require("MintableSuperToken")

module.exports = async function (callback) {
	const name = "Burnable/Mintable Super Token"
	const symbol = "BMST"

	try {
		setWeb3Provider(web3.currentProvider)

		const chainId = await web3.eth.net.getId()
		const superTokenFactory = factory[chainId]

		const mintableSuperToken = await web3tx(
			MintableSuperToken.new,
			"Deploy BurnableSuperToken contract"
		)()

		console.log(`Deployed at: ${mintableSuperToken.address}`)

		await web3tx(
			mintableSuperToken.initialize,
			"Initialize BurnableSuperToken contract"
		)(name, symbol, superTokenFactory)

		callback()
	} catch (error) {
		console.error(error)
		callback(error)
	}
}
