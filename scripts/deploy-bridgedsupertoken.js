const sfMeta = require("@superfluid-finance/metadata")

const BridgedSuperToken = artifacts.require("BridgedSuperToken")

const ISuperTokenFactoryArtifact = require("@superfluid-finance/ethereum-contracts/artifacts/contracts/interfaces/superfluid/ISuperTokenFactory.sol/ISuperTokenFactory")
const SuperTokenArtifact = require("@superfluid-finance/ethereum-contracts/artifacts/contracts/superfluid/SuperToken.sol/SuperToken")

// see https://docs.connext.network/resources/deployments
const CONNEXT_ADDRS = {
	// testnets
	5: "0xFCa08024A6D4bCc87275b1E4A1E22B71fAD7f649", // goerli
	80001: "0x2334937846Ab2A3FCE747b32587e1A1A2f6EEC5a", // mumbai
	420: "0x5Ea1bb242326044699C3d81341c5f535d5Af1504", // OP goerli
	421613: "0x2075c9E31f973bb53CAE5BAC36a8eeB4B082ADC2", // Arb goerli
	1442: "0x20b4789065DE09c71848b9A4FcAABB2c10006FA2", // zkEVM

	// mainnets
	1: "0x8898B472C54c31894e3B9bb83cEA802a5d0e63C6",
	10: "0x8f7492DE823025b4CfaAB1D34c58963F2af5DEDA", // OP
	137: "0x11984dc4465481512eb5b777E44061C158CF2259", // Matic
	42161: "0xEE9deC2712cCE65174B561151701Bf54b99C24C8", // Arbitrum
	56: "0xCd401c10afa37d641d2F594852DA94C700e4F2CE", // BSC
	100: "0x5bB83e95f63217CDa6aE3D181BA580Ef377D2109" // Gnosis
}

/*
 * Truffle script for deploying BridgedSuperToken
 * optional env vars:
 * - UPGRADE_ADMIN (default: deployer)
 * - BRIDGE_ADDR (default: CONNEXT_ADDRS[chainId])
 * - HOST (default: taken from metadata)
 * - FACTORY (default: taken from metadata)
 */
module.exports = async function (callback) {
	try {
		const deployer = (await web3.eth.getAccounts())[0]
		console.log("deployer: ", deployer)

		const chainId = await web3.eth.getChainId()

		const upgradeAdmin = process.env.UPGRADE_ADMIN || deployer
		const bridgeAddr = process.env.BRIDGE_ADDR || CONNEXT_ADDRS[chainId]

		if (bridgeAddr === undefined) {
			throw new Error("no bridge address defined for chainId " + chainId)
		}

		console.log("chainId: ", chainId)

		const network = sfMeta.getNetworkByChainId(chainId)
		console.log("network: ", network.name)

		const hostAddr = process.env.HOST || network.contractsV1.host
		const factoryAddr =
			process.env.FACTORY || network.contractsV1.superTokenFactory

		const factory = new web3.eth.Contract(
			ISuperTokenFactoryArtifact.abi,
			factoryAddr
		)

		const curLogicAddr = await factory.methods.getSuperTokenLogic().call()
		console.log("current logic: ", curLogicAddr)

		// Get addresses of COF and CIF NFTs - note that this is NOT the same as the addresses in the factory contract
		// This point to the proxies while those in the factory point to the logic contracts
		const currentSTLogic = new web3.eth.Contract(
			SuperTokenArtifact.abi,
			curLogicAddr
		)
		const curCofNFTAddr = await currentSTLogic.methods
			.CONSTANT_OUTFLOW_NFT()
			.call()
		const curCifNFTAddr = await currentSTLogic.methods
			.CONSTANT_INFLOW_NFT()
			.call()

		console.log("COF NFT: ", curCofNFTAddr)
		console.log("CIF NFT: ", curCifNFTAddr)

		const newSTLogic = await BridgedSuperToken.new(
			hostAddr,
			curCofNFTAddr,
			curCifNFTAddr,
			upgradeAdmin,
			bridgeAddr
		)

		console.log("Deployed BridgedSuperToken:", newSTLogic.address)

		callback()
	} catch (error) {
		callback(error)
	}
}
