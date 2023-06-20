# Create2
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/lib/Create2.sol)


## Functions
### computeCreate2Address


```solidity
function computeCreate2Address(
  bytes32 salt,
  address deployer,
  bytes memory initcode,
  bytes memory constructorArgs
) internal pure returns (address);
```

