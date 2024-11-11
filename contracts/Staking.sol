// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import { Error } from "./libraries/Error.sol";
import { Event } from "./libraries/Event.sol";
import { IERC20 } from "contracts/interfaces/IERC20.sol";

contract Staking {
    uint constant ONE_YEAR = 365 days;
    address stakingOperator;
    IERC20 token;

    struct PoolInfo {
        string name;
        uint8 percentageYield;
        uint8 minFee;
    }
    PoolInfo[] pools;

    struct StakeInfo{
        uint amount;
        uint startedAt;
        uint endedAt;
        bool rewardClaimed;
    }

    mapping(uint => mapping(address => StakeInfo)) stakes;

    constructor(address _deployer, address _token) {
        stakingOperator = _deployer;
        token = IERC20(_token);
    }

    modifier onlyStakingOperator {
        require(msg.sender == stakingOperator, Error.Not_AUTHORIZED());
        _;
    }

    function createPool(string memory _name, uint8 _percentageYield, uint8 _minFee) 
    external 
    onlyStakingOperator {

        PoolInfo memory newPool = PoolInfo({
            name: _name,
            percentageYield: _percentageYield,
            minFee: _minFee
        });

        pools.push(newPool);

        emit Event.PoolCreatedSuccessfully(_name, _percentageYield, _minFee);
    }

    function stakeInPool(uint8 _poolId, uint _amount) external {

        PoolInfo memory selectedPool = pools[_poolId];

        require(msg.sender != address(0));
        require(selectedPool.minFee != 0, Error.INVALID_POOL());
        require(selectedPool.minFee < _amount, Error.AMOUNT_IS_BELOW_MINIMUM_FEE());
        require(token.balanceOf(msg.sender) > _amount, Error.INSUFICIENT_STAKE_BALANCE());
    
        token.transferFrom(msg.sender, address(this), _amount);
        
        stakes[_poolId][msg.sender] = StakeInfo({
            amount: _amount,
            startedAt: block.timestamp,
            endedAt: 0,
            rewardClaimed: false
        });

        emit Event.StakeCreatedSuccessfully(msg.sender, _amount, stakes[_poolId][msg.sender].startedAt, _poolId);
    }

    function claimReward(uint8 _poolId) external {
        StakeInfo memory stake = stakes[_poolId][msg.sender];

        require(msg.sender != address(0), Error.ADDRESS_NOT_SUPPORTED());
        require(stake.startedAt != 0, Error.UNIDENTIFIED_STAKE());
        require(stake.amount != 0, Error.INSUFICIENT_STAKE_BALANCE());

        uint amount = stake.amount;
        stake.endedAt = block.timestamp;
        stake.rewardClaimed = true;

        uint reward = calculateReward(_poolId);

        stake.amount = 0; 

        token.transferFrom(stakingOperator, msg.sender, reward + amount);
    }

    function calculateReward(uint8 _poolId) 
    internal
    view 
    returns (uint apy) 
    {
        // A is the future value of the investment/loan, including interest.
        // P is the principal investment amount (initial deposit or loan amount).
        // r is the annual interest rate (in decimal form).
        // t is the number of years.

        PoolInfo memory pool = pools[_poolId];
        StakeInfo memory stake = stakes[_poolId][msg.sender];
        uint noOfdaysStaked = (stake.endedAt - stake.startedAt) / 1 days;

        apy = stake.amount * (uint256(1) + (uint256(pool.percentageYield) / 100)) ** (noOfdaysStaked / ONE_YEAR);
    }
}