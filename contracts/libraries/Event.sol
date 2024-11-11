// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
library Event {

    event PoolCreatedSuccessfully(string indexed name, uint8 percentageYield, uint8 minFee);

    event StakeCreatedSuccessfully(address indexed staker, uint amount, uint stakedAt, uint8 pool);
}