const { web3tx, toWad } = require("@decentral.ee/web3-helpers")
const deployFramework = require("@superfluid-finance/ethereum-contracts/scripts/deploy-framework")
const { builtTruffleContractLoader } = require('@superfluid-finance/ethereum-contracts/scripts/libs/common')
const SuperfluidSDK = require("@superfluid-finance/js-sdk")

const MintableSuperToken = artifacts.require("MintableSuperToken")

contract("MintableSuperToken", accounts => {
	const errorHandler = error => {
		if (error) throw error
	}

	let sf
	let superTokenFactory
    // MintableSuperToken methods are called either by proxy
    // or on the contract directly.
    // proxy methods exist on the logic contract (ISuperToken)
    // native methods exist on the proxy contract (MintableSuperToken)
    let proxy
    let native
    let mintableSuperToken

	const [admin, alice, bob, carol] = accounts.slice(0, 4)

	before(
		async () => await deployFramework(errorHandler, { web3, from: admin })
	)

	beforeEach(async () => {
		sf = new SuperfluidSDK.Framework({
            web3,
            version: "test",
            additionalContracts: ["INativeSuperToken"],
            contractLoader: builtTruffleContractLoader,
        })
		await sf.initialize()

		superTokenFactory = await sf.contracts.ISuperTokenFactory.at(
			await sf.host.getSuperTokenFactory.call()
		)

        // having 2 transactions to init is fine for testing BUT
        // these should be batched in the same transaction
        // to avoid front running!!!

        // native methods initialized
		native = await web3tx(
			MintableSuperToken.new,
			"MintableSuperToken.new by alice"
		)(alice, { from: alice })

		await web3tx(
			superTokenFactory.initializeCustomSuperToken,
			"MintableSuperToken contract upgrade by alice"
		)(native.address, { from: alice })

        await web3tx(
            native.initialize,
            "MintableSuperToken.initialize by alice with zero initial supply"
        )(
            "Super Juicy Token",
            "SJT",
            alice,
            0,
            "0x"
        )

        const { INativeSuperToken } = sf.contracts
        proxy = await INativeSuperToken.at(native.address)

        mintableSuperToken = { native, proxy }
	})

	it("mints to anyone from alice", async() => {
        await web3tx(
            mintableSuperToken.native.mint,
            "alice mints 100 SJT to theirself"
        )(
            alice,
            toWad(100),
            "0x",
            { from: alice }
        )

        assert.equal(
            (await mintableSuperToken.proxy.balanceOf.call(alice)).toString(),
            toWad(100)
        )
    })
})
