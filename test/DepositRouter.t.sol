// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "forge-std/Test.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {PerpetualContracts} from "test/PerpetualContracts.sol";
import {PerpetualRouterFactory} from "src/Perpetual.sol";

contract DepositRouterForkTestBase is Test, PerpetualContracts {
  PerpetualRouterFactory factory;

  function setUp() public {
    vm.createSelectFork(vm.rpcUrl("optimism"), 87_407_144);
    factory = new PerpetualRouterFactory(
            clearingHouse,
            accountBalance,
            vault
        );
    factory.deploy(PerpetualRouterFactory.RouterTypes.DepositRouterType, USDC);
    deal(USDC, address(this), 100_000_000);
    deal(address(this), 100 ether);
  }
}

// Add deposit interface
contract DepositForkTest is DepositRouterForkTestBase {
  function test_Deposit() public {
    address routerAddress =
      address(factory.computeAddress(PerpetualRouterFactory.RouterTypes.DepositRouterType, USDC));
    uint256 amount = 1_000_000;

    ERC20(USDC).approve(routerAddress, amount);
    (bool ok,) = payable(routerAddress).call(abi.encode(amount));
    int256 balance = vault.getBalanceByToken(address(this), USDC);
    assertTrue(ok);
    assertEq(balance, 1_000_000);
  }

  function test_DepositEth() public {
    address routerAddress = address(
      factory.computeAddress(PerpetualRouterFactory.RouterTypes.DepositRouterType, address(USDC))
    );
    (bool ok,) = payable(routerAddress).call{value: 1 ether}("");
    int256 balance = vault.getBalanceByToken(address(this), WETH);
    assertTrue(ok);
    assertEq(balance, 1 ether);
  }
}
