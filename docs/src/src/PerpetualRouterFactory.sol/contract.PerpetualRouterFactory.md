# PerpetualRouterFactory
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/PerpetualRouterFactory.sol)

A factory for deploying an optimized router for Perpetual protocol. A router will
require an asset and wrap some piece of functionality of Perpetual protocol.


## State Variables
### PERPETUAL_CLEARING_HOUSE
The contract used to manage positions in Perpetual.


```solidity
IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
```


### PERPETUAL_ACCOUNT_BALANCE
The Perpetual contract that manages a users account balance.


```solidity
IAccountBalance public immutable PERPETUAL_ACCOUNT_BALANCE;
```


### PERPETUAL_VAULT
The contract for the Perpetual vault where the deposits are sent.


```solidity
IVault public immutable PERPETUAL_VAULT;
```


## Functions
### constructor


```solidity
constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, IVault vault);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouse`|`IClearingHouse`|Address of the Perpetual clearing house contract.|
|`accountBalance`|`IAccountBalance`|Address of the Perpetual account balance contract.|
|`vault`|`IVault`|Address of the Perpetual vault contract.|


### deploy

Creates a contract for a given `asset` and router `type_`, and returns the address for
the deployed contract.

*This function will only revert with `RouterTypeDoesNotExist` if a new router is added and
the case has not been handled yet. It should never revert in production.*


```solidity
function deploy(RouterType type_, address asset) external returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`type_`|`RouterType`|The type of router to deploy.|
|`asset`|`address`|The token the router uses to manage deposits and positions.|


### computeAddress

Returns the address for a router of a given `asset` and router `type_`. This function
will still return an address even if the router has not been deployed.

*This function will only revert with `RouterTypeDoesNotExist` if a new router is added and
the case has not been handled yet. It should never revert in production.*


```solidity
function computeAddress(RouterType type_, address asset) external view returns (address);
```

### _computePositionAddress

*Computes the address for a position router of a given `asset`.*


```solidity
function _computePositionAddress(address asset) internal view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The token the router uses to open and close positions.|


### _computeDepositAddress

*Computes the address for a deposit router of a given `asset`.*


```solidity
function _computeDepositAddress(address asset) internal view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`asset`|`address`|The token the router uses to manage deposits.|


### _salt

*Creates salt value used when creating a contract using `CREATE2` for the given `asset`.*


```solidity
function _salt(address asset) internal pure returns (bytes32);
```

## Events
### RouterDeployed
*Emitted on a successfully deployed router.*


```solidity
event RouterDeployed(RouterType indexed type_, address indexed asset);
```

## Errors
### RouterTypeDoesNotExist
*Thrown when a function tries to use a router that does not exist. This error should not
be thrown in production as we use an enum to ensure that a valid router is passed into a
function.*


```solidity
error RouterTypeDoesNotExist();
```

## Enums
### RouterType
*The different types of routers that can be deployed by the factory.*


```solidity
enum RouterType {
  PositionRouterType,
  DepositRouterType
}
```

