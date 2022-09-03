const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")
const { expectRevert } = require("@openzeppelin/test-helpers")
const MaticBridgedSuperToken = artifacts.require("MaticBridgedSuperToken")
const IMaticBridgedSuperToken = artifacts.require("IMaticBridgedSuperToken")
const ISuperTokenFactory = artifacts.require(
	"@superfluid-finance/ethereum-contracts/contracts/interfaces/superfluid/ISuperTokenFactory.sol"
)
const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000"
const AMOUNT_1 = toWad(3)
const AMOUNT_2 = toWad(5000)

contract("MaticBridgedSuperToken", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	let superTokenFactoryAddress
	let token
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
			contractLoader: builtTruffleContractLoader
		})

		await sf.initialize()
		cfa = sf.agreements.cfa
		superTokenFactoryAddress = await sf.host.getSuperTokenFactory.call()

		console.log("chainMgr: ", chainMgr)
		const proxy = await web3tx(
			MaticBridgedSuperToken.new,
			"MaticBridgedSuperToken (proxy) deploy"
		)(chainMgr)

		await web3tx(proxy.initialize, "MaticBridgedSuperToken.initialize")(
			"Matic Bridged Token",
			"MBT",
			superTokenFactoryAddress
		)

		// get Superfluid functions from the framework
		const { ISuperToken } = sf.contracts
		const impl = await ISuperToken.at(proxy.address)

		// composite of funcionality of the proxy and implementation contracts
		token = { impl, proxy, address: proxy.address }
	})

	it("#1 can initialize only once", async () => {
		await expectRevert.unspecified(
			token.proxy.initialize(
				"Hacked Matic Bridged Token",
				"HMBT",
				superTokenFactoryAddress
			)
		)
	})

	it("#2 bridge interface permissions", async () => {
		await expectRevert(
			token.proxy.deposit(
				bob,
				web3.eth.abi.encodeParameter("uint256", AMOUNT_1)
			),
			"MBPSuperToken: no permission to deposit"
		)

		await token.proxy.deposit(
			bob,
			web3.eth.abi.encodeParameter("uint256", AMOUNT_1),
			{ from: chainMgr }
		)

		await expectRevert(
			token.proxy.withdraw(AMOUNT_1),
			"SuperfluidToken: burn amount exceeds balance"
		)

		await token.proxy.withdraw(AMOUNT_1, { from: bob })

		await expectRevert(
			token.proxy.updateChildChainManager(bob),
			"MBPSuperToken: only governance allowed"
		)
	})

	it("#3 bridge interface correct balance changes", async () => {
		assert.equal(
			(await token.impl.balanceOf(bob)).toString(),
			toWad(0).toString()
		)
		const r1 = await token.proxy.deposit(
			bob,
			web3.eth.abi.encodeParameter("uint256", AMOUNT_1),
			{ from: chainMgr }
		)
		assert.equal(
			(await token.impl.balanceOf(bob)).toString(),
			AMOUNT_1.toString()
		)

		await token.proxy.deposit(
			bob,
			web3.eth.abi.encodeParameter("uint256", AMOUNT_2),
			{ from: chainMgr }
		)
		assert.equal(
			(await token.impl.balanceOf(bob)).toString(),
			AMOUNT_1.add(AMOUNT_2).toString()
		)
		assert.equal(
			(await token.impl.balanceOf(bob)).toString(),
			AMOUNT_1.add(AMOUNT_2).toString()
		)

		await token.proxy.withdraw(AMOUNT_1, { from: bob })
		assert.equal(
			(await token.impl.balanceOf(bob)).toString(),
			AMOUNT_2.toString()
		)
		assert.equal(
			(await token.impl.totalSupply()).toString(),
			AMOUNT_2.toString()
		)
	})
})
