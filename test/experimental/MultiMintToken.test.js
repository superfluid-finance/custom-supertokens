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
	let superTokenFactoryAddress

	// Functions on the proxy contract (MultiMintToken.sol) are called with `multiMintToken.proxy`
	// Functions on the implementation contract (SuperToken.sol) are called with `multiMintToken.impl`
	let impl
	let proxy
	let multiMintToken

	const INDEX_ID = 0 // for readability

	const [admin, alice, bob] = accounts.slice(0, 3)

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

		ida = sf.agreements.ida

		superTokenFactoryAddress = await sf.host.getSuperTokenFactory.call()

		// proxy (custom) logic
		proxy = await web3tx(
			MultiMintToken.new,
			"MultiMintToken.new by alice"
		)({ from: alice })

		await web3tx(
			proxy.initialize,
			"MultiMintToken.initialize by alice with 100 token mint every day"
		)(
			"Super Juicy Token",
			"SJT",
			superTokenFactoryAddress,
			ida.address,
			alice, // share issuer
			86400, // mint interval
			toWad(100), // mint amount
			{ from: alice }
		)

		const { ISuperToken } = sf.contracts

		impl = await ISuperToken.at(proxy.address)

		multiMintToken = { impl, proxy, address: proxy.address }
	})

	it("alice can distribute to bob", async () => {
		let index
		let subscription

		await web3tx(
			multiMintToken.proxy.issueShare,
			"alice issues 1 share to bob"
		)(bob, 1, { from: alice })

		// check index and subscription
		index = await ida.getIndex.call(
			multiMintToken.address,
			multiMintToken.address,
			INDEX_ID
		)
		assert(index.exist)
		assert.equal(index.indexValue, "0")

		subscription = await ida.getSubscription.call(
			multiMintToken.address,
			multiMintToken.address,
			INDEX_ID,
			bob
		)
		assert(subscription.exist)
		assert.equal(subscription.units, 1)

		await web3tx(sf.host.callAgreement, "bob approves subscription")(
			ida.address,
			ida.contract.methods
				.approveSubscription(
					multiMintToken.address,
					multiMintToken.address,
					INDEX_ID,
					"0x"
				)
				.encodeABI(),
			"0x",
			{ from: bob }
		)

		subscription = await ida.getSubscription.call(
			multiMintToken.address,
			multiMintToken.address,
			INDEX_ID,
			bob
		)
		assert(subscription.approved)

		await web3tx(multiMintToken.proxy.mint, "alice mints")()

		// check index
		index = await ida.getIndex.call(
			multiMintToken.address,
			multiMintToken.address,
			INDEX_ID
		)
		assert.equal(index.indexValue.toString(), toWad(100))
	})
})
