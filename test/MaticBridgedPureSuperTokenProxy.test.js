const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")
const MaticBridgedPureSuperTokenProxy = artifacts.require(
	"MaticBridgedPureSuperTokenProxy"
)
const IMaticBridgedPureSuperToken = artifacts.require(
	"IMaticBridgedPureSuperToken"
)
const ISuperTokenFactory = artifacts.require(
	"@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol"
)
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"

const expectedRevert = async (fn, revertMsg, printError = false) => {
	try {
		await fn
		return false
	} catch (err) {
		if (printError) console.log(err)
		return err.hijackedStack.toString().includes(revertMsg)
	}
}

contract("MaticBridgedPureSuperTokenProxy", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	const [admin, chainMgr] = accounts.slice(0, 3)

	before(
		async () =>
			await deployFramework(errorHandler, {
				web3,
				from: admin,
				newTestResolver: true
			})
	)

	beforeEach(async () => {
		sf = new SuperfluidSDK.Framework({
			web3,
			version: "test",
			additionalContracts: ["INativeSuperToken"],
			contractLoader: builtTruffleContractLoader
		})

		await sf.initialize()
		cfa = sf.agreements.cfa
		superTokenFactory = await ISuperTokenFactory.at(
			await sf.host.getSuperTokenFactory()
		)
		console.log("chainMgr: ", chainMgr)
		tokenProxy = await web3tx(
			MaticBridgedPureSuperTokenProxy.new,
			"MaticBridgedPureSuperTokenProxy deploy"
		)(chainMgr)

		await web3tx(
			superTokenFactory.initializeCustomSuperToken,
			"superTokenFactory.initializeCustomSuperToken"
		)(tokenProxy.address)

		token = await IMaticBridgedPureSuperToken.at(tokenProxy.address)
		await web3tx(token.initialize, "initialize")(
			ZERO_ADDRESS,
			18,
			"Matic Bridged Token",
			"MBT"
		)
	})

	it("#1 can initialize only once", async () => {
		const rightError = await expectedRevert(
			token.initialize(
				ZERO_ADDRESS,
				18,
				"Hacked Matic Bridged Token",
				"HMBT"
			),
			"Initializable: contract is already initialized"
		)
		assert.ok(rightError)
	})
})
