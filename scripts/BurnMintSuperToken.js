const { web3tx } = require("@decentral.ee/web3-helpers")
const { setWeb3Provider } = require("@decentral.ee/web3-helpers/src/config")
const { factory } = require("./utils/constants")
const BurnMintSuperToken = artifacts.require("BurnMintSuperToken")

module.exports = async function (callback) {
	const name = "Burnable/Mintable Super Token"
	const symbol = "BMST"
	const initialSupply = "1"
	const receiver = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
	const userData = "0x"

	try {
		setWeb3Provider(web3.currentProvider)

		const chainId = await web3.eth.net.getId()
		const superTokenFactory = factory[chainId]

		const burnMintSuperToken = await web3tx(
			BurnMintSuperToken.new,
			"Deploy BurnableSuperToken contract"
		)()

		console.log(`Deployed at: ${burnMintSuperToken.address}`)

		await web3tx(
			burnMintSuperToken.initialize,
			"Initialize BurnableSuperToken contract"
		)(name, symbol, superTokenFactory, initialSupply, receiver, userData)

		callback()
	} catch (error) {
		console.error(error)
		callback(error)
	}
}
