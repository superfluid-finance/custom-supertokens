const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")
const { fastForward } = require("./util")
const BurnableSuperToken = artifacts.require("BurnableSuperToken")

contract("BurnableSuperToken", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	let superTokenFactoryAddress

	// Functions on the proxy contract (BurnableSuperToken.sol) are called with `burnableSuperToken.proxy`
	// Functions on the implementation contract (SuperToken.sol) are called with `burnableSuperToken.impl`
	let impl
	let proxy
	let burnableSuperToken

	const INIT_SUPPLY = toWad(1000000)

	const [admin, alice, bob, carol] = accounts.slice(0, 4)

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

		superTokenFactoryAddress = await sf.host.getSuperTokenFactory.call()

		// proxy (custom) logic
		proxy = await web3tx(
			BurnableSuperToken.new,
			"BurnableSuperToken.new by alice"
		)({ from: alice })

		await web3tx(
			proxy.initialize,
			`BurnableSuperToken.initialize by alice with supply of ${INIT_SUPPLY}`
		)(
			"Super Juicy Token",
			"SJT",
			superTokenFactoryAddress,
			INIT_SUPPLY,
			alice,
			"0x"
		)

		// get impl functions from the framework
		const { INativeSuperToken } = sf.contracts
		impl = await INativeSuperToken.at(proxy.address)

		// adding `address` to keep things simple
		burnableSuperToken = { impl, proxy, address: proxy.address }
	})

	it("alice cannot initialize twice", async () => {
		try {
			await web3tx(
				burnableSuperToken.proxy.initialize,
				"alice tries to initialize a second time"
			)(
				"Not Super Juicy Token",
				"NSJT",
				superTokenFactoryAddress,
				INIT_SUPPLY,
				alice
			)
			throw null
		} catch (error) {
			assert(error, "Expected Revert")
		}
	})

	it("alice can burn", async () => {
		await web3tx(burnableSuperToken.proxy.burn, "alice burns all tokens")(
			INIT_SUPPLY,
			"0x",
			{ from: alice }
		)

		assert.equal(
			(await burnableSuperToken.impl.balanceOf.call(alice)).toString(),
			"0"
		)
	})

	it("bob can burn", async () => {
		await web3tx(
			burnableSuperToken.impl.send,
			"alice sends bob all tokens"
		)(bob, INIT_SUPPLY, "0x", { from: alice })

		await web3tx(burnableSuperToken.proxy.burn, "bob burns all tokens")(
			INIT_SUPPLY,
			"0x",
			{ from: bob }
		)

		assert.equal(
			(await burnableSuperToken.impl.balanceOf.call(alice)).toString(),
			"0"
		)

		assert.equal(
			(await burnableSuperToken.impl.balanceOf.call(bob)).toString(),
			"0"
		)
	})

	it("tokens can be streamed", async () => {
		await web3tx(
			burnableSuperToken.impl.transfer,
			"alice transfers 500_000 SJT to bob"
		)(bob, toWad("500000"), { from: alice })

		const flowRate = "1000000000000000" // 0.001

		await web3tx(
			sf.host.callAgreement,
			"bob starts a 0.001 SJT per second flow to carol"
		)(
			cfa.address,
			cfa.contract.methods
				.createFlow(burnableSuperToken.address, carol, flowRate, "0x")
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		assert.equal(
			(
				await cfa.getFlow.call(burnableSuperToken.address, bob, carol)
			).flowRate.toString(),
			flowRate
		)

		// FAST FORWARD 1000 SECONDS
		await fastForward(1000)

		await web3tx(sf.host.callAgreement, "bob stops flow to carol")(
			cfa.address,
			cfa.contract.methods
				.deleteFlow(burnableSuperToken.address, bob, carol, "0x")
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		assert.equal(
			(
				await cfa.getFlow.call(burnableSuperToken.address, bob, carol)
			).flowRate.toString(),
			"0"
		)

		// The passage of time seems to be a little unpredictable in the
		// testing environment, but this at least ensures the balances are
		// not what they once were. :)
		assert.notEqual(
			(await burnableSuperToken.impl.balanceOf.call(bob)).toString(),
			toWad("500000")
		)

		assert.notEqual(
			(await burnableSuperToken.impl.balanceOf.call(carol)).toString(),
			"0"
		)
	})
})
