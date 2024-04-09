// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IUniswapV2Router02 {
    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

contract EquityPurchase {
    struct User {
        address[] downlines;
        uint256 depositAmount;
        bool exists;
        address referrer; 
        uint256 referralRewardReceived;
    }
    
    constructor() {
        users[msg.sender] = User(new address[](0), 0, true, address(0), 0);
    }
    
    uint256 public dailyReward = 0;
    mapping(address => User) public users;
    
    event Deposit(address indexed user, uint256 amount);
    event ReferralReward(address indexed referrer, address indexed downline, uint256 amount);
    
    function deposit(address referrer) external payable {
        // exchange rate of BNB/USDT
        address[] memory path = new address[](2);
        path[0] = address(this); 
        path[1] = address(0x55d398326f99059fF775485246999027B3197955); 

        IUniswapV2Router02 uniswapRouter = IUniswapV2Router02(0x10ED43C718714eb63d5aA57B78B54704E256024E);
        uint[] memory amounts = uniswapRouter.getAmountsOut(msg.value, path);
        require(amounts[1] >= 300 * 1e18, "Insufficient USDT equivalent value");

        require(!users[msg.sender].exists, "User already exists");
        require(users[referrer].exists || referrer == address(0), "Referrer does not exist");
        
        users[msg.sender] = User(new address[](0), msg.value, true, referrer, 0);
        
        if (referrer != address(0)) {
            users[referrer].downlines.push(msg.sender);
            addUserToDownlines(referrer, msg.sender, 1);
        }
        
        emit Deposit(msg.sender, msg.value);
        
        distributeReferralRewards(msg.sender, msg.value, 1);
    }
    
    function addUserToDownlines(address referrer, address downline, uint256 level) public {
        if (level >= 10 || referrer == address(0)) {
            return;
        }
        
        users[referrer].downlines.push(downline);
        address indirectReferrer = users[referrer].referrer;
        addUserToDownlines(indirectReferrer, downline, level + 1);
    }
    
    function distributeReferralRewards(address user, uint256 amount, uint256 level) public {
        if (level > 10) {
            return;
        }
        
        address referrer = users[user].downlines[0];
        
        uint256 referralReward = 0;
        if (level == 1) {
            // First referrer in downline gets 7% of ROI once 
            referralReward = amount * 7 / 100;
            users[referrer].referralRewardReceived += referralReward;
            dailyReward = (amount * 15 / 100) / 1 days; // 15% of ROI daily
            users[referrer].referralRewardReceived += dailyReward;
        } else if (level == 2) {
            // Second referrer in downline gets 2% of ROI once
            referralReward = amount * 2 / 100;
            users[referrer].referralRewardReceived += referralReward;
            dailyReward = (amount * 10 / 100) / 1 days; // 10% of ROI daily
            users[referrer].referralRewardReceived += dailyReward;
        } else if (level >= 3 && level <= 10) {
            // Third to tenth referrer in downline gets 1% of ROI once
            referralReward = amount / 100;
            users[referrer].referralRewardReceived += referralReward;
            if (level >= 3 && level <= 5) {
                dailyReward = (amount * 7 / 100) / 1 days; // 7% of ROI daily
                users[referrer].referralRewardReceived += dailyReward;
            } else if (level >= 6 && level <= 8) {
                dailyReward = (amount * 4 / 100) / 1 days; // 4% of ROI daily
                users[referrer].referralRewardReceived += dailyReward;
            } else if (level >= 9 && level <= 10) {
                dailyReward = (amount * 3 / 100) / 1 days; // 4% of ROI daily
                users[referrer].referralRewardReceived += dailyReward;
            }
        }
        
        payable(referrer).transfer(referralReward + dailyReward);
        emit ReferralReward(referrer, user, referralReward + dailyReward);
        
        distributeReferralRewards(referrer, amount, level + 1);
    }
}
