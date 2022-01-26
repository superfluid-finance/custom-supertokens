const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")

const CappedSuperToken = artifacts.require("CappedSuperToken")

contract("CappedSuperToken", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	let superTokenFactory

	// CappedSuperToken methods are called either by proxy
	// or on the contract directly.
	// proxy methods exist on the logic contract (ISuperToken)
	// native methods exist on the proxy contract (CappedSuperToken)
	let proxy
	let native
	let cappedSuperToken

	const MAX_SUPPLY = toWad(1000000)

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
			CappedSuperToken.new,
			"CappedSuperToken.new by alice"
		)({ from: alice })

		await web3tx(
			superTokenFactory.initializeCustomSuperToken,
			"CappedSuperToken contract upgrade by alice"
		)(native.address, { from: alice })

		await web3tx(
			native.initialize,
			"CappedSuperToken.initialize by alice max supply of 1_000_000"
		)("Super Juicy Token", "SJT", MAX_SUPPLY, { from: alice })

		// get proxy methods from a template
		const { INativeSuperToken } = sf.contracts
		proxy = await INativeSuperToken.at(native.address)

		// store native and proxy methods in the same object
		cappedSuperToken = { native, proxy }
	})

	it("alice cannot initialize twice", async () => {
		try {
			await web3tx(
				cappedSuperToken.native.initialize,
				"alice tries to initializes a second time"
			)("Not Super Juicy Token", "NSJT", MAX_SUPPLY, alice)
			throw null
		} catch (error) {
			assert(error, "Expected revert")
		}
	})

	it("alice mints to anyone", async () => {
		// alice mints to self
		await web3tx(
			cappedSuperToken.native.mint,
			"alice mints 100 SJT to self"
		)(alice, toWad(100), "0x", { from: alice })

		assert.equal(
			(await cappedSuperToken.proxy.balanceOf.call(alice)).toString(),
			toWad(100)
		)

		assert.equal(
			(await cappedSuperToken.proxy.totalSupply.call()).toString(),
			toWad(100)
		)

		// alice mints to bob
		await web3tx(
			cappedSuperToken.native.mint,
			"alice mints 100 SJT to bob"
		)(bob, toWad(100), "0x", { from: alice })

		assert.equal(
			(await cappedSuperToken.proxy.balanceOf.call(alice)).toString(),
			toWad(100)
		)

		assert.equal(
			(await cappedSuperToken.proxy.balanceOf.call(bob)).toString(),
			toWad(100)
		)

		assert.equal(
			(await cappedSuperToken.proxy.totalSupply.call()).toString(),
			toWad(200)
		)
	})

	it("only alice can mint", async () => {
		// alice mints to self
		await web3tx(
			cappedSuperToken.native.mint,
			"alice mints 100 SJT to self"
		)(alice, toWad(100), "0x", { from: alice })

		assert.equal(
			(await cappedSuperToken.proxy.balanceOf.call(alice)).toString(),
			toWad(100)
		)

		assert.equal(
			(await cappedSuperToken.proxy.totalSupply.call()).toString(),
			toWad(100)
		)

		// bob tries to mint to self
		try {
			await web3tx(
				cappedSuperToken.native.mint,
				"bob tries to mint 100 SJT to self"
			)(bob, toWad(100), "0x", { from: bob })
			// always throws to catch, but assert() requires a non-nullish error
			throw null
		} catch (error) {
			assert(error, "Expected Revert")
		}

		assert.equal(
			(await cappedSuperToken.proxy.balanceOf.call(alice)).toString(),
			toWad(100)
		)

		assert.equal(
			(await cappedSuperToken.proxy.balanceOf.call(bob)).toString(),
			"0"
		)

		assert.equal(
			(await cappedSuperToken.proxy.totalSupply.call()).toString(),
			toWad(100)
		)
	})

	it("alice cannot mint beyond supply cap", async () => {
		try {
			await web3tx(
				cappedSuperToken.native.mint,
				"alice tries to mint 1_000_001 SJT to self"
			)(alice, toWad("1000001"), "0x", { from: alice })
			throw null
		} catch (error) {
			assert(error, "Expected revert")
		}

		await web3tx(
			cappedSuperToken.native.mint,
			"alice mints 500_000 SJT to self"
		)(alice, toWad("500000"), "0x", { from: alice })

		try {
			await web3tx(
				cappedSuperToken.native.mint,
				"alice tries to mint another 500_001 SJT to self"
			)(alice, toWad("500001"), "0x", { from: alice })
			throw null
		} catch (error) {
			assert(error, "Expected revert")
		}
	})

	it("alice transfers mint permission to bob", async () => {
		assert.equal(await cappedSuperToken.native.owner.call(), alice)

		await web3tx(
			cappedSuperToken.native.transferOwnership,
			"alice transfers minting permission to bob"
		)(bob, { from: alice })

		assert.equal(await cappedSuperToken.native.owner.call(), bob)
	})

	it("bob may not transfer mint permission if not minter", async () => {
		assert.equal(await cappedSuperToken.native.owner.call(), alice)

		try {
			await web3tx(
				cappedSuperToken.native.transferOwnership,
				"bob tries to transfer minting permission to self"
			)(bob, { from: bob })
		} catch (error) {
			assert(error, "Expected revert")
		}

		assert.equal(await cappedSuperToken.native.owner.call(), alice)
	})

	it("general super token functionality", async () => {
		await web3tx(
			cappedSuperToken.native.mint,
			"alice mints max supply of SJT to self"
		)(alice, MAX_SUPPLY, "0x", { from: alice })

		await web3tx(
			cappedSuperToken.proxy.transfer,
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
					cappedSuperToken.native.address,
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
					cappedSuperToken.native.address,
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
				.deleteFlow(cappedSuperToken.native.address, bob, carol, "0x")
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		assert.equal(
			(
				await cfa.getFlow.call(
					cappedSuperToken.native.address,
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
			(await cappedSuperToken.proxy.balanceOf.call(bob)).toString(),
			toWad("500000")
		)

		assert.notEqual(
			(await cappedSuperToken.proxy.balanceOf.call(carol)).toString(),
			"0"
		)
	})
})
