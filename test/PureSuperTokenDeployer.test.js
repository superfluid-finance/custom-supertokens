const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const {
	builtTruffleContractLoader
} = require("@superfluid-finance/ethereum-contracts/scripts/libs/common")
const SuperfluidSDK = require("@superfluid-finance/js-sdk")
const PureSuperTokenDeployer = artifacts.require("PureSuperTokenDeployer")

contract("PureSuperTokenDeployer", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let cfa
	let superTokenFactoryAddress

	// deployer contract
	let pureSuperTokenDeployer

	const INIT_SUPPLY = toWad(1000000)

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

		cfa = sf.agreements.cfa

		superTokenFactoryAddress = await sf.host.getSuperTokenFactory.call()

		pureSuperTokenDeployer = await web3tx(
			PureSuperTokenDeployer.new,
			"alice deploys new deployment contract"
		)(superTokenFactoryAddress)
	})

	it("can deploy super token", async () => {
		const tx = await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"alice deploys pure super token"
		)("Super Juicy Token", "SJT", alice, INIT_SUPPLY, { from: alice })
		const address = tx.logs[0].args.newSuperToken
		const superToken = await sf.contracts.ISuperToken.at(address)

		assert.equal(
			(await superToken.balanceOf.call(alice)).toString(),
			INIT_SUPPLY
		)
	})

	it("can not deploy twice", async () => {
		await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"alice deploys pure super token"
		)("Super Juicy Token", "SJT", alice, INIT_SUPPLY, { from: alice })

		try {
			await web3tx(
				pureSuperTokenDeployer.deploySuperToken,
				"alice deploys pure super token again"
			)("Super Juicy Token", "SJT", alice, "1", { from: alice })
			throw null
		} catch (error) {
			assert(error, "Expected Revert")
		}
	})

	it("can deploy same name and symbol from different senders", async () => {
		const tx0 = await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"alice deploys pure super token"
		)("Super Juicy Token", "SJT", alice, INIT_SUPPLY, { from: alice })

		const tx1 = await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"bob deploys pure super token"
		)("Super Juicy Token", "SJT", alice, INIT_SUPPLY, { from: bob })

		// this is kinda redundant since create2 throws on creating an existing
		// address but hey, why not just make the assertion anyway
		assert(tx0.logs[0].args.newSuperToken != tx1.logs[0].args.newSuperToken)
	})

	it("can not create a hashing collision", async () => {
		// A hash collision is still feasible, but not in any realistic case,
		// and to no benefit of an attacker. Since the packed encoding is of
		// (name . msgSender . symbol), one would need a name and/or symbol at
		// least 20 bytes long to expose a hash collision.

		await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"alice deploys pure super token"
		)("Super Juicy Token", "SJT", alice, INIT_SUPPLY, { from: alice })

		await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"alice deploys pure super token"
		)(
			"Super Juicy Toke", // shift `n` to symbol
			"nSJT",
			alice,
			INIT_SUPPLY,
			{ from: alice }
		)
	})

	it("can call agreement with super token", async () => {
		const tx = await web3tx(
			pureSuperTokenDeployer.deploySuperToken,
			"alice deploys pure super token"
		)("Super Juicy Token", "SJT", alice, INIT_SUPPLY, { from: alice })
		const address = tx.logs[0].args.newSuperToken

		const flowRate = "1000000000000000" // 0.001

		await web3tx(sf.host.callAgreement, "alice creates a flow to bob")(
			cfa.address,
			cfa.contract.methods
				.createFlow(address, bob, flowRate, "0x")
				.encodeABI(),
			"0x",
			{ from: alice }
		)

		assert.equal(
			(await cfa.getFlow.call(address, alice, bob)).flowRate.toString(),
			flowRate
		)
	})
})
