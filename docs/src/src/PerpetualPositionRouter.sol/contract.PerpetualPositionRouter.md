# PerpetualPositionRouter
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/PerpetualPositionRouter.sol)

A router to manage a Perpetual position by opening and closing it.


## State Variables
### PERPETUAL_CLEARING_HOUSE
The contract used to manage positions in Perpetual.


```solidity
IClearingHouse public immutable PERPETUAL_CLEARING_HOUSE;
```


### TOKEN
The token used for the router's positions.


```solidity
address public immutable TOKEN;
```


### ACCOUNT_BALANCE
The Perpetual contract that manages a users account balance.


```solidity
IAccountBalance public immutable ACCOUNT_BALANCE;
```


### REFERRAL_CODE
*The default value for a referral code used when opening a position.*


```solidity
bytes32 internal constant REFERRAL_CODE =
  0x0000000000000000000000000000000000000000000000000000000000000000;
```


## Functions
### constructor


```solidity
constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, address asset);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouse`|`IClearingHouse`|Address of the Perpetual clearing house contract.|
|`accountBalance`|`IAccountBalance`|Address of the Perpetual account balance contract.|
|`asset`|`address`|Address of the token used for the Perpetual position.|


### receive

*if we remove this function solc will give a missing-receive-ether warning because we have
a payable fallback function. We cannot change the fallback function to a receive function
because receive does not have access to msg.data. In order to prevent a missing-receive-ether
warning we add a receive function and revert.*


```solidity
receive() external payable;
```

### _openLongInput

*Used to open a long position that takes in the exact amount of input tokens.*


```solidity
function _openLongInput(
  uint256 amount,
  uint256 oppositeAmountBound,
  uint160 sqrtPriceLimitX96,
  uint256 deadline
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The input amount of the position.|
|`oppositeAmountBound`|`uint256`|The lower bound of the router token.|
|`sqrtPriceLimitX96`|`uint160`|The restriction on the ending price after the swap.|
|`deadline`|`uint256`|The restriction on when the tx should be executed; otherwise, tx will get reverted.|


### _openLongOutput

*Used to open a long position specifying the output amount of the position.*


```solidity
function _openLongOutput(
  uint256 amount,
  uint256 oppositeAmountBound,
  uint160 sqrtPriceLimitX96,
  uint256 deadline
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The output amount of the position.|
|`oppositeAmountBound`|`uint256`|The upper bound on the input quote token (e.g. vUSDC).|
|`sqrtPriceLimitX96`|`uint160`|The restriction on the ending price after the swap.|
|`deadline`|`uint256`|The restriction on when the tx should be executed; otherwise, tx will get reverted.|


### _openShortInput

*Used to open a short position specifying the input amount of the position.*


```solidity
function _openShortInput(
  uint256 amount,
  uint256 oppositeAmountBound,
  uint160 sqrtPriceLimitX96,
  uint256 deadline
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The input amount of the position.|
|`oppositeAmountBound`|`uint256`|The lower bound on the output quote token (e.g. vUSDC).|
|`sqrtPriceLimitX96`|`uint160`|The restriction on the ending price after the swap.|
|`deadline`|`uint256`|The restriction on when the tx should be executed; otherwise, tx will get reverted.|


### _openShortOutput

*Used to open a short position specifying the output amount of the position.*


```solidity
function _openShortOutput(
  uint256 amount,
  uint256 oppositeAmountBound,
  uint160 sqrtPriceLimitX96,
  uint256 deadline
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The output amount of the position.|
|`oppositeAmountBound`|`uint256`|The upper bound of the router token.|
|`sqrtPriceLimitX96`|`uint160`|The restriction on the ending price after the swap.|
|`deadline`|`uint256`|The restriction on when the tx should be executed; otherwise, tx will get reverted.|


### _closePosition

*Closes an open position for the router's token.*


```solidity
function _closePosition(uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96, uint256 deadline)
  internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`oppositeAmountBound`|`uint256`|If the position being closed in a long position then this will be the upper bound on the input quote token (e.g. vUSDC). If the position is a short position then this will be the lower bound on the output quote token (e.g. vUSDC).|
|`sqrtPriceLimitX96`|`uint160`|The restriction on the ending price after the swap.|
|`deadline`|`uint256`|The restriction on when the tx should be executed; otherwise, tx will get reverted.|


### fallback

Creates or closes a position depending on the provided `funcId`. Calldata is
conditionally decoded based on the `funcId`.


```solidity
fallback() external payable;
```

## Errors
### FunctionDoesNotExist
*Thrown when calldata provides a function ID that does not exist.*


```solidity
error FunctionDoesNotExist();
```

### InvalidCalldata
*Thrown when calldata is invalid for the provided function id.*


```solidity
error InvalidCalldata();
```

### NoExistingPosition
*Thrown when a user tries to take an action on a position that does not exist.*


```solidity
error NoExistingPosition();
```

### UnsupportedFunction
*Thrown when a function is not supported.*


```solidity
error UnsupportedFunction();
```

