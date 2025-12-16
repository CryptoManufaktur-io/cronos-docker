#!/usr/bin/env bash
set -euo pipefail

# Initialization for graceful shutdown
STOPPED=false
REQUIRED_VARS=("MONIKER" "NETWORK" "CL_P2P_PORT" "CL_RPC_PORT")
for var in "${REQUIRED_VARS[@]}"; do
  if [ -z "${!var:-}" ]; then
    echo "Error: Environment variable $var is not set!" >&2
    exit 1
  fi
done

# Trap SIGTERM and SIGINT so the script can exit quickly if requested.
# Adjust the pkill command to target cronosd.
trap 'STOPPED=true; echo "Stopping services..."; pkill -SIGTERM cronosd' SIGTERM SIGINT

if [[ ! -f /cosmos/.initialized ]]; then
  echo "Initializing!"

  echo "Running init..."
  cronosd init "$MONIKER" --chain-id "$NETWORK" --home /cosmos --overwrite

  echo "Downloading genesis..."
  wget https://raw.githubusercontent.com/crypto-org-chain/cronos-mainnet/master/cronosmainnet_25-1/genesis.json -O /cosmos/config/genesis.json

  echo "Downloading seeds..."
  SEEDS="0d5cf1394a1cfde28dc8f023567222abc0f47534@cronos-seed-0.crypto.org:26656,3032073adc06d710dd512240281637c1bd0c8a7b@cronos-seed-1.crypto.org:26656,04f43116b4c6c70054d9c2b7485383df5b1ed1da@cronos-seed-2.crypto.org:26656,337377dcda43d79c537d2c4d93ad3b698ce9452e@bd-cronos-mainnet-seed-node-01.bdnodes.net:26656"
  dasel put -f /cosmos/config/config.toml -v "$SEEDS" p2p.seeds

  # If a stop signal was received, exit early.
  [[ "$STOPPED" == "true" ]] && { echo "Shutdown signal received, exiting early"; exit 0; }

  if [ -n "${SNAPSHOT:-}" ]; then
    echo "Downloading snapshot with aria2c..."

    # Download the snapshot using high concurrency.
    aria2c -x5 -s5 -j1 --allow-overwrite=true --console-log-level=notice --summary-interval=5 -d /cosmos -o snapshot.lz4 "$SNAPSHOT"


    if [ ! -f "/cosmos/snapshot.lz4" ]; then
      echo "Error: Snapshot file not found after download!"
      exit 1
    fi

    echo "Extracting snapshot..."
    # Determine the size of the snapshot file for progress tracking.
    SNAPSHOT_SIZE=$(stat -c %s /cosmos/snapshot.lz4)
    # Use pv to show extraction progress while decompressing with lz4 and extracting via tar.
    pv -s "$SNAPSHOT_SIZE" /cosmos/snapshot.lz4 | lz4 -c -d - | tar --exclude='data/priv_validator_state.json' -x -C /cosmos

    echo "Snapshot successfully extracted!"
    rm -f /cosmos/snapshot.lz4  # Clean up the snapshot file

    [[ "$STOPPED" == "true" ]] && { echo "Shutdown signal received during snapshot extraction, exiting early"; exit 0; }
  else
    echo "No snapshot URL defined."
  fi

  touch /cosmos/.initialized
else
  echo "Already initialized!"
fi

echo "Updating config..."

# Get public IP address, with fallbacks.
__public_ip=$(curl -s ifconfig.me || curl -s http://checkip.amazonaws.com || echo "UNKNOWN")
[[ "$STOPPED" == "true" ]] && { echo "Shutdown signal received before updating config, exiting early"; exit 0; }
echo "Public ip: ${__public_ip}"

# Update various configuration parameters.
dasel put -f /cosmos/config/config.toml -v "10s" consensus.timeout_commit
dasel put -f /cosmos/config/config.toml -v "${__public_ip}:${CL_P2P_PORT}" p2p.external_address
dasel put -f /cosmos/config/config.toml -v "tcp://0.0.0.0:${CL_P2P_PORT}" p2p.laddr
dasel put -f /cosmos/config/config.toml -v "tcp://0.0.0.0:${CL_RPC_PORT}" rpc.laddr
dasel put -f /cosmos/config/config.toml -v "$MONIKER" moniker
dasel put -f /cosmos/config/config.toml -v true prometheus
dasel put -f /cosmos/config/config.toml -v "$LOG_LEVEL" log_level
dasel put -f /cosmos/config/config.toml -v true instrumentation.prometheus
dasel put -f /cosmos/config/app.toml -v "0.0.0.0:${RPC_PORT}" json-rpc.address
dasel put -f /cosmos/config/app.toml -v "0.0.0.0:${WS_PORT}" json-rpc.ws-address
dasel put -f /cosmos/config/app.toml -v "0.0.0.0:${CL_GRPC_PORT}" grpc.address
dasel put -f /cosmos/config/app.toml -v true grpc.enable
dasel put -f /cosmos/config/app.toml -v "$MIN_GAS_PRICE" "minimum-gas-prices"
dasel put -f /cosmos/config/app.toml -v 0 "iavl-cache-size"
dasel put -f /cosmos/config/app.toml -v "true" "iavl-disable-fastnode"
dasel put -f /cosmos/config/app.toml -v "signet" "btc-config.network"
dasel put -f /cosmos/config/app.toml -v 0  'mempool."max-txs"'
dasel put -f /cosmos/config/app.toml -v 10 'mempool.feebump'
dasel put -f /cosmos/config/app.toml -v false 'cronos.disable-tx-replacement'
dasel put -f /cosmos/config/app.toml -v true  'cronos.disable-optimistic-execution'
dasel put -f /cosmos/config/client.toml -v "tcp://localhost:${CL_RPC_PORT}" node

# Word splitting is desired for the command line parameters.
# shellcheck disable=SC2086
exec "$@" ${EXTRA_FLAGS}
