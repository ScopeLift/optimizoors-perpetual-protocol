# IClearingHouse
[Git Source](https://github.com/ScopeLift/optimizoors-perpetual-protocol/blob/1a3cdb1ddd1ba9b2c3010057997c040c5a815dac/src/interface/IClearingHouse.sol)


## Functions
### addLiquidity

Maker can call `addLiquidity` to provide liquidity on Uniswap V3 pool

*Tx will fail if adding `base == 0 && quote == 0` / `liquidity == 0`*

*- `AddLiquidityParams.useTakerBalance` is only accept `false` now*


```solidity
function addLiquidity(AddLiquidityParams calldata params)
  external
  returns (AddLiquidityResponse memory response);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`AddLiquidityParams`|AddLiquidityParams struct|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`response`|`AddLiquidityResponse`|AddLiquidityResponse struct|


### removeLiquidity

Maker can call `removeLiquidity` to remove liquidity

*remove liquidity will transfer maker impermanent position to taker position,
if `liquidity` of RemoveLiquidityParams struct is zero, the action will collect fee from
pool to maker*


```solidity
function removeLiquidity(RemoveLiquidityParams calldata params)
  external
  returns (RemoveLiquidityResponse memory response);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`RemoveLiquidityParams`|RemoveLiquidityParams struct|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`response`|`RemoveLiquidityResponse`|RemoveLiquidityResponse struct|


### settleAllFunding

Settle all markets fundingPayment to owedRealized Pnl


```solidity
function settleAllFunding(address trader) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|


### openPosition

Trader can call `openPosition` to long/short on baseToken market

*- `OpenPositionParams.oppositeAmountBound`
- B2Q + exact input, want more output quote as possible, so we set a lower bound of output
quote
- B2Q + exact output, want less input base as possible, so we set a upper bound of input
base
- Q2B + exact input, want more output base as possible, so we set a lower bound of output
base
- Q2B + exact output, want less input quote as possible, so we set a upper bound of input
quote
> when it's set to 0, it will disable slippage protection entirely regardless of exact
input or output
> when it's over or under the bound, it will be reverted*

*- `OpenPositionParams.sqrtPriceLimitX96`
- B2Q: the price cannot be less than this value after the swap
- Q2B: the price cannot be greater than this value after the swap
> it will fill the trade until it reaches the price limit but WON'T REVERT
> when it's set to 0, it will disable price limit;
> when it's 0 and exact output, the output amount is required to be identical to the param
amount*


```solidity
function openPosition(OpenPositionParams memory params)
  external
  returns (uint256 base, uint256 quote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`OpenPositionParams`|OpenPositionParams struct|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`base`|`uint256`|The amount of baseToken the taker got or spent|
|`quote`|`uint256`|The amount of quoteToken the taker got or spent|


### openPositionFor


```solidity
function openPositionFor(address trader, OpenPositionParams memory params)
  external
  returns (uint256 base, uint256 quote, uint256 fee);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`params`|`OpenPositionParams`|OpenPositionParams struct is the same as `openPosition()`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`base`|`uint256`|The amount of baseToken the taker got or spent|
|`quote`|`uint256`|The amount of quoteToken the taker got or spent|
|`fee`|`uint256`|The trading fee|


### closePosition

Close trader's position


```solidity
function closePosition(ClosePositionParams calldata params)
  external
  returns (uint256 base, uint256 quote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`params`|`ClosePositionParams`|ClosePositionParams struct|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`base`|`uint256`|The amount of baseToken the taker got or spent|
|`quote`|`uint256`|The amount of quoteToken the taker got or spent|


### liquidate

If trader is underwater, any one can call `liquidate` to liquidate this trader

*If trader has open orders, need to call `cancelAllExcessOrders` first*

*If positionSize is greater than maxLiquidatePositionSize, liquidate
maxLiquidatePositionSize by default*

*If margin ratio >= 0.5 * mmRatio,
maxLiquidateRatio = MIN((1, 0.5 * totalAbsPositionValue / absPositionValue)*

*If margin ratio < 0.5 * mmRatio, maxLiquidateRatio = 1*

*maxLiquidatePositionSize = positionSize * maxLiquidateRatio*


```solidity
function liquidate(address trader, address baseToken, int256 positionSize) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|
|`positionSize`|`int256`|the position size to be liquidated by liquidator|


### liquidate

liquidate trader's position and will liquidate the max possible position size

*If margin ratio >= 0.5 * mmRatio,
maxLiquidateRatio = MIN((1, 0.5 * totalAbsPositionValue / absPositionValue)*

*If margin ratio < 0.5 * mmRatio, maxLiquidateRatio = 1*

*maxLiquidatePositionSize = positionSize * maxLiquidateRatio*


```solidity
function liquidate(address trader, address baseToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|


### cancelExcessOrders

Cancel excess order of a maker

*Order id can get from `OrderBook.getOpenOrderIds`*


```solidity
function cancelExcessOrders(address maker, address baseToken, bytes32[] calldata orderIds) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker`|`address`|The address of Maker|
|`baseToken`|`address`|The address of baseToken|
|`orderIds`|`bytes32[]`|The id of the order|


### cancelAllExcessOrders

Cancel all excess orders of a maker if the maker is underwater

*This function won't fail if the maker has no order but fails when maker is not underwater*


```solidity
function cancelAllExcessOrders(address maker, address baseToken) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`maker`|`address`|The address of maker|
|`baseToken`|`address`|The address of baseToken|


### quitMarket

Close all positions and remove all liquidities of a trader in the closed market


```solidity
function quitMarket(address trader, address baseToken)
  external
  returns (uint256 base, uint256 quote);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|
|`baseToken`|`address`|The address of baseToken|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`base`|`uint256`|The amount of base token that is closed|
|`quote`|`uint256`|The amount of quote token that is closed|


### getAccountValue

Get account value of trader

*accountValue = totalCollateralValue + totalUnrealizedPnl, in 18 decimals*


```solidity
function getAccountValue(address trader) external view returns (int256 accountValue);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`trader`|`address`|The address of trader|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accountValue`|`int256`|The account value of trader|


### getQuoteToken

Get QuoteToken address


```solidity
function getQuoteToken() external view returns (address quoteToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`quoteToken`|`address`|The quote token address|


### getUniswapV3Factory

Get UniswapV3Factory address


```solidity
function getUniswapV3Factory() external view returns (address factory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`factory`|`address`|UniswapV3Factory address|


### getClearingHouseConfig

Get ClearingHouseConfig address


```solidity
function getClearingHouseConfig() external view returns (address clearingHouseConfig);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`clearingHouseConfig`|`address`|ClearingHouseConfig address|


### getVault

Get `Vault` address


```solidity
function getVault() external view returns (address vault);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`vault`|`address`|`Vault` address|


### getExchange

Get `Exchange` address


```solidity
function getExchange() external view returns (address exchange);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`exchange`|`address`|`Exchange` address|


### getOrderBook

Get `OrderBook` address


```solidity
function getOrderBook() external view returns (address orderBook);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`orderBook`|`address`|`OrderBook` address|


### getAccountBalance

Get AccountBalance address


```solidity
function getAccountBalance() external view returns (address accountBalance);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`accountBalance`|`address`|`AccountBalance` address|


### getInsuranceFund

Get `InsuranceFund` address


```solidity
function getInsuranceFund() external view returns (address insuranceFund);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`insuranceFund`|`address`|`InsuranceFund` address|


### getDelegateApproval

Get `DelegateApproval` address


```solidity
function getDelegateApproval() external view returns (address delegateApproval);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`delegateApproval`|`address`|`DelegateApproval` address|


## Events
### ReferredPositionChanged
Emitted when open position with non-zero referral code


```solidity
event ReferredPositionChanged(bytes32 indexed referralCode);
```

### PositionLiquidated
Emitted when taker position is being liquidated


```solidity
event PositionLiquidated(
  address indexed trader,
  address indexed baseToken,
  uint256 positionNotional,
  uint256 positionSize,
  uint256 liquidationFee,
  address liquidator
);
```

### LiquidityChanged
Emitted when maker's liquidity of a order changed


```solidity
event LiquidityChanged(
  address indexed maker,
  address indexed baseToken,
  address indexed quoteToken,
  int24 lowerTick,
  int24 upperTick,
  int256 base,
  int256 quote,
  int128 liquidity,
  uint256 quoteFee
);
```

### PositionChanged
Emitted when taker's position is being changed


```solidity
event PositionChanged(
  address indexed trader,
  address indexed baseToken,
  int256 exchangedPositionSize,
  int256 exchangedPositionNotional,
  uint256 fee,
  int256 openNotional,
  int256 realizedPnl,
  uint256 sqrtPriceAfterX96
);
```

### PositionClosed
Emitted when taker close her position in closed market


```solidity
event PositionClosed(
  address indexed trader,
  address indexed baseToken,
  int256 closedPositionSize,
  int256 closedPositionNotional,
  int256 openNotional,
  int256 realizedPnl,
  uint256 closedPrice
);
```

### FundingPaymentSettled
Emitted when settling a trader's funding payment


```solidity
event FundingPaymentSettled(
  address indexed trader, address indexed baseToken, int256 fundingPayment
);
```

### TrustedForwarderChanged
Emitted when trusted forwarder address changed

*TrustedForward is only used for metaTx*


```solidity
event TrustedForwarderChanged(address indexed forwarder);
```

### DelegateApprovalChanged
Emitted when DelegateApproval address changed


```solidity
event DelegateApprovalChanged(address indexed delegateApproval);
```

## Structs
### AddLiquidityParams

```solidity
struct AddLiquidityParams {
  address baseToken;
  uint256 base;
  uint256 quote;
  int24 lowerTick;
  int24 upperTick;
  uint256 minBase;
  uint256 minQuote;
  bool useTakerBalance;
  uint256 deadline;
}
```

### RemoveLiquidityParams

```solidity
struct RemoveLiquidityParams {
  address baseToken;
  int24 lowerTick;
  int24 upperTick;
  uint128 liquidity;
  uint256 minBase;
  uint256 minQuote;
  uint256 deadline;
}
```

### AddLiquidityResponse

```solidity
struct AddLiquidityResponse {
  uint256 base;
  uint256 quote;
  uint256 fee;
  uint256 liquidity;
}
```

### RemoveLiquidityResponse

```solidity
struct RemoveLiquidityResponse {
  uint256 base;
  uint256 quote;
  uint256 fee;
}
```

### OpenPositionParams

```solidity
struct OpenPositionParams {
  address baseToken;
  bool isBaseToQuote;
  bool isExactInput;
  uint256 amount;
  uint256 oppositeAmountBound;
  uint256 deadline;
  uint160 sqrtPriceLimitX96;
  bytes32 referralCode;
}
```

### ClosePositionParams

```solidity
struct ClosePositionParams {
  address baseToken;
  uint160 sqrtPriceLimitX96;
  uint256 oppositeAmountBound;
  uint256 deadline;
  bytes32 referralCode;
}
```

### CollectPendingFeeParams

```solidity
struct CollectPendingFeeParams {
  address trader;
  address baseToken;
  int24 lowerTick;
  int24 upperTick;
}
```

