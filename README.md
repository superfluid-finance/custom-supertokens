# Custom Super Tokens

This repository shows how to implement custom SuperTokens.

More examples coming soon.

## Setup

To set up the repo for development, clone this repo and install dependencies:

```bash
git clone https://github.com/superfluid-finance/custom-supertokens@v2
cd custom-supertokens
yarn install
```

## Deployment

First, make sure to have up to date binaries:

```bash
yarn build
```

In order to deploy an instance of a Custom Super Token, you can use the included truffe deploy script with the needed ENV vars set:

```bash
CONTRACT=<contract_name> CTOR_ARGS=<args...> INIT_ARGS=<args...> npx truffle exec --network <network> scripts/deploy.js
```

where `CTOR_ARGS` are the arguments provided to the constructor of the proxy contract (empty / not needed in most cases) and `INIT_ARGS` are the arguments provided to the `initialize` method (excluding the first argument `factory` which is added by the script).

Example invocation for deploying an instance of `PureSuperToken` with the name "my token", symbol "MTK"
and a total supply of 10 tokens (value provided in wei) minted to the receiver 0x736e4ed1d4467de872fc08d024fbbb71ed470970

```bash
RPC=... MNEMONIC=... CONTRACT=PureSuperTokenProxy INIT_ARGS="my token","MTK","0x736e4ed1d4467de872fc08d024fbbb71ed470970",10000000000000000000 npx truffle exec --network any scripts/deploy.js
```

In order to figure out which `INIT_ARGS` are needed, check the contract source.

env vars can also be provided via an env file `.env`.

### Verification

You can verify contracts deployed to public networks on etherscan-compatible explorers.

First, you have to provide an API key for the explorer to verify with. See `.env.template` for the relevant ENV vars.

With the API key set, you can trigger verification like this:

```bash
RPC=... npx truffle run --network <network> verify <contract_name>@<address> --custom-proxy <contract_name>
```

Example invocation for verifying an instance of `PureSuperTokenProxy` deployed at `0x5A54F0a964AbBbD68f395E8Cc1Ba50f433d443e2`:

```bash
RPC=... npx truffle run --network any verify PureSuperTokenProxy@0x5A54F0a964AbBbD68f395E8Cc1Ba50f433d443e2
```

If verification succeeded (contract source code visible on that page), you may still need to manually trigger the proxy detection in order to enable the full SuperToken interface in the Explorer (and not just the proxy interface). In order to achieve that, click "More options", then "Is this a proxy?", in the next page "Verify", in the next popup "Save".
![image](https://user-images.githubusercontent.com/5479136/228034548-552044dc-5417-44ad-ae95-144e26c99c5e.png)

After doing that and heading back to the contract page, you should get additional tabs "Read as Proxy" and "Write as Proxy" providing the full SuperToken interface.
