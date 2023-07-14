// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {Raffle} from "../src/Raffle.sol";
import {HelperConfig} from "./HelperConfig.s.sol";
import {AddConsumer, CreateSubscription, FundSubscription} from "./Interactions.s.sol";

contract DeployRaffle is Script {
    // The run function is the main entry point for the contract
    function run() external returns (Raffle, HelperConfig) {
        HelperConfig helperConfig = new HelperConfig();
        AddConsumer addConsumer = new AddConsumer();
        // Retrieve active network configuration values from the helperConfig contract
        (
            uint64 subscriptionId,
            bytes32 gasLane,
            uint32 callbackGasLimit,
            address vrfCoordinatorV2,
            address ethUsdPriceFeed,
            address link,
            uint256 deployerKey
        ) = helperConfig.activeNetworkConfig();

        // If subscriptionId is 0, create a new subscription and fund it
        if (subscriptionId == 0) {
            CreateSubscription createSubscription = new CreateSubscription();
            subscriptionId = createSubscription.createSubscription(vrfCoordinatorV2, deployerKey);

            FundSubscription fundSubscription = new FundSubscription();
            // Fund the newly created subscription
            fundSubscription.fundSubscription(vrfCoordinatorV2, subscriptionId, link, deployerKey);
        }

        // Start a broadcast transaction with the deployer key
        vm.startBroadcast(deployerKey);
        // Deploy a new Raffle contract instance with the required parameters
        Raffle raffle = new Raffle(
            vrfCoordinatorV2,
            ethUsdPriceFeed,
            subscriptionId,
            gasLane,
            callbackGasLimit
        );
        // Stop the broadcast transaction
        vm.stopBroadcast();

        // Add the newly deployed Raffle contract as a consumer to the VRF Coordinator
        addConsumer.addConsumer(address(raffle), vrfCoordinatorV2, subscriptionId, deployerKey);
        // Return the instances of the deployed Raffle and HelperConfig contracts
        return (raffle, helperConfig);
    }
}
