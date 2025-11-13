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


---

# D — 5 meaningful commit messages (order to use)

Use these messages as you add files to the repo. GitHub’s web UI allows you to make multiple commits — try to split changes across them.

1. `chore: scaffold repo for MoveFWD Week3 (three challenge folders)`
2. `feat(counter): add Counter module with AdminCap and events`
3. `feat(nft): add SimpleNFT module (mint, transfer, burn, views)`
4. `feat(staking): add Staking pool module (stake, unstake, rewards)`
5. `test: add tests for counter, nft, and staking; add README`

You can add extra commits such as `docs: update README` or `refactor: rename helper` to exceed the minimum if needed.

---

# E — Discord submission message (paste after publishing)

When you publish each package to testnet, you’ll get a Package ID. Post this in the MoveFWD Discord Week-3 channel (copy/paste below and replace package IDs and GitHub link):

