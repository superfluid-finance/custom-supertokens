const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")

const BurnableSuperToken = artifacts.require("BurnableSuperToken")

contract("BurnableSuperToken", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	let superTokenFactory

	// BurnableSuperToken methods are called either by proxy
	// or on the contract directly.
	// proxy methods exist on the logic contract (ISuperToken)
	// native methods exist on the proxy contract (BurnableSuperToken)
	let proxy
	let native
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

		superTokenFactory = await sf.contracts.ISuperTokenFactory.at(
			await sf.host.getSuperTokenFactory.call()
		)

		// having 2 transactions to init is fine for testing BUT
		// these should be batched in the same transaction
		// to avoid front running!!!

		// native methods initialized
		native = await web3tx(
			BurnableSuperToken.new,
			"BurnableSuperToken.new by alice"
		)({ from: alice })

		await web3tx(
			superTokenFactory.initializeCustomSuperToken,
			"BurnableSuperToken contract upgrade by alice"
		)(native.address, { from: alice })

		await web3tx(
			native.initialize,
			"BurnableSuperToken.initialize by alice with supply of 1_000_000"
		)("Super Juicy Token", "SJT", INIT_SUPPLY, alice, "0x")

		// get proxy methods from a template
		const { INativeSuperToken } = sf.contracts
		proxy = await INativeSuperToken.at(native.address)

		// store native and proxy methods in the same object
		burnableSuperToken = { native, proxy }
	})

	it("alice can burn", async () => {
		await web3tx(burnableSuperToken.native.burn, "alice burns all tokens")(
			INIT_SUPPLY,
			"0x",
			{ from: alice }
		)

		assert.equal(
			(await burnableSuperToken.proxy.balanceOf.call(alice)).toString(),
			"0"
		)
	})

	it("bob can burn", async () => {
		await web3tx(
			burnableSuperToken.proxy.send,
			"alice sends bob all tokens"
		)(bob, INIT_SUPPLY, "0x", { from: alice })

		await web3tx(burnableSuperToken.native.burn, "bob burns all tokens")(
			INIT_SUPPLY,
			"0x",
			{ from: bob }
		)

		assert.equal(
			(await burnableSuperToken.proxy.balanceOf.call(alice)).toString(),
			"0"
		)

		assert.equal(
			(await burnableSuperToken.proxy.balanceOf.call(bob)).toString(),
			"0"
		)
	})

	it("tokens can be streamed", async () => {
		await web3tx(
			burnableSuperToken.proxy.transfer,
			"alice transfers 500_000 SJT to bob"
		)(bob, toWad("500000"), { from: alice })

		const flowRate = "1000000000000000" // 0.001 tokens per second

		await web3tx(
			sf.host.callAgreement,
			"bob starts a 0.001 SJT per second flow to carol"
		)(
			cfa.address,
			cfa.contract.methods
				.createFlow(
					burnableSuperToken.native.address,
					carol,
					flowRate,
					"0x"
				)
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		assert.equal(
			(
				await cfa.getFlow.call(
					burnableSuperToken.native.address,
					bob,
					carol
				)
			).flowRate.toString(),
			flowRate
		)

		// FAST FORWARD 1000 SECONDS
		console.log(`Fast forwarding 1000 seconds`)
		await web3.currentProvider.send(
			{
				jsonrpc: "2.0",
				method: "evm_increaseTime",
				params: [999],
				id: 0
			},
			() => {}
		)
		await web3.currentProvider.send(
			{
				jsonrpc: "2.0",
				method: "evm_mine",
				params: [],
				id: 0
			},
			() => {}
		)

		await web3tx(sf.host.callAgreement, "bob stops flow to carol")(
			cfa.address,
			cfa.contract.methods
				.deleteFlow(burnableSuperToken.native.address, bob, carol, "0x")
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		assert.equal(
			(
				await cfa.getFlow.call(
					burnableSuperToken.native.address,
					bob,
					carol
				)
			).flowRate.toString(),
			"0"
		)

		// The passage of time seems to be a little unpredictable in the
		// testing environment, but this at least ensures the balances are
		// not what they once were. :)
		assert.notEqual(
			(await burnableSuperToken.proxy.balanceOf.call(bob)).toString(),
			toWad("500000")
		)

		assert.notEqual(
			(await burnableSuperToken.proxy.balanceOf.call(carol)).toString(),
			"0"
		)
	})
})
