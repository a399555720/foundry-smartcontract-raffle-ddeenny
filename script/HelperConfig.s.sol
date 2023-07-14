// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "../test/mocks/VRFCoordinatorV2Mock.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";
import {LinkToken} from "../test/mocks/LinkToken.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;

    // Struct that defines the network configuration.
    struct NetworkConfig {
        uint64 subscriptionId; // Id of subscription to use
        bytes32 gasLane; // Address of the gas lane contract
        uint32 callbackGasLimit; // Gas limit for callbacks
        address vrfCoordinatorV2; // Address of the VRF coordinator
        address ethUsdPriceFeed; // Address of the ETH/USD price feed contract
        address link; // Address of the LINK token contract
        uint256 deployerKey; // Private key of the deployer
    }

    uint256 public DEFAULT_ANVIL_PRIVATE_KEY = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;

    // Event emitted when a mock VRF coordinator is created.
    event HelperConfig__CreatedMockVRFCoordinator(address vrfCoordinator);

    // Constructor that sets the active network configuration based on the chain id.
    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else {
            activeNetworkConfig = getOrCreateAnvilEthConfig();
        }
    }

    // Returns the network configuration for Sepolia.
    function getSepoliaEthConfig() public view returns (NetworkConfig memory sepoliaNetworkConfig) {
        sepoliaNetworkConfig = NetworkConfig({
            subscriptionId: 2742,
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
            ethUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            link: 0x779877A7B0D9E8603169DdbD7836e478b4624789,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }

    // Returns the network configuration for Anvil or creates it if it doesn't exist.
    function getOrCreateAnvilEthConfig() public returns (NetworkConfig memory anvilNetworkConfig) {
        // If an active network configuration for Anvil already exists, return it.
        if (activeNetworkConfig.vrfCoordinatorV2 != address(0) || activeNetworkConfig.ethUsdPriceFeed != address(0)) {
            return activeNetworkConfig;
        }

        // Parameters for deploying VRFCoordinatorV2Mock
        uint96 baseFee = 0.25 ether;
        uint96 gasPriceLink = 1e9;

        // Parameters for deploying MockV3Aggregator
        uint8 decimal = 8;
        int256 initialPrice = 200000000000; // 2000

        // Start a broadcast transaction.
        vm.startBroadcast(DEFAULT_ANVIL_PRIVATE_KEY);
        VRFCoordinatorV2Mock vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );

        // Deploy VRFCoordinatorV2Mock.
        MockV3Aggregator mockV3Aggregator = new MockV3Aggregator(
            decimal,
            initialPrice
        );

        // Deploy MockV3Aggregator.
        LinkToken link = new LinkToken();
        vm.stopBroadcast();

        // Emitan event indicating that a mock VRF coordinator has been created.
        emit HelperConfig__CreatedMockVRFCoordinator(address(vrfCoordinatorV2Mock));

        // Set the network configuration for Anvil.
        anvilNetworkConfig = NetworkConfig({
            subscriptionId: 0, // If left as 0, our scripts will create one!
            gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
            callbackGasLimit: 500000, // 500,000 gas
            vrfCoordinatorV2: address(vrfCoordinatorV2Mock),
            ethUsdPriceFeed: address(mockV3Aggregator),
            link: address(link),
            deployerKey: DEFAULT_ANVIL_PRIVATE_KEY
        });
    }
}
