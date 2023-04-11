// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {Create2} from "src/lib/Create2.sol";
import {IOpenPosition} from "src/interface/IOpenPosition.sol";

// Base token will be virtual address
// struct OpenPositionParams {
//     address baseToken;
//     // true for shorting, false for long
//     bool isBaseToQuote;
//     // Is exact input, if you want to send an exact
//     // amount of input tokens or exact output
//     bool isExactInput;
//     // Depending on exact input this will be exact input amount or exact output amount
//     uint256 amount;
//     // Bound on what to receive or pay
//     // depends on isBaseToQuote and isExactInput
//     uint256 oppositeAmountBound;
//     // Deadline of when a transaction should be executed
//     // opportunity: reduce precision
//     uint256 deadline;
//     // The price limit for the position. 0 for no limit
//     uint160 sqrtPriceLimitX96;
//     // The referrala code for partners
//     bytes32 referralCode;
// }

// interface IPerpetual {
//     function openPosition(OpenPositionParams memory params) external;
// }

// base for token, short, long, exact input, exact output
abstract contract PerpetualBaseRouter {
    IClearingHouse public immutable PERPETUAL;
    bool public immutable IS_BASE_TO_QUOTE;
    bool public immutable IS_EXACT_INPUT;
    address public immutable TOKEN;

    bytes32 internal constant REFERRAL_CODE =
        0x0000000000000000000000000000000000000000000000000000000000000000;

    constructor(
        IClearingHouse perpetual,
        address asset,
        bool isBaseToQuote,
        bool isExactInput
    ) {
        PERPETUAL = perpetual;
        IS_BASE_TO_QUOTE = isBaseToQuote;
        IS_EXACT_INPUT = isExactInput;
        TOKEN = asset;
    }
}

// open position
// User approves to send to contract
// Contract already has approval to send to Perpetual
contract PerpetualLongInput is PerpetualBaseRouter, IOpenPosition {
    using SafeTransferLib for IERC20;

    constructor(IClearingHouse perpetual, address asset)
        PerpetualBaseRouter(perpetual, asset, false, true)
    {
        // IERC20(asset).safeApprove(address(perpetual), type(uint256).max);
    }

    // Using fallback is possible, but not recommended
    // by the docs.
    // https://docs.soliditylang.org/en/v0.8.19/contracts.html#fallback-function
    //
    // Going to push on the integer optimization as we figure out the pros and cons
    //
    // 1. What us a reasonable amount of precision to reducethe function?
    // 2. What are reasonable time periods for deadlines
    //
    // Could we use message.value
    function openPosition(
        uint256 amount,
        uint256 oppositeAmountBound,
        uint160 sqrtPriceLimitX96
    )
        external
        payable
        returns (
            uint256 base,
            uint256 quote,
            uint256 fee
        )
    {
        return
            PERPETUAL.openPositionFor(
                msg.sender,
                IClearingHouse.OpenPositionParams({
                    baseToken: TOKEN,
                    isBaseToQuote: IS_BASE_TO_QUOTE,
                    isExactInput: IS_EXACT_INPUT,
                    amount: amount,
                    oppositeAmountBound: oppositeAmountBound,
                    deadline: block.timestamp,
                    sqrtPriceLimitX96: sqrtPriceLimitX96,
                    referralCode: REFERRAL_CODE
                })
            );
    }
}

// Simple router, support a single token
contract PerpetualRouterFactory {
    IClearingHouse public immutable PERPETUAL;

    event RoutersDeployed(
        address supplyRouter,
        address withdrawRouter,
        address indexed asset
    );

    constructor(IClearingHouse clearingHouse) {
        PERPETUAL = clearingHouse;
    }

    function deploy(address asset) external returns (address) {
        bytes32 salt = _salt(asset);
        address openPositionLongInput = address(
            new PerpetualLongInput{salt: salt}(PERPETUAL, asset)
        );
        return openPositionLongInput;
    }

    function computeAddress(address asset) external view returns (address) {
        return
            Create2.computeCreate2Address(
                _salt(asset),
                address(this),
                type(PerpetualLongInput).creationCode,
                abi.encode(PERPETUAL, asset)
            );
    }

    function _salt(address asset) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(asset)));
    }
}
