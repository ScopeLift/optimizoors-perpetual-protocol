// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Test} from "forge-std/Test.sol";

import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {PerpetualContracts} from "test/PerpetualContracts.sol";

contract RouterFactoryTest is Test, PerpetualContracts {
  function test_deployPositionRouter() public {
    PerpetualRouterFactory factory =
      new PerpetualRouterFactory(clearingHouse, accountBalance, vault);

    address VETHLongInputRouter =
      factory.deploy(PerpetualRouterFactory.RouterTypes.PositionRouterType, VETH);
    assertEq(
      VETHLongInputRouter,
      factory.computeAddress(PerpetualRouterFactory.RouterTypes.PositionRouterType, VETH)
    );
  }

  function test_deployDepositRouter() public {
    PerpetualRouterFactory factory =
      new PerpetualRouterFactory(clearingHouse, accountBalance, vault);

    address USDCDepositRouter =
      factory.deploy(PerpetualRouterFactory.RouterTypes.DepositRouterType, USDC);
    assertEq(
      USDCDepositRouter,
      factory.computeAddress(PerpetualRouterFactory.RouterTypes.DepositRouterType, USDC)
    );
  }
}
