# Perpetual Protocol Optimizoors

⚠️ **This code is not audited. Use at your own risk.**

- [About](#about)
- [Development](#development)
  - [Instructions](#instructions)
  - [Contracts](docs/src/SUMMARY.md)
  - [Addresses](#addresses)
- [License](#license)


## About

Perpetual Optimizoors provides a calldata-optimized router for [Perpetual Protocol](https://perp.com/),
providing significant gas savings to users. This work was funded by an Ethereum Foundation
[grant](https://blog.ethereum.org/2023/02/14/layer-2-grants-roundup). Read our [blog post](https://www.scopelift.co/blog/calldata-optimizooooors) to learn more about how we optimize protocols on L2.

## Development

### Instructions

To get started, clone this repo, then follow the below instructions:

```sh
# run these commands from the workspace root!
cp .env.example .env

# Run tests
forge test

# Build smart contracts
forge build
```

## Addresses

| Name   |    Address      |
|----------|:-------------:|
| Perpetual Router Factory |  0xbF2870611603b2f02B8616E0fE65C60f7657a0f4|

### How it works

We have a router factory which deploys calldata optimized routers for specific functionality within
Perpetual Protocol. Currently, we have two types of routers. One that has the functionality for opening and closing
positions which we call the `PositionRouter`, and another to deposit ERC20 or Ethereum into a Perpetual vault which
we call the `DepositRouter`.

There will be one `PositionRouter` contract per position token. For example if a user is opening a vETH
position they will have to call the vETH position router. The same is also true for a `DepositRouter`. There
will a `DepositRouter` contract per token.

## License

This project is available under the [MIT](LICENSE.txt) license.

Copyright (c) 2023 ScopeLift
