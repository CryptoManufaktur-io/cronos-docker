# Cronos Node Docker

This repository provides Docker Compose configurations for running a Cronos RPC node.

It’s designed to work with [central-proxy-docker](https://github.com/CryptoManufaktur-io/central-proxy-docker) for Traefik and Prometheus remote write. If you need external network connectivity, include `:ext-network.yml` in your `COMPOSE_FILE` (as set in your `.env` file).

## Quick Setup

1. **Prepare your environment:**  
   Copy the default environment file and update your settings:
   ```bash
   cp default.env .env
   nano .env
   ```
   Update values such as `MONIKER`, `NETWORK`, and `SNAPSHOT`.

2. **Expose RPC Ports (Optional):**  
   If you want the node’s RPC ports exposed locally, include `rpc-shared.yml` in your `COMPOSE_FILE` within `.env`.

3. **Install Docker (if needed):**  
   Run:
   ```bash
   ./cronosd install
   ```
   This command installs Docker CE if it isn’t already installed.

4. **Start the Node:**  
   Bring up your Cronos RPC node by running:
   ```bash
   ./cronosd up
   ```

5. **Software Updates:**  
   To update the node software, run:
   ```bash
   ./cronosd update
   ./cronosd up
   ```

## Snapshot and Genesis Setup

When you first start the node, the container will:

- **Initialize the node:**  
  Run `cronosd init` with your specified `MONIKER` and `NETWORK`.
- **Download the genesis file:**  
  It retrieves the genesis file from the official Cronos mainnet repository.
- **Download seeds:**  
  The configuration is updated with a list of seed nodes.
- **Download and extract a snapshot (if provided):**  
  If the `SNAPSHOT` environment variable is set, the snapshot will be downloaded via `aria2c` and then extracted into the node’s data directory using a pipeline that displays progress.

## CLI Usage

A CLI image containing the `cronosd` binary is also available. For example:
- To display node status:
  ```bash
  docker compose run --rm cli tendermint show-node-id
  ```
- To query account balances:
  ```bash
  docker compose run --rm cli query bank balances <your_address> --node http://cronos:26657/
  ```

## Version

Cronos Node Docker uses semantic versioning.  
This is cronos-node-docker v1.0.0

