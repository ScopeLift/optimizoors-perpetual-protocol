# IAccountBalance
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/interface/IAccountBalance.sol)


## Functions
### modifyTakerBalance

Modify trader account balance

*Only used by `ClearingHouse` contract*


```solidity
function modifyTakerBalance(address trader, address baseToken, int256 base, int256 quote)
  external
  returns (int256 takerPositionSize, int256 takerOpenNotional);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`baseToken`|`address`|The address of the baseToken|
|`base`|`int256`|Modified amount of base|
|`quote`|`int256`|Modified amount of quote|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`takerPositionSize`|`int256`|Taker position size after modified|
|`takerOpenNotional`|`int256`|Taker open notional after modified|


### modifyOwedRealizedPnl

Modify trader owedRealizedPnl

*Only used by `ClearingHouse` contract*


```solidity
function modifyOwedRealizedPnl(address trader, int256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`amount`|`int256`|Modified amount of owedRealizedPnl|


### settleOwedRealizedPnl

Settle owedRealizedPnl

*Only used by `Vault.withdraw()`*


```solidity
function settleOwedRealizedPnl(address trader) external returns (int256 pnl);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`pnl`|`int256`|Settled owedRealizedPnl|


### settleQuoteToOwedRealizedPnl

Modify trader owedRealizedPnl

*Only used by `ClearingHouse` contract*


```solidity
function settleQuoteToOwedRealizedPnl(address trader, address baseToken, int256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`baseToken`|`address`|The address of the baseToken|
|`amount`|`int256`|Settled quote amount|


### settleBalanceAndDeregister

Settle account balance and deregister base token

*Only used by `ClearingHouse` contract*


```solidity
function settleBalanceAndDeregister(
  address trader,
  address baseToken,
  int256 takerBase,
  int256 takerQuote,
  int256 realizedPnl,
  int256 makerFee
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`baseToken`|`address`|The address of the baseToken|
|`takerBase`|`int256`|Modified amount of taker base|
|`takerQuote`|`int256`|Modified amount of taker quote|
|`realizedPnl`|`int256`|Amount of pnl realized|
|`makerFee`|`int256`|Amount of maker fee collected from pool|


### registerBaseToken

Every time a trader's position value is checked, the base token list of this trader will be traversed;
thus, this list should be kept as short as possible

*Only used by `ClearingHouse` contract*


```solidity
function registerBaseToken(address trader, address baseToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`baseToken`|`address`|The address of the trader's base token|


### deregisterBaseToken

Deregister baseToken from trader accountInfo

*Only used by `ClearingHouse` contract, this function is expensive, due to for loop*


```solidity
function deregisterBaseToken(address trader, address baseToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`baseToken`|`address`|The address of the trader's base token|


### updateTwPremiumGrowthGlobal

Update trader Twap premium info

*Only used by `ClearingHouse` contract*


```solidity
function updateTwPremiumGrowthGlobal(
  address trader,
  address baseToken,
  int256 lastTwPremiumGrowthGlobalX96
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|
|`lastTwPremiumGrowthGlobalX96`|`int256`|The last Twap Premium|


### settlePositionInClosedMarket

Settle trader's PnL in closed market

*Only used by `ClearingHouse`*


```solidity
function settlePositionInClosedMarket(address trader, address baseToken)
  external
  returns (int256 positionNotional, int256 openNotional, int256 realizedPnl, uint256 closedPrice);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of the trader|
|`baseToken`|`address`|The address of the trader's base token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`positionNotional`|`int256`|Taker's position notional settled with closed price|
|`openNotional`|`int256`|Taker's open notional|
|`realizedPnl`|`int256`|Settled realized pnl|
|`closedPrice`|`uint256`|The closed price of the closed market|


### getClearingHouseConfig

Get `ClearingHouseConfig` address


```solidity
function getClearingHouseConfig() external view returns (address clearingHouseConfig);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouseConfig`|`address`|The address of ClearingHouseConfig|


### getOrderBook

Get `OrderBook` address


```solidity
function getOrderBook() external view returns (address orderBook);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`orderBook`|`address`|The address of OrderBook|


### getVault

Get `Vault` address


```solidity
function getVault() external view returns (address vault);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`address`|The address of Vault|


### getBaseTokens

Get trader registered baseTokens


```solidity
function getBaseTokens(address trader) external view returns (address[] memory baseTokens);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`baseTokens`|`address[]`|The array of baseToken address|


### getAccountInfo

Get trader account info


```solidity
function getAccountInfo(address trader, address baseToken)
  external
  view
  returns (AccountMarket.Info memory traderAccountInfo);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`traderAccountInfo`|`AccountMarket.Info`|The baseToken account info of trader|


### getTakerOpenNotional

Get taker cost of trader's baseToken


```solidity
function getTakerOpenNotional(address trader, address baseToken)
  external
  view
  returns (int256 openNotional);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`openNotional`|`int256`|The taker cost of trader's baseToken|


### getTotalOpenNotional

Get total cost of trader's baseToken


```solidity
function getTotalOpenNotional(address trader, address baseToken)
  external
  view
  returns (int256 totalOpenNotional);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalOpenNotional`|`int256`|the amount of quote token paid for a position when opening|


### getTotalDebtValue

Get total debt value of trader

*Total debt value will relate to `Vault.getFreeCollateral()`*


```solidity
function getTotalDebtValue(address trader) external view returns (uint256 totalDebtValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalDebtValue`|`uint256`|The debt value of trader|


### getMarginRequirementForLiquidation

Get margin requirement to check whether trader will be able to liquidate

*This is different from `Vault._getTotalMarginRequirement()`, which is for freeCollateral calculation*


```solidity
function getMarginRequirementForLiquidation(address trader)
  external
  view
  returns (int256 marginRequirementForLiquidation);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`marginRequirementForLiquidation`|`int256`|It is compared with `ClearingHouse.getAccountValue` which is also an int|


### getPnlAndPendingFee

Get owedRealizedPnl, unrealizedPnl and pending fee


```solidity
function getPnlAndPendingFee(address trader)
  external
  view
  returns (int256 owedRealizedPnl, int256 unrealizedPnl, uint256 pendingFee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`owedRealizedPnl`|`int256`|the pnl realized already but stored temporarily in AccountBalance|
|`unrealizedPnl`|`int256`|the pnl not yet realized|
|`pendingFee`|`uint256`|the pending fee of maker earned|


### hasOrder

Check trader has open order in open/closed market.


```solidity
function hasOrder(address trader) external view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|True of false|


### getBase

Get trader base amount

*`base amount = takerPositionSize - orderBaseDebt`*


```solidity
function getBase(address trader, address baseToken) external view returns (int256 baseAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`baseAmount`|`int256`|The base amount of trader's baseToken market|


### getQuote

Get trader quote amount

*`quote amount = takerOpenNotional - orderQuoteDebt`*


```solidity
function getQuote(address trader, address baseToken) external view returns (int256 quoteAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`quoteAmount`|`int256`|The quote amount of trader's baseToken market|


### getTakerPositionSize

Get taker position size of trader's baseToken market

*This will only has taker position, can get maker impermanent position through `getTotalPositionSize`*


```solidity
function getTakerPositionSize(address trader, address baseToken)
  external
  view
  returns (int256 takerPositionSize);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`takerPositionSize`|`int256`|The taker position size of trader's baseToken market|


### getTotalPositionSize

Get total position size of trader's baseToken market

*`total position size = taker position size + maker impermanent position size`*


```solidity
function getTotalPositionSize(address trader, address baseToken)
  external
  view
  returns (int256 totalPositionSize);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalPositionSize`|`int256`|The total position size of trader's baseToken market|


### getTotalPositionValue

Get total position value of trader's baseToken market

*A negative returned value is only be used when calculating pnl,*

*we use mark price to calc position value*


```solidity
function getTotalPositionValue(address trader, address baseToken)
  external
  view
  returns (int256 totalPositionValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalPositionValue`|`int256`|Total position value of trader's baseToken market|


### getTotalAbsPositionValue

Get all market position abs value of trader


```solidity
function getTotalAbsPositionValue(address trader)
  external
  view
  returns (uint256 totalAbsPositionValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalAbsPositionValue`|`uint256`|Sum up positions value of every market|


### getLiquidatablePositionSize

Get liquidatable position size of trader's baseToken market


```solidity
function getLiquidatablePositionSize(address trader, address baseToken, int256 accountValue)
  external
  view
  returns (int256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|
|`accountValue`|`int256`|The account value of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`int256`|liquidatablePositionSize The liquidatable position size of trader's baseToken market|


### getMarkPrice

Get mark price of baseToken market

*Mark price is the median of three prices as below.
1. current market price
2. market twap with 30 mins
3. index price + premium with 15 mins*

*If the parameters to calculate mark price are not set, returns index twap instead for backward compatible*

*If the market is paused, returns index twap instead, that will be the index twap while pausing market*


```solidity
function getMarkPrice(address baseToken) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|price The mark price of baseToken market|


## Events
### VaultChanged

```solidity
event VaultChanged(address indexed vault);
```

### PnlRealized
*Emit whenever a trader's `owedRealizedPnl` is updated*


```solidity
event PnlRealized(address indexed trader, int256 amount);
```

