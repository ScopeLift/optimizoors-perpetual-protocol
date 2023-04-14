// SPDX-License-Identifier: GPL-3.0-or-later
// permalink: https://optimistic.etherscan.io/address/0x12c884f45062b58e1592d1438542731829790a25#code#F39#L1
pragma solidity 0.8.16;

library AccountMarket {
    /// @param lastTwPremiumGrowthGlobalX96 the last time weighted premiumGrowthGlobalX96
    struct Info {
        int256 takerPositionSize;
        int256 takerOpenNotional;
        int256 lastTwPremiumGrowthGlobalX96;
    }
}
