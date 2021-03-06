//stake: lock tokens into our smart contract
// withdraw: unlock tokens & pull out of the contract
// claimreward: users get their reward tokens
// what's a good reward mechanism?
// what's some good reward math

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error Staking__TransferFailed();
error Staking_NeedsMoreThanZero();

contract Staking{
IERC20 public s_stakingToken;
IERC20 public s_rewardToken;

//someone address-> how much they staked
mapping(address => uint256) public s_balances;

//a mapping of how much each address has been paid
mapping(address => uint256) public s_userRewardPerTokenPaid ;

//a mapping of how much rewards each address has to claim
mapping(address => uint256) public s_rewards;

//reward per second
uint256 public constant REWARD_RATE = 100;
//total token in the contract
uint256 public s_totalSupply;
uint256 public s_rewardPerTokenStored;
uint256 public s_lastUpdateTime;

modifier updateReward(address account){
    //how much reward per token?
    //last timestamp
    //12-1, user earned x tokens
    s_rewardPerTokenStored = rewardPerToken();
    s_lastUpdateTime = block.timestamp;
    s_rewards[account] = earned(account);
    s_userRewardPerTokenPaid[account] = s_rewardPerTokenStored;
    _;
    }

modifier moreThanZero(uint256 amount){
    if(amount == 0){
        revert Staking_NeedsMoreThanZero();
    }
    _;
}

constructor(address stakingToken, address rewardToken){
s_stakingToken = IERC20(stakingToken);
s_rewardToken = IERC20(rewardToken);
}

function earned(address account) public view returns(uint256){
    uint256 currentBalance = s_balances[account];
    //how much they have been paid already
    uint256 amountPaid = s_userRewardPerTokenPaid[account];
    uint256 currentRewardPerToken = rewardPerToken();
    uint256 pastRewards = s_rewards[account];
    uint256 _earned = ((currentBalance*(currentRewardPerToken - amountPaid))/1e18)* pastRewards;
    return _earned;
}

// based on how long it's been during this most recent snapshot
function rewardPerToken() public view returns(uint256){
    if(s_totalSupply == 0){
        return s_rewardPerTokenStored;
    }
    return s_rewardPerTokenStored + (((block.timestamp - s_lastUpdateTime)* REWARD_RATE * 1e18)/ s_totalSupply);
}
//allow only specific token
 
 function stake(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
     //keep track of how much this user has staked
     //keep track of how much token we have in total
     //transfer the tokens to this contract
  s_balances[msg.sender] = s_balances[msg.sender] + amount;
  s_totalSupply = s_totalSupply + amount;

  bool success = s_stakingToken.transferFrom(msg.sender, address(this), amount);
//   require(success,"Failed");
if(!success){
    revert Staking__TransferFailed();
}
 } 

function withdraw(uint256 amount) external updateReward(msg.sender) moreThanZero(amount){
    s_balances[msg.sender] = s_balances[msg.sender] - amount;
    s_totalSupply = s_totalSupply - amount;
    bool success = s_stakingToken.transfer(msg.sender,amount);

    if(!success){
        revert Staking__TransferFailed();
    }
} 

function claimReward() external updateReward(msg.sender) {

    uint256 reward = s_rewards[msg.sender];
    bool success = s_rewardToken.transfer(msg.sender, reward);

    if(!success){
      revert Staking__TransferFailed();
    }
    
    //How much reward do they get?
    //the contract is going to emit X tokens per sec
    // and  disperse them to all token stakers

    //100 tokens/sec
    //staked:50 staked tokens, 20 staked tokens, 30 staked tokens
    //rewards: 50 reward tokens, 20 reward tokens, 30 reward tokens

    //staked: 100,50,20,30(total = 200)
    //rewards : 50,25,10,15

    //why not 1 to 1? bankruptyour protocol

    // 5 seconds, 1 person had 100 token staked = reward 500 tokens
    // 6 seconds , 2 person have 100 tokens staked each:
    // Person 1: 550
    // Person 2: 50

    // ok between seconds 1 and 5, person 1 got 500 tokens
    // ok at second 6 on, person 1 gets 50 tokens now 
}
 }

