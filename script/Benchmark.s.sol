import {Script, stdJson} from "forge-std/Script.sol";
import {DepositRouter} from "src/DepositRouter.sol";
import {PerpetualRouterFactory} from "src/PerpetualRouterFactory.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {IVault} from "src/interface/IVault.sol";
import {IClearingHouse} from "src/interface/IClearingHouse.sol";
import {IDelegateApproval} from "test/interface/IDelegateApproval.sol";

contract Benchmark is Script {
  using stdJson for string;

  IVault vault = IVault(0xAD7b4C162707E0B2b5f6fdDbD3f8538A5fbA0d60);
  IClearingHouse clearingHouse = IClearingHouse(0x82ac2CE43e33683c58BE4cDc40975E73aA50f459);

  IDelegateApproval delegateApproval = IDelegateApproval(0xfd7bB5F6844a43c5469c972640Eddfa99597a547);
  address public immutable VETH = 0x8C835DFaA34e2AE61775e80EE29E2c724c6AE2BB;
  address public immutable USDC = 0x7F5c764cBc14f9669B88837ca1490cCa17c31607;

  function run() public {
    require(block.chainid == 10, "script can only be run on optimism");
    string memory file = "broadcast/Deploy.s.sol/10/run-latest.json";
    string memory json = vm.readFile(file);

    address depositRtr = json.readAddress(".transactions[1].additionalContracts[0].address");

    address positionRtr = json.readAddress(".transactions[2].additionalContracts[0].address");

    // ===========================
    // ======== Execution ========
    // ===========================

    vm.startBroadcast();
    // Default ETH deposit in perpetual vault
    vault.depositEther{value: 0.00002 ether}();

    // Optimized ETH deposit in perpetual vault
    (bool ok,) = payable(depositRtr).call{value: 0.00002 ether}("");
    require(ok, "Optimized ETH deposit");

    // Default ERC20 deposit in perpetual vault
    ERC20(USDC).approve(address(vault), 250_000);
    vault.deposit(USDC, 250_000);

    // Optimized ERC20 deposit in perpetual vault
    ERC20(USDC).approve(depositRtr, 250_000);
    (bool okDepositUSDC,) = payable(depositRtr).call(abi.encode(250_000));
    require(okDepositUSDC, "Optimized ETH deposit");

    uint256 amount = 0.000000025 ether;
    delegateApproval.approve(positionRtr, 1);

    // Default open exact output short VETH position
    clearingHouse.openPosition(
      IClearingHouse.OpenPositionParams({
        baseToken: VETH,
        isBaseToQuote: true,
        isExactInput: false,
        amount: amount,
        oppositeAmountBound: 0,
        deadline: type(uint256).max,
        sqrtPriceLimitX96: 0,
        referralCode: 0
      })
    );

    // Default close VETH positions
    clearingHouse.closePosition(
      IClearingHouse.ClosePositionParams({
        baseToken: VETH,
        oppositeAmountBound: 0,
        deadline: type(uint256).max,
        sqrtPriceLimitX96: 0,
        referralCode: 0
      })
    );

    // Optimized open exact output short VETH position
    (bool okPosition,) = payable(positionRtr).call(abi.encode(1, amount, 0, 0));
    require(okPosition, "Optimized VETH close position");

    // Optimized close VETH positions
    (bool okClose,) = payable(positionRtr).call(abi.encode(5, 0, 0, 0));
    require(okClose, "Optimized VETH close position");

    vm.stopBroadcast();
  }
}
