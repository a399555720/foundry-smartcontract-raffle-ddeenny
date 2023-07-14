// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {DeployRaffle} from "../../script/DeployRaffle.s.sol";
import {Raffle} from "../../src/Raffle.sol";
import {PriceConverter} from "../../src/PriceConverter.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {VRFCoordinatorV2Mock} from "../mocks/VRFCoordinatorV2Mock.sol";
import {CreateSubscription} from "../../script/Interactions.s.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract RaffleTest is StdCheats, Test {
    using PriceConverter for uint256;

    // Declare public variables to be used in the tests.
    Raffle public raffle;
    HelperConfig public helperConfig;
    bytes32 gasLane;
    uint32 callbackGasLimit;
    address vrfCoordinatorV2;
    address ethUsdPriceFeed;
    address public PLAYER = makeAddr("player");
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public raffleEntranceFee;

    // Declare events to be used in the tests.
    event RequestedRaffleWinner(uint256 indexed requestId);
    event WinnerPicked(address indexed player);

    // This function is called before each test to set up the test environment.
    function setUp() external {
        // Deploy a new Raffle and HelperConfig contract for each test.
        DeployRaffle deployer = new DeployRaffle();
        (raffle, helperConfig) = deployer.run();
        // Set the raffle entrance fee and give the PLAYER account some starting ether.
        raffleEntranceFee = raffle.getEntranceFeeInEth();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
        // Get the variables from the HelperConfig contract.
        (, gasLane, callbackGasLimit, vrfCoordinatorV2, ethUsdPriceFeed,,) = helperConfig.activeNetworkConfig();
    }

    /////////////////////////
    // constructor         //
    /////////////////////////

    // Test that the USD to ETH conversion is correct.
    function testUsdToEthIsCorrect() public view {
        // Check that 100 USD is equal to the raffle entrance fee in ETH.
        assert(
            100e18 / PriceConverter.getPrice(AggregatorV3Interface(ethUsdPriceFeed))
                == raffle.getEntranceFeeInEth() / 10e18
        );
    }

    // Test that the Raffle contract initializes in the open state.
    function testRaffleInitializesInOpenState() public view {
        assert(raffle.getRaffleState() == Raffle.RaffleState.OPEN);
    }

    // Test that the aggregator and vrfCoordinator address are correct.
    function testAggregatorAndvrfcoordinatorAddressCorrectly() public {
        address aggregatorResponse = address(raffle.getPriceFeed());
        address vrfcoordinatorResponse = address(raffle.getVRFCoordinator());
        assertEq(vrfcoordinatorResponse, vrfCoordinatorV2);
        assertEq(aggregatorResponse, ethUsdPriceFeed);
    }

    /////////////////////////
    // enterRaffle         //
    /////////////////////////

    // Test that an error is thrown when the player doesn't pay enough ETH to enter the raffle.
    function testWhenYouDontPayEnoughETH() public {
        vm.prank(PLAYER);
        bytes memory customError = abi.encodeWithSignature("Raffle__SendMoreToEnterRaffle()");
        vm.expectRevert(customError);
        raffle.enterRaffle();
    }

    // Test that the raffle state changes to calculating when the player enter raffle.
    function testChangeTheStateToCalculation() public {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        bytes memory customError = abi.encodeWithSignature("Raffle__RaffleNotOpen()");
        vm.prank(PLAYER);
        vm.expectRevert(customError);
        raffle.enterRaffle{value: raffleEntranceFee}();
        assert(raffle.getRaffleState() == Raffle.RaffleState.CALCULATING);
    }

    // This function tests sending 10% of the entrance fee to the owner of the raffle
    function testSendTenPercentEntranceFeeToOwner() public {
        address owner = raffle.getOwner();
        uint256 startOwnerBalance = owner.balance;
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        uint256 endOwnerBalance = owner.balance;
        startOwnerBalance += raffleEntranceFee / 10;
        assertEq(startOwnerBalance, endOwnerBalance);
    }

    // This function tests updating the request ID
    function testUpdateTheRequestId() public {
        vm.prank(PLAYER);
        vm.recordLogs();
        raffle.enterRaffle{value: raffleEntranceFee}();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 requestId = uint256(bytes32(entries[1].topics[1]));
        assert(requestId > 0);
    }

    /////////////////////////
    // fulfillRandomWords //
    ////////////////////////

    // This modifier skips the fork if the chain ID is not equal to 31337
    modifier skipFork() {
        if (block.chainid != 31337) {
            return;
        }
        _;
    }

    // This function tests emitting the requested raffle winner event on enter
    function testEmitsTheRequestedRaffleWinnerEventOnEnter() public skipFork {
        vm.prank(PLAYER);
        vm.recordLogs();
        raffle.enterRaffle{value: raffleEntranceFee}();
        Vm.Log[] memory entries = vm.getRecordedLogs();
        uint256 requestId = uint256(bytes32(entries[1].topics[1]));
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(requestId, address(raffle));
        vm.expectEmit(true, false, false, false, address(raffle));
        emit RequestedRaffleWinner(requestId + 1);
        raffle.enterRaffle{value: raffleEntranceFee}();
    }

    // This function use fuzz testing tests that fulfillRandomWords can only be called if there is already a request ID
    function testFulfillRandomWordsCanOnlyBeCalledAlreadyHaveRequestId(uint256 requestId) public skipFork {
        vm.prank(PLAYER);
        raffle.enterRaffle{value: raffleEntranceFee}();
        vm.assume(requestId > 1 || requestId == 0);
        vm.expectRevert("nonexistent request");
        VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(requestId, address(raffle));
    }

    // This function tests that fulfillRandomWords picks a winner, resets the raffle, and sends the money
    function testFulfillRandomWordsPicksAWinnerResetsAndSendsMoney() public skipFork {
        uint256 startingBalance;
        uint256 raffleBalance;
        uint32 i;
        while (true) {
            i++;
            vm.recordLogs();
            vm.prank(PLAYER);
            raffle.enterRaffle{value: raffleEntranceFee}();
            startingBalance = PLAYER.balance;
            raffleBalance = address(raffle).balance;
            Vm.Log[] memory entries = vm.getRecordedLogs();
            uint256 requestId = uint256(bytes32(entries[1].topics[1]));
            // Will win when execute the 8th time in mock
            if (i == 8) {
                vm.expectEmit(true, false, false, false, address(raffle));
                emit WinnerPicked(PLAYER);
                VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(requestId, address(raffle));
            } else {
                VRFCoordinatorV2Mock(vrfCoordinatorV2).fulfillRandomWords(requestId, address(raffle));
            }
            // If the recent random number is equal to the prize number, break out of the loop
            if (raffle.getRecentRandNum() == raffle.getPrizeNumber()) {
                break;
            }
        }
        // Check that the recent winner is the player
        assert(raffle.getRecentWinner() == PLAYER);
        // Check that the raffle state is changes to open
        assert(uint8(raffle.getRaffleState()) == 0);
        // Check that the player's balance has increased by 90% of the raffle balance
        assert(PLAYER.balance == startingBalance + (raffleBalance * 9) / 10);
    }
}
