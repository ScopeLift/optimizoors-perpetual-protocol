// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {IAccountBalance} from "src/interface/IAccountBalance.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {PerpetualPositionRouter} from "src/PerpetualPositionRouter.sol";
import {AccountMarket} from "src/lib/AccountMarket.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

contract PerpetualPositionRouterTestHarness is PerpetualPositionRouter {
  constructor(IClearingHouse clearingHouse, IAccountBalance accountBalance, address asset)
    PerpetualPositionRouter(clearingHouse, accountBalance, asset)
  {}

  function extractSqrtPriceLimitX96(uint168 args) external pure returns (uint160) {
    return _extractSqrtPriceLimitX96(args);
  }
}

contract PositionRouterTest is Test, PerpetualContracts {
  address vethPositionRouterAddr;

  function setUp() public virtual {
    PerpetualRouterFactory factory =
      new PerpetualRouterFactory(clearingHouse, accountBalance, vault);
    vethPositionRouterAddr =
      address(factory.computeAddress(PerpetualRouterFactory.RouterType.PositionRouterType, VETH));
  }

  function encodeArgs(uint8 funcId, uint160 sqrtPriceLimitX96) internal pure returns (uint168) {
    return (uint168(funcId) << 160) | uint168(sqrtPriceLimitX96);
  }

  function closePositionHelper(
    uint8 openFunc,
    uint256 amount,
    uint256 oppositeAmountBound,
    uint160 sqrtPriceLimitX96
  ) internal {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 openCombinedArgs = encodeArgs(openFunc, sqrtPriceLimitX96);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encode(openCombinedArgs, amount, oppositeAmountBound)
    );
    uint168 closeCombinedArgs = encodeArgs(5, sqrtPriceLimitX96);
    (bool okTwo,) =
      payable(vethPositionRouterAddr).call(abi.encode(closeCombinedArgs, 0, oppositeAmountBound));
    assertTrue(ok);
    assertTrue(okTwo);
  }
}

contract Constructor is PositionRouterTest {
  function test_CorrectlySetsAllConstructorArgs() public {
    PerpetualPositionRouter router = new PerpetualPositionRouter(
  	  clearingHouse,
  	  accountBalance,
  	  VETH
  );
    assertEq(
      address(router.PERPETUAL_CLEARING_HOUSE()),
      address(clearingHouse),
      "PERPETUAL_CLEARING_HOUSE not set correctly"
    );
    assertEq(
      address(router.ACCOUNT_BALANCE()),
      address(accountBalance),
      "ACCOUNT_BALANCE not set correctly"
    );
    assertEq(router.TOKEN(), VETH, "TOKEN not set correctly");
  }
}

contract _ExtractSqrtPriceLimitX96 is PositionRouterTest {
  function testFuzz_SuccessfullyExtractsSqrtPriceLimitX96(uint8 funcId, uint160 sqrtPriceLimitX96)
    public
  {
    PerpetualPositionRouterTestHarness harness = new PerpetualPositionRouterTestHarness(
      clearingHouse,
      accountBalance,
      VETH
    );
    assertEq(
      harness.extractSqrtPriceLimitX96(encodeArgs(funcId, sqrtPriceLimitX96)), sqrtPriceLimitX96
    );
  }

  function testFuzz_SuccessfullyReencodeArgs(uint168 args) public {
    PerpetualPositionRouterTestHarness harness = new PerpetualPositionRouterTestHarness(
      clearingHouse,
      accountBalance,
      VETH
    );
    uint168 firstEightBitMask = ((1 << 8) - 1) << 160;
    uint8 funcId = uint8((args & firstEightBitMask) >> 160);
    assertEq(encodeArgs(funcId, harness.extractSqrtPriceLimitX96(args)), args);
  }
}

contract Fallback is PositionRouterTest {
  PerpetualRouterFactory factory;

  function setUp() public override {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(clearingHouse, accountBalance, vault);
    factory.deploy(PerpetualRouterFactory.RouterType.PositionRouterType, VETH);
    deal(address(this), 100 ether);
    vault.depositEther{value: 10 ether}();
    vethPositionRouterAddr =
      address(factory.computeAddress(PerpetualRouterFactory.RouterType.PositionRouterType, VETH));
  }

  function testFork_OpenLongExactInputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = encodeArgs(4, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    // Long position is represented as a negative number
    assertEq(info.takerOpenNotional, -1 ether);
    // Meant to prevent regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerPositionSize, 538_599_759_293_451);
  }

  function testFork_OpenLongExactOutputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = encodeArgs(3, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);

    assertTrue(ok);

    // Long position is represented as a negative number
    assertEq(info.takerOpenNotional, -1_856_697_038_719_929_142_024);
    // Meant to prevent a regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerPositionSize, 1 ether);
  }

  function testFork_OpenShortExactInputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = encodeArgs(2, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    // Short position is represented as a positive number
    // Meant to prevent a regression. Number was sourced
    // from running this test in a working state.
    assertEq(info.takerOpenNotional, 1_852_924_032_181_202_909_050);
    assertEq(info.takerPositionSize, -1 ether);
  }

  function testFork_OpenShortExactOutputPosition() public {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint168 combinedArgs = encodeArgs(1, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);
    // Short position is represented as a positive number
    assertEq(info.takerOpenNotional, 1 ether);
    // Meant to prevent regression number was sourced
    // from running test in a working state.
    assertEq(info.takerPositionSize, -539_678_586_420_661);
  }

  function testFork_CloseLongExactInputPosition() public {
    closePositionHelper(4, 1 ether, 0, 0);
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_CloseLongExactOutputPosition() public {
    closePositionHelper(3, 1 ether, 0, 0);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_CloseShortExactInputPosition() public {
    closePositionHelper(2, 5 ether, 0, 0);

    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function testFork_CloseShortExactOutputPosition() public {
    closePositionHelper(1, 1 ether, 0, 0);
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, 0);
    assertEq(info.takerPositionSize, 0);
  }

  function test_FailedCallWhenExtraCalldataArgument() public {
    uint168 combinedArgs = encodeArgs(4, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0, 100));
    assertTrue(!ok);
  }

  function test_FailedClosePositionCallWithWrongArguments() public {
    uint168 combinedArgs = encodeArgs(5, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    assertTrue(!ok);
  }

  function test_FailedFallbackWithZeroFuncId() public {
    uint168 combinedArgs = encodeArgs(0, 0);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    assertTrue(!ok);
  }
}
