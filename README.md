# MoveFWD Week 3 — Solutions

This repo contains solutions for MoveFWD Week 3 challenges:

- `challenge-1` — Counter with Access Control
- `challenge-2` — Simple NFT Minting
- `challenge-3` — Simple Staking Contract

## Structure

Each challenge folder contains:
- `Move.toml` — package metadata
- `sources/*.move` — Move modules
- `tests/*.move` — unit/integration tests (Sui test_scenario style)

## How to build & test (local, optional)
If you have Sui CLI and Rust installed:

```bash
# from challenge folder, e.g. challenge-1
sui move build
sui move test
# publish (requires testnet config & gas)
sui client publish --gas-budget 100000000
