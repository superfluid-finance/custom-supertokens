const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")
const { expectEvent } = require("@openzeppelin/test-helpers")
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
const AMOUNT_1 = toWad(3)
const AMOUNT_2 = toWad(5000)

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
	const [admin, chainMgr, bob] = accounts.slice(0, 3)

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

	it("#2 bridge interface permissions", async () => {
		await expectedRevert(
			token.deposit(
				bob,
				web3.eth.abi.encodeParameter("uint256", AMOUNT_1)
			),
			"MBPSuperToken: no permission to deposit"
		)

		await token.deposit(
			bob,
			web3.eth.abi.encodeParameter("uint256", AMOUNT_1),
			{ from: chainMgr }
		)

		await expectedRevert(
			token.withdraw(AMOUNT_1),
			"SuperfluidToken: burn amount exceeds balance"
		)

		await token.withdraw(AMOUNT_1, { from: bob })

		await expectedRevert(
			token.updateChildChainManager(bob),
			"MBPSuperToken: only governance allowed"
		)
	})

	it("#3 bridge interface correct balance changes", async () => {
		assert.equal(
			(await token.balanceOf(bob)).toString(),
			toWad(0).toString()
		)
		const r1 = await token.deposit(
			bob,
			web3.eth.abi.encodeParameter("uint256", AMOUNT_1),
			{ from: chainMgr }
		)
		await expectEvent(r1, "Transfer", {
			from: ZERO_ADDRESS,
			to: bob,
			value: AMOUNT_1
		})
		assert.equal(
			(await token.balanceOf(bob)).toString(),
			AMOUNT_1.toString()
		)

		await token.deposit(
			bob,
			web3.eth.abi.encodeParameter("uint256", AMOUNT_2),
			{ from: chainMgr }
		)
		assert.equal(
			(await token.balanceOf(bob)).toString(),
			AMOUNT_1.add(AMOUNT_2).toString()
		)
		assert.equal(
			(await token.balanceOf(bob)).toString(),
			AMOUNT_1.add(AMOUNT_2).toString()
		)

		await token.withdraw(AMOUNT_1, { from: bob })
		assert.equal(
			(await token.balanceOf(bob)).toString(),
			AMOUNT_2.toString()
		)
		assert.equal(
			(await token.totalSupply()).toString(),
			AMOUNT_2.toString()
		)
	})
})
