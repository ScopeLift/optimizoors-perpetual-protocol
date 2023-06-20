# IVault
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/interface/IVault.sol)


## Functions
### deposit

Deposit collateral into vault


```solidity
function deposit(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to deposit|
|`amount`|`uint256`|The amount of the token to deposit|


### depositFor

Deposit the collateral token for other account


```solidity
function depositFor(address to, address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address of the account to deposit to|
|`token`|`address`|The address of collateral token|
|`amount`|`uint256`|The amount of the token to deposit|


### depositEther

Deposit ETH as collateral into vault


```solidity
function depositEther() external payable;
```

### depositEtherFor

Deposit ETH as collateral for specified account


```solidity
function depositEtherFor(address to) external payable;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|The address of the account to deposit to|


### withdraw

Withdraw collateral from vault


```solidity
function withdraw(address token, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to withdraw|
|`amount`|`uint256`|The amount of the token to withdraw|


### withdrawEther

Withdraw ETH from vault


```solidity
function withdrawEther(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of the ETH to withdraw|


### withdrawAll

Withdraw all free collateral from vault


```solidity
function withdrawAll(address token) external returns (uint256 amount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of the token withdrawn|


### withdrawAllEther

Withdraw all free collateral of ETH from vault


```solidity
function withdrawAllEther() external returns (uint256 amount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|The amount of ETH withdrawn|


### liquidateCollateral

Liquidate trader's collateral by given settlement token amount or non settlement token
amount


```solidity
function liquidateCollateral(
  address trader,
  address token,
  uint256 amount,
  bool isDenominatedInSettlementToken
) external returns (uint256 returnAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader that will be liquidated|
|`token`|`address`|The address of non settlement collateral token that the trader will be liquidated|
|`amount`|`uint256`|The amount of settlement token that the liquidator will repay for trader or the amount of non-settlement collateral token that the liquidator will charge from trader|
|`isDenominatedInSettlementToken`|`bool`|Whether the amount is denominated in settlement token or not|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnAmount`|`uint256`|The amount of a non-settlement token (in its native decimals) that is liquidated when `isDenominatedInSettlementToken` is true or the amount of settlement token that is repaid when `isDenominatedInSettlementToken` is false|


### settleBadDebt

Settle trader's bad debt


```solidity
function settleBadDebt(address trader) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader that will be settled|


### getBalance

Get the specified trader's settlement token balance, without pending fee, funding
payment
and owed realized PnL

*The function is equivalent to `getBalanceByToken(trader, settlementToken)`
We keep this function solely for backward-compatibility with the older single-collateral
system.
In practical applications, the developer might want to use `getSettlementTokenValue()`
instead
because the latter includes pending fee, funding payment etc.
and therefore more accurately reflects a trader's settlement (ex. USDC) balance*


```solidity
function getBalance(address trader) external view returns (int256 balance);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`int256`|The balance amount (in settlement token's decimals)|


### getBalanceByToken

Get the balance of Vault of the specified collateral token and trader


```solidity
function getBalanceByToken(address trader, address token) external view returns (int256 balance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`token`|`address`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`int256`|The balance amount (in its native decimals)|


### getCollateralTokens

Get they array of collateral token addresses that a trader has


```solidity
function getCollateralTokens(address trader)
  external
  view
  returns (address[] memory collateralTokens);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralTokens`|`address[]`|array of collateral token addresses|


### getAccountValue

Get account value of the specified trader


```solidity
function getAccountValue(address trader) external view returns (int256 accountValueX10_S);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accountValueX10_S`|`int256`|account value (in settlement token's decimals)|


### getFreeCollateral

Get the free collateral value denominated in the settlement token of the specified
trader


```solidity
function getFreeCollateral(address trader) external view returns (uint256 freeCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`freeCollateral`|`uint256`|the value (in settlement token's decimals) of free collateral available for withdraw or opening new positions or orders)|


### getFreeCollateralByRatio

Get the free collateral amount of the specified trader and collateral ratio

*There are three configurations for different insolvency risk tolerances:
**conservative, moderate &aggressive**. We will start with the **conservative** one
and gradually move to **aggressive** to increase capital efficiency*


```solidity
function getFreeCollateralByRatio(address trader, uint24 ratio)
  external
  view
  returns (int256 freeCollateralByRatio);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`ratio`|`uint24`|The margin requirement ratio, imRatio or mmRatio|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`freeCollateralByRatio`|`int256`|freeCollateral (in settlement token's decimals), by using the input margin requirement ratio; can be negative|


### getFreeCollateralByToken

Get the free collateral amount of the specified collateral token of specified trader


```solidity
function getFreeCollateralByToken(address trader, address token)
  external
  view
  returns (uint256 freeCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`token`|`address`|The address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`freeCollateral`|`uint256`|amount of that token (in the token's native decimals)|


### getSettlementTokenValue

Get the specified trader's settlement value, including pending fee, funding payment,
owed realized PnL and unrealized PnL

*Note the difference between `settlementTokenBalanceX10_S`, `getSettlementTokenValue()`
and `getBalance()`:
They are all settlement token balances but with or without
pending fee, funding payment, owed realized PnL, unrealized PnL, respectively
In practical applications, we use `getSettlementTokenValue()` to get the trader's debt
(if < 0)*


```solidity
function getSettlementTokenValue(address trader) external view returns (int256 balance);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balance`|`int256`|The balance amount (in settlement token's decimals)|


### getSettlementToken

Get the settlement token address

*We assume the settlement token should match the denominator of the price oracle.
i.e. if the settlement token is USDC, then the oracle should be priced in USD*


```solidity
function getSettlementToken() external view returns (address settlementToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`settlementToken`|`address`|The address of the settlement token|


### isLiquidatable

Check if a given trader's collateral token can be liquidated; liquidation criteria:
1. margin ratio falls below maintenance threshold + 20bps (mmRatioBuffer)
2. USDC debt > nonSettlementTokenValue * debtNonSettlementTokenValueRatio (ex: 75%)
3. USDC debt > debtThreshold (ex: $10000)


```solidity
function isLiquidatable(address trader) external view returns (bool isLiquidatable);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isLiquidatable`|`bool`|If the trader can be liquidated|


### getMarginRequirementForCollateralLiquidation

get the margin requirement for collateral liquidation of a trader

*this value is compared with `ClearingHouse.getAccountValue()` (int)*


```solidity
function getMarginRequirementForCollateralLiquidation(address trader)
  external
  view
  returns (int256 marginRequirement);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`marginRequirement`|`int256`|margin requirement (in 18 decimals)|


### getCollateralMmRatio

Get the maintenance margin ratio for collateral liquidation


```solidity
function getCollateralMmRatio() external view returns (uint24 collateralMmRatio);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralMmRatio`|`uint24`|The maintenance margin ratio for collateral liquidation|


### getLiquidatableCollateralBySettlement

Get a trader's liquidatable collateral amount by a given settlement amount


```solidity
function getLiquidatableCollateralBySettlement(address token, uint256 settlementX10_S)
  external
  view
  returns (uint256 collateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token of the trader's collateral|
|`settlementX10_S`|`uint256`|The amount of settlement token the liquidator wants to pay|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateral`|`uint256`|The collateral amount(in its native decimals) the liquidator can get|


### getRepaidSettlementByCollateral

Get a trader's repaid settlement amount by a given collateral amount


```solidity
function getRepaidSettlementByCollateral(address token, uint256 collateral)
  external
  view
  returns (uint256 settlementX10_S);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|The address of the token of the trader's collateral|
|`collateral`|`uint256`|The amount of collateral token the liquidator wants to get|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`settlementX10_S`|`uint256`|The settlement amount(in settlement token's decimals) the liquidator needs to pay|


### getMaxRepaidSettlementAndLiquidatableCollateral

Get a trader's max repaid settlement & max liquidatable collateral by a given
collateral token


```solidity
function getMaxRepaidSettlementAndLiquidatableCollateral(address trader, address token)
  external
  view
  returns (uint256 maxRepaidSettlementX10_S, uint256 maxLiquidatableCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`token`|`address`|The address of the token of the trader's collateral|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maxRepaidSettlementX10_S`|`uint256`|The maximum settlement amount(in settlement token's decimals) the liquidator needs to pay to liquidate a trader's collateral token|
|`maxLiquidatableCollateral`|`uint256`|The maximum liquidatable collateral amount (in the collateral token's native decimals) of a trader|


### decimals

Get settlement token decimals

*cached the settlement token's decimal for gas optimization*


```solidity
function decimals() external view returns (uint8 decimals);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`decimals`|`uint8`|The decimals of settlement token|


### getTotalDebt

(Deprecated) Get the borrowed settlement token amount from insurance fund


```solidity
function getTotalDebt() external view returns (uint256 debtAmount);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`debtAmount`|`uint256`|The debt amount (in settlement token's decimals)|


### getClearingHouseConfig

Get `ClearingHouseConfig` contract address


```solidity
function getClearingHouseConfig() external view returns (address clearingHouseConfig);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouseConfig`|`address`|The address of `ClearingHouseConfig` contract|


### getAccountBalance

Get `AccountBalance` contract address


```solidity
function getAccountBalance() external view returns (address accountBalance);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accountBalance`|`address`|The address of `AccountBalance` contract|


### getInsuranceFund

Get `InsuranceFund` contract address


```solidity
function getInsuranceFund() external view returns (address insuranceFund);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`insuranceFund`|`address`|The address of `InsuranceFund` contract|


### getExchange

Get `Exchange` contract address


```solidity
function getExchange() external view returns (address exchange);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`exchange`|`address`|The address of `Exchange` contract|


### getClearingHouse

Get `ClearingHouse` contract address


```solidity
function getClearingHouse() external view returns (address clearingHouse);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouse`|`address`|The address of `ClearingHouse` contract|


### getCollateralManager

Get `CollateralManager` contract address


```solidity
function getCollateralManager() external view returns (address clearingHouse);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouse`|`address`|The address of `CollateralManager` contract|


### getWETH9

Get `WETH9` contract address


```solidity
function getWETH9() external view returns (address clearingHouse);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouse`|`address`|The address of `WETH9` contract|


## Events
### Deposited
Emitted when trader deposit collateral into vault


```solidity
event Deposited(address indexed collateralToken, address indexed trader, uint256 amount);
```

### Withdrawn
Emitted when trader withdraw collateral from vault


```solidity
event Withdrawn(address indexed collateralToken, address indexed trader, uint256 amount);
```

### CollateralLiquidated
Emitted when a trader's collateral is liquidated


```solidity
event CollateralLiquidated(
  address indexed trader,
  address indexed collateralToken,
  address indexed liquidator,
  uint256 collateral,
  uint256 repaidSettlementWithoutInsuranceFundFeeX10_S,
  uint256 insuranceFundFeeX10_S,
  uint24 discountRatio
);
```

### TrustedForwarderChanged
Emitted when trustedForwarder is changed

*trustedForwarder is only used for metaTx*


```solidity
event TrustedForwarderChanged(address indexed trustedForwarder);
```

### ClearingHouseChanged
Emitted when clearingHouse is changed


```solidity
event ClearingHouseChanged(address indexed clearingHouse);
```

### CollateralManagerChanged
Emitted when collateralManager is changed


```solidity
event CollateralManagerChanged(address indexed collateralManager);
```

### WETH9Changed
Emitted when WETH9 is changed


```solidity
event WETH9Changed(address indexed WETH9);
```

### BadDebtSettled
Emitted when bad debt realized and settled


```solidity
event BadDebtSettled(address indexed trader, uint256 amount);
```

