const { web3tx } = require("@decentral.ee/web3-helpers")
const { setWeb3Provider } = require("@decentral.ee/web3-helpers/src/config")
const BurnableSuperToken = artifacts.require("BurnableSuperToken")

module.exports = async function (callback) {
	try {
		setWeb3Provider(web3.currentProvider)

		const burnableSuperToken = await web3tx(
			BurnableSuperToken.new,
			"Deploy BurnableSuperToken contract"
		)()
	} catch (error) {
		console.error(error)
		callback(error)
	}
}
