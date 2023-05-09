# Perpetual Protocol Optimizoors

**This repo does not contain production ready code and is still a work in progress.**

- [About](#about)
- [Development](#development)
  - [Instructions](#instructions)
- [License](#license)

## About

Perpetual Optimizoors compresses calldata for Perpetual Protocol allowing
users to experience significant gas savings. This work was funded by an Ethereum Foundation
[grant](https://blog.ethereum.org/2023/02/14/layer-2-grants-roundup). Read our [blog post](https://www.scopelift.co/blog/calldata-optimizooooors) to learn more.

## Development

This repository requires [foundry](https://github.com/foundry-rs/foundry) for smart contract development.

### Instructions

To get started, clone this repo, then follow the below instructions:

```
# run these commands from the workspace root!
cp .env.example .env
curl -L https://foundry.paradigm.xyz | bash # install foundryup binary
foundryup # install Foundry

# Example commands using forge

forge test # runs tests for the smart contracts
forge build # build the projects smart contracts
```

To learn more about what commands can be run using forge check out the
[foundry book](https://book.getfoundry.sh/reference/forge/forge).

## License

Umbra is available under the [MIT](LICENSE.txt) license.

Copyright (c) 2023 ScopeLift
