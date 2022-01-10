const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")

const MultiMintToken = artifacts.require("MultiMintToken")

contract("MulitMintToken", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let ida
	let superTokenFactory

	// MultiMintToken methods are called either by proxy
	// or on the contract directly.
	// proxy methods exist on the logic contract (ISuperToken)
	// native methods exist on the proxy contract (MultiMintToken)
	let proxy
	let native
	let multiMintToken

	const INDEX_ID = 0 // for readability

	const [admin, alice, bob, _] = accounts.slice(0, 4)

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

		ida = sf.agreements.ida

		superTokenFactory = await sf.contracts.ISuperTokenFactory.at(
			await sf.host.getSuperTokenFactory.call()
		)

		// having 2 transactions to init is fine for testing BUT
		// these should be batched in the same transaction
		// to avoid front running!!!

		// native methods initialized
		native = await web3tx(
			MultiMintToken.new,
			"MultiMintToken.new by alice"
		)({ from: alice })

		await web3tx(
			superTokenFactory.initializeCustomSuperToken,
			"MultiMintToken contract upgrade by alice"
		)(native.address, { from: alice })

		await web3tx(
			native.initialize,
			"MultiMintToken.initialize by alice with 100 token mint every day"
		)(
			"Super Juicy Token",
			"SJT",
			ida.address,
			alice, // share issuer
			86400, // mint interval
			toWad(100), // mint amount
			{ from: alice }
		)

		const { INativeSuperToken } = sf.contracts

		proxy = await INativeSuperToken.at(native.address)

		multiMintToken = { native, proxy }
	})

	it("alice can distribute to bob", async () => {
		let index
		let subscription

		await web3tx(
			multiMintToken.native.issueShare,
			"alice issues 1 share to bob"
		)(bob, 1, { from: alice })

		// check index and subscription
		index = await ida.getIndex.call(
			multiMintToken.native.address,
			multiMintToken.native.address,
			INDEX_ID
		)
		assert(index.exist)
		assert.equal(index.indexValue, "0")

		subscription = await ida.getSubscription.call(
			multiMintToken.native.address,
			multiMintToken.native.address,
			INDEX_ID,
			bob
		)
		assert(subscription.exist)
		assert.equal(subscription.units, 1)

		await web3tx(sf.host.callAgreement, "bob approves subscription")(
			ida.address,
			ida.contract.methods
				.approveSubscription(
					multiMintToken.native.address,
					multiMintToken.native.address,
					INDEX_ID,
					"0x"
				)
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		subscription = await ida.getSubscription.call(
			multiMintToken.native.address,
			multiMintToken.native.address,
			INDEX_ID,
			bob
		)
		assert(subscription.approved)

		await web3tx(multiMintToken.native.mint, "alice mints")()

		// check index
		index = await ida.getIndex.call(
			multiMintToken.native.address,
			multiMintToken.native.address,
			INDEX_ID
		)
		assert.equal(index.indexValue.toString(), toWad(100))
	})
})
