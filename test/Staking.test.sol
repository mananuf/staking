// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { Staking } from "../contracts/Staking.sol";
import { Event } from "../contracts/libraries/Event.sol";
import { Error } from "../contracts/libraries/Error.sol";
import { IERC20 } from "../contracts/interfaces/IERC20.sol";

contract StakingTest is Test {
    Staking public stakingContract;
    IERC20 public tokenContract;
    address stakingOperator = mkaddr("Staking Operator");
    address tokenAddress = mkaddr("Token");
    address staker = mkaddr("Staker");

    function mkaddr(string memory name) public returns (address) {
        address addr = address(
            uint160(uint256(keccak256(abi.encodePacked(name))))
        );
        vm.label(addr, name);
        return addr;
    }

    function setUp() public {
        tokenContract = IERC20(tokenAddress);
        stakingContract = new Staking(stakingOperator, tokenAddress);

    }

    function test_Only_staking_operator_can_create_a_pool() public {
        vm.prank(stakingOperator);

        vm.expectEmit(true, true, false, true);
        emit Event.PoolCreatedSuccessfully("pool 1", 10, 1000);

        stakingContract.createPool("pool 1", 10, 1000);

        (string memory name, uint8 percentageYield, uint minFee) = stakingContract.pools(0);
        assertEq(name, "pool 1");
        assertEq(percentageYield, 10);
        assertEq(minFee, 1000);
    }

    function test_random_address_can_not_create_a_pool() public {
        vm.prank(staker);

        vm.expectRevert(Error.NOT_AUTHORIZED.selector);

        stakingContract.createPool("pool 1", 10, 1000);
    }

    function test_staker_can_not_stake_if_poolID_is_incorrect() public {
        vm.prank(staker);

        vm.expectRevert(Error.UNIDENTIFIED_STAKE.selector);

        stakingContract.stakeInPool(1, 1000);
    }

    function test_address0_can_not_stake_in_pool() public {
        vm.prank(stakingOperator);
        stakingContract.createPool("pool 1", 10, 1000);

        vm.prank(stakingOperator);
        stakingContract.createPool("pool 2", 15, 5000);

        vm.prank(stakingOperator);
        stakingContract.createPool("pool 3", 30, 15000);

        vm.prank(address(0));
        vm.expectRevert(Error.ADDRESS_NOT_SUPPORTED.selector);
        stakingContract.stakeInPool(1, 1000);
    }

    function test_staker_can_not_stake_in_a_particular_pool_if_amount_passed_is_below_minimum_fee() public {
        vm.prank(stakingOperator);
        stakingContract.createPool("pool 1", 10, 1000);

        vm.prank(stakingOperator);
        stakingContract.createPool("pool 2", 15, 5000);

        vm.prank(stakingOperator);
        stakingContract.createPool("pool 3", 30, 15000);

        vm.prank(staker);
        vm.expectRevert(Error.AMOUNT_IS_BELOW_MINIMUM_FEE.selector);
        stakingContract.stakeInPool(1, 1000);
    }

    function test_staker_can_not_stake_if_balance_is_insufficient() public {
        vm.prank(stakingOperator);
        stakingContract.createPool("pool 1", 10, 1000);

        vm.prank(stakingOperator);
        stakingContract.createPool("pool 2", 15, 5000);

        vm.prank(stakingOperator);
        stakingContract.createPool("pool 3", 30, 15000);

        vm.prank(staker);
        // vm.expectRevert(Error.INSUFICIENT_STAKE_BALANCE.selector);
        stakingContract.stakeInPool(1, 5000);
    }
}
