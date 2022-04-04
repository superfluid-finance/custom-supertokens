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
// const { web3tx } = require("@decentral.ee/web3-helpers")
// const { setWeb3Provider } = require("@decentral.ee/web3-helpers/src/config")
// const SuperFractionalizer = artifacts.require("SuperFractionalizer")
// // const JuicyNFT = artifacts.require('JuicyNFT')

// module.exports = async function (callback) {
// 	try {
// 		setWeb3Provider(web3.currentProvider)

// 		const superFractionalizer = await web3tx(
// 			SuperFractionalizer.new,
// 			"Deploy SuperFractionalizer"
// 		)("0x2C90719f25B10Fc5646c82DA3240C76Fa5BcCF34")

// 		console.log({ superFractionalizer })
// 		// const juicyNFT = await web3tx(
// 		// 	JuicyNFT.new,
// 		// 	"Deploy JuicyNFT"
// 		// )(
// 		// 	"Juicy NFT",
// 		// 	"JNFT",
// 		// 	"ipfs://bafyreiauhev5snezofkgscfdr6hmtmi753bwfsqrmecr4wg7ttwkqkek5u/metadata.json"
// 		// )

// 		// console.log({ juicyNFT })
// 		callback()
// 	} catch (error) {
// 		console.error({ error })
// 		callback(error)
// 	}
// }
