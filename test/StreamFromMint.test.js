const { web3tx, toWad, BN, toBN } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")
const { fastForward } = require("./util")

const StreamFromMint = artifacts.require("StreamFromMint")

contract("StreamFromMint", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	let superTokenFactory

	let native
	let streamFromMint

	const INIT_MINT_FLOW_RATE = toWad(200)

	const [admin, alice, bob] = accounts.slice(0, 4)

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

		native = await web3tx(
			StreamFromMint.new,
			"StreamFromMint.new by alice"
		)({ from: alice })

		await web3tx(
			superTokenFactory.initializeCustomSuperToken,
			"StreamFromMint contract upgrade by alice"
		)(native.address, { from: alice })

		await web3tx(
			native.initialize,
			"StreamFromMint.initialize by alice max supply of 1_000_000"
		)("Super Juicy Token", "SJT", cfa.address, alice, INIT_MINT_FLOW_RATE, {
			from: alice
		})

		// get proxy methods from a template
		const { INativeSuperToken } = sf.contracts
		proxy = await INativeSuperToken.at(native.address)

		// store native and proxy methods in the same object
		streamFromMint = { native, proxy }
	})

	it("flow is legit", async () => {
		assert.equal(
			(await streamFromMint.native.totalSupply.call()).toString(),
			"0"
		)
		assert.equal(
			(
				await cfa.getFlow.call(
					streamFromMint.native.address,
					streamFromMint.native.address,
					alice
				)
			).flowRate.toString(),
			INIT_MINT_FLOW_RATE
		)

		fastForward(10000)

		assert.notEqual(
			(await streamFromMint.native.totalSupply.call()).toString(),
			"0"
		)
	})
})
