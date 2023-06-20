# DepositRouter
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/DepositRouter.sol)

A router for depositing funds into the Perpetual vault. It supports a single ERC20 token
and Ether.


## State Variables
### TOKEN
The token that is being deposited into the router.


```solidity
address public immutable TOKEN;
```


### PERPETUAL_VAULT
The contract for the Perpetual vault where the deposits are sent.


```solidity
IVault public immutable PERPETUAL_VAULT;
```


## Functions
### constructor


```solidity
constructor(address token, IVault vault);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Address of the token that is being deposited into the router.|
|`vault`|`IVault`|Address of the Perpetual vault where the deposits are sent.|


### fallback

Deposits the router's token into the Perpetual vault.


```solidity
fallback() external payable;
```

### receive

Deposits Ether into the Perpetual vault.


```solidity
receive() external payable;
```

