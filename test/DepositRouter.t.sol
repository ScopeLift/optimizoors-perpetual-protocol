// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {DepositRouter} from "src/DepositRouter.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";
import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";

contract DepositRouterTest is Test, PerpetualContracts {
  PerpetualRouterFactory factory;
  address routerAddress;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(clearingHouse, accountBalance, vault);
    factory.deploy(PerpetualRouterFactory.RouterType.DepositRouterType, USDC);
    routerAddress =
      address(factory.computeAddress(PerpetualRouterFactory.RouterType.DepositRouterType, USDC));
  }
}

contract Constructor is DepositRouterTest {
  function test_CorrectlySetsAllConstructorArgs() public {
    DepositRouter router = new DepositRouter(VETH, vault);
    assertEq(address(router.PERPETUAL_VAULT()), address(vault), "VAULT not set correctly");
    assertEq(router.TOKEN(), VETH, "TOKEN not set correctly");
  }
}

contract Fallback is DepositRouterTest {
  function testForkFuzz_TraderDepositsUsdcIntoVault(uint256 amount) public {
    uint256 settlementTokenBalanceCap = clearingHouseConfig.getSettlementTokenBalanceCap();
    uint256 vaultBalance = ERC20(USDC).balanceOf(address(vault));

    amount = bound(amount, 1, settlementTokenBalanceCap - vaultBalance);

    deal(USDC, address(this), amount);
    ERC20(USDC).approve(routerAddress, amount);

    (bool ok,) = payable(routerAddress).call(abi.encode(amount));

    int256 balance = vault.getBalanceByToken(address(this), USDC);
    assertTrue(ok);
    assertEq(balance, int256(amount));
  }
}

contract Receive is DepositRouterTest {
  function testForkFuzz_TraderDepositsEtherIntoVault(uint256 amount) public {
    uint256 depositCap = collateralManager.getCollateralConfig(WETH).depositCap;
    uint256 vaultBalance = ERC20(WETH).balanceOf(address(vault));

    amount = bound(amount, 1, depositCap - vaultBalance);

    deal(address(this), amount);
    (bool ok,) = payable(routerAddress).call{value: amount}("");
    int256 balance = vault.getBalanceByToken(address(this), WETH);
    assertTrue(ok);
    assertEq(balance, int256(amount));
  }
}
