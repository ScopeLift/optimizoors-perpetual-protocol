// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IOpenPosition {
  function openPosition(uint256 amount, uint256 oppositeAmountBound, uint160 sqrtPriceLimitX96)
    external
    payable
    returns (uint256 base, uint256 quote, uint256 fee);
}
