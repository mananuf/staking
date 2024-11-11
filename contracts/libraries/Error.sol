// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

library Error {

    error Not_AUTHORIZED();

    error INVALID_POOL();

    error AMOUNT_IS_BELOW_MINIMUM_FEE();

    error UNIDENTIFIED_STAKE();

    error ADDRESS_NOT_SUPPORTED();

    error INSUFICIENT_STAKE_BALANCE();
}