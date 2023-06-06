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

  function extractSqrtPriceLimitX96(uint200 args) external pure returns (uint160) {
    return _extractSqrtPriceLimitX96(args);
  }

  function extractDeadline(uint200 args) external pure returns (uint32) {
    return _extractDeadline(args);
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

  function encodeArgs(uint8 funcId, uint160 sqrtPriceLimitX96, uint32 deadline)
    internal
    pure
    returns (uint200)
  {
    return (uint200(funcId) << 192) | uint200(sqrtPriceLimitX96) << 32 | uint200(deadline);
  }

  function closePositionHelper(
    uint8 openFunc,
    uint256 amount,
    uint256 oppositeAmountBound,
    uint160 sqrtPriceLimitX96
  ) internal {
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint200 openCombinedArgs = encodeArgs(openFunc, sqrtPriceLimitX96, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(
      abi.encode(openCombinedArgs, amount, oppositeAmountBound)
    );
    uint200 closeCombinedArgs = encodeArgs(5, sqrtPriceLimitX96, type(uint32).max);
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

contract _ExtractDeadline is PositionRouterTest {
  function testFuzz_SuccessfullyExtractsDeadline(
    uint8 funcId,
    uint160 sqrtPriceLimitX96,
    uint32 deadline
  ) public {
    PerpetualPositionRouterTestHarness harness = new PerpetualPositionRouterTestHarness(
      clearingHouse,
      accountBalance,
      VETH
    );

    assertEq(harness.extractDeadline(encodeArgs(funcId, sqrtPriceLimitX96, deadline)), deadline);
  }
}

contract _ExtractSqrtPriceLimitX96 is PositionRouterTest {
  function testFuzz_SuccessfullyExtractsSqrtPriceLimitX96(
    uint8 funcId,
    uint160 sqrtPriceLimitX96,
    uint32 deadline
  ) public {
    PerpetualPositionRouterTestHarness harness = new PerpetualPositionRouterTestHarness(
      clearingHouse,
      accountBalance,
      VETH
    );
    assertEq(
      harness.extractSqrtPriceLimitX96(encodeArgs(funcId, sqrtPriceLimitX96, deadline)),
      sqrtPriceLimitX96
    );
  }

  function testFuzz_SuccessfullyReencodeArgs(uint200 args) public {
    PerpetualPositionRouterTestHarness harness = new PerpetualPositionRouterTestHarness(
      clearingHouse,
      accountBalance,
      VETH
    );
    uint200 firstEightBitMask = ((1 << 8) - 1) << 192;
    uint8 funcId = uint8((args & firstEightBitMask) >> 192);
    assertEq(
      encodeArgs(funcId, harness.extractSqrtPriceLimitX96(args), harness.extractDeadline(args)),
      args
    );
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

  function helper_native_openPosition(
    address token,
    bool isBaseToQuote,
    bool isExactInput,
    uint256 amount,
    uint256 oppositeAmountBound,
    uint256 deadline,
    uint160 sqrtPriceLimitX96
  ) internal {
    clearingHouse.openPosition(
      IClearingHouse.OpenPositionParams({
        baseToken: token,
        isBaseToQuote: isBaseToQuote,
        isExactInput: isExactInput,
        amount: amount,
        oppositeAmountBound: oppositeAmountBound,
        deadline: deadline,
        sqrtPriceLimitX96: sqrtPriceLimitX96,
        referralCode: bytes32("")
      })
    );
  }

  function testFork_OpenLongExactInputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint200 combinedArgs = encodeArgs(4, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    vm.revertTo(snapshotId);
    helper_native_openPosition(VETH, false, true, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
  }

  function testFork_OpenLongExactOutputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint200 combinedArgs = encodeArgs(3, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);

    assertTrue(ok);

    vm.revertTo(snapshotId);
    helper_native_openPosition(VETH, false, false, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
  }

  function testFork_OpenShortExactInputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint200 combinedArgs = encodeArgs(2, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    vm.revertTo(snapshotId);
    helper_native_openPosition(VETH, true, true, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
  }

  function testFork_OpenShortExactOutputPosition() public {
    uint256 snapshotId = vm.snapshot();
    delegateApproval.approve(vethPositionRouterAddr, 1);
    uint200 combinedArgs = encodeArgs(1, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    AccountMarket.Info memory info = accountBalance.getAccountInfo(address(this), VETH);
    assertTrue(ok);

    vm.revertTo(snapshotId);
    helper_native_openPosition(VETH, true, false, uint256(1 ether), 0, type(uint32).max, 0);
    AccountMarket.Info memory nativeInfo = accountBalance.getAccountInfo(address(this), VETH);
    assertEq(info.takerOpenNotional, nativeInfo.takerOpenNotional);
    assertEq(info.takerPositionSize, nativeInfo.takerPositionSize);
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

  function testFork_FailedCallWhenExtraCalldataArgument() public {
    uint200 combinedArgs = encodeArgs(4, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0, 100));
    assertTrue(!ok);
  }

  function testFork_FailedClosePositionCallWithWrongArguments() public {
    uint200 combinedArgs = encodeArgs(5, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    assertTrue(!ok);
  }

  function testFork_FailedFallbackWithZeroFuncId() public {
    uint200 combinedArgs = encodeArgs(0, 0, type(uint32).max);
    (bool ok,) = payable(vethPositionRouterAddr).call(abi.encode(combinedArgs, 1 ether, 0));
    assertTrue(!ok);
  }
}
