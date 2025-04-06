# cronos-node-docker

Docker compose for Cronos Node.

Meant to be used with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for traefik
and Prometheus remote write; use `:ext-network.yml` in `COMPOSE_FILE` inside `.env` in that case.

## Quick setup

Run `cp default.env .env`, then `nano .env`, and update values like MONIKER, NETWORK, and SNAPSHOT.

If you want the consensus node RPC ports exposed locally, use `rpc-shared.yml` in `COMPOSE_FILE` inside `.env`.

- `./cronosd install` brings in docker-ce, if you don't have Docker installed already.
- `docker compose run --rm create-validator-keys` creates the consensus/validator node keys
- `docker compose run --rm create-operator-wallet` creates the operator wallet used to register the validator
- `docker compose run --rm create-bls-key` creates the BLS key using the priv_validator_key.json and the operator wallet.
- `docker compose run --rm import-validator-keys` imports the generated consensus/validator + bls keys into the docker volume
- `./cronosd up`

To update the software, run `./cronosd update` and then `./cronosd up`

## consensus

### Validator Key Generation

Run `docker compose run --rm create-validator-keys`

It is meant to be executed only once, it has no sanity checks and creates the `priv_validator_key.json` and `priv_validator_state.json` files inside the `keys/consensus/` folder.

Remember to backup those files if you're running a validator.

You can also export the keys from the docker volume, into the `keys/consensus/` folder by running: `docker compose run --rm export-validator-keys`.

### Operator Wallet Creation

An operator wallet is needed for staking operations. We provide a simple command to generate it, so it can be done in an air-gapped environment. It is meant to be executed only once, it has no sanity checks. It creates the operator wallet and stores the result in the `keys/operator/` folder.

Make sure to backup the `keys/operator/$MONIKER.backup` file, it is the only way to recover the wallet.

Run `docker compose run --rm create-operator-wallet`

### Register Validator

This assumes an operator wallet `keys/operator/$MONIKER.info` is present, and the `priv_validator_key.json` is present in the `keys/consensus/` folder.

`docker compose run --rm register-validator`

### CLI

An image with the `cronosd` binary is also avilable, e.g:

- `docker compose run --rm cli tendermint show-validator`
- `docker compose run --rm cli query bank balances bbn1q5u89k4w0tj7nxvmp6dhz3yaflw2cx9epv3g5x --node http://cronos:26657/`
## Version

Cronos Node Docker uses a semver scheme.

This is cronos-node-docker v1.0.0
