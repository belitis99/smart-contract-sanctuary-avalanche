// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./TresrStakingUpgradeableV1.sol";
import "./NFKeyStakingUpgradeableV1.sol";
import "./TresrCoinUpgradeableV1.sol";
import "./LpStakingUpgradeableV1.sol";

contract RewardUpgradeableV1 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    address private _tokenAddressContract;
    address private _veTresrAddressContract;
    address private _jlpSmrtAddressContract;
    address private _jlpTresrAddressContract;
    address private _keyLevelAddressContract;

    uint private _keyLevelBonusReward;
    uint private _veTresrBonusReward;
    uint private _jlpSmrtBonusReward;
    uint private _jlpTresrBonusReward;

    mapping(uint => uint) private _claimedKeyLevelBonusReward;
    mapping(address => uint) private _claimedVeTresrBonusReward;
    mapping(address => uint) private _claimedJlpSmrtBonusReward;
    mapping(address => uint) private _claimedJlpTresrBonusReward;

    function initialize(address newTokenAddressContract) public initializer {
        __Ownable_init();
        _tokenAddressContract = newTokenAddressContract;

        _veTresrBonusReward = 350;
        _keyLevelBonusReward = 250;
        _jlpSmrtBonusReward = 200;
        _jlpTresrBonusReward = 200;
    }

    // REWARD CONSTANTS
    function jlpSmrtBonusReward() external view onlyOwner returns (uint) {
        return _jlpSmrtBonusReward;
    }

    function setJlpSmrtBonusReward(uint amount) external onlyOwner {
        _jlpSmrtBonusReward = amount;
    }

    function jlpTresrBonusReward() external view onlyOwner returns (uint) {
        return _jlpTresrBonusReward;
    }

    function setJlpTresrBonusReward(uint amount) external onlyOwner {
        _jlpTresrBonusReward = amount;
    }

    function keyLevelBonusReward() external view onlyOwner returns (uint) {
        return _keyLevelBonusReward;
    }

    function setKeyLevelBonusReward(uint amount) external onlyOwner {
        _keyLevelBonusReward = amount;
    }

    function veTresrBonusReward() external view onlyOwner returns (uint) {
        return _veTresrBonusReward;
    }

    function setVeTresrBonusReward(uint amount) external onlyOwner {
        _veTresrBonusReward = amount;
    }


    // STAKING CONTRACTS
    function veTresrAddressContract() external view onlyOwner returns (address) {
        return _veTresrAddressContract;
    }

    function setVeTresrAddressContract(address newAddress) external onlyOwner {
        _veTresrAddressContract = newAddress;
    }

    function jlpSmrtAddressContract() external view onlyOwner returns (address) {
        return _jlpSmrtAddressContract;
    }

    function setJlpSmrtAddressContract(address newAddress) external onlyOwner {
        _jlpSmrtAddressContract = newAddress;
    }

    function jlpTresrAddressContract() external view onlyOwner returns (address) {
        return _jlpTresrAddressContract;
    }

    function setJlpTresrAddressContract(address newAddress) external onlyOwner {
        _jlpTresrAddressContract = newAddress;
    }

    function keyLevelAddressContract() external view onlyOwner returns (address) {
        return _keyLevelAddressContract;
    }

    function setKeyLevelAddressContract(address newAddress) external onlyOwner {
        _keyLevelAddressContract = newAddress;
    }

    function claimBonus(uint[] memory tokenIDList) public {
        require(_tokenAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint amountReward = 0;

        if (_veTresrAddressContract != address(0)) {
            // claim bonus from veTresr balance
            uint reward = TresrStakingUpgradeableV1(_veTresrAddressContract).getVeTresrBonusReward(msg.sender, block.timestamp) * _veTresrBonusReward / 1000;

            if (_claimedVeTresrBonusReward[msg.sender] <= reward) {
                amountReward += reward - _claimedVeTresrBonusReward[msg.sender];
                _claimedVeTresrBonusReward[msg.sender] += reward;
            }
        }

        if (_jlpSmrtAddressContract != address(0)) {
            // claim bonus from jlpSmrt
            uint reward = LpStakingUpgradeableV1(_jlpSmrtAddressContract).getBonusReward(msg.sender, block.timestamp) * _jlpSmrtBonusReward / 1000;

            if (_claimedJlpSmrtBonusReward[msg.sender] <= reward) {
                amountReward += reward - _claimedJlpSmrtBonusReward[msg.sender];
                _claimedJlpSmrtBonusReward[msg.sender] += reward;
            }
        }

        if (_jlpTresrAddressContract != address(0)) {
            uint reward = LpStakingUpgradeableV1(_jlpTresrAddressContract).getBonusReward(msg.sender, block.timestamp) * _jlpTresrBonusReward / 1000;

            if (_claimedJlpTresrBonusReward[msg.sender] <= reward) {
                amountReward += reward - _claimedJlpTresrBonusReward[msg.sender];
                _claimedJlpTresrBonusReward[msg.sender] += reward;
            }
        }

        if (_keyLevelAddressContract != address(0) && tokenIDList.length > 0) {
            uint reward = NFKeyStakingUpgradeableV1(_keyLevelAddressContract).getBonusReward(tokenIDList, block.timestamp) * _keyLevelBonusReward / 1000;

            uint claimedKeyLevelBonusRewardSum = 0;
            for (uint i = 0; i < tokenIDList.length; i++) {
                claimedKeyLevelBonusRewardSum += _claimedKeyLevelBonusReward[tokenIDList[i]];
            }

            if (claimedKeyLevelBonusRewardSum <= reward) {
                amountReward += reward - claimedKeyLevelBonusRewardSum;
                _claimedKeyLevelBonusReward[tokenIDList[0]] += reward;
            }
        }

        TresrCoinUpgradeableV1(_tokenAddressContract).mint(msg.sender, amountReward);
    }

    function claimBase(uint tokenID) public {
        require(_tokenAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint reward = NFKeyStakingUpgradeableV1(_keyLevelAddressContract).claim(tokenID);
        TresrCoinUpgradeableV1(_tokenAddressContract).mint(msg.sender, reward);
    }

    function claimAll(uint[] memory tokenIDList) external {
        require(_tokenAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint reward = NFKeyStakingUpgradeableV1(_keyLevelAddressContract).claimByTokens(tokenIDList);
        TresrCoinUpgradeableV1(_tokenAddressContract).mint(msg.sender, reward);
        claimBonus(tokenIDList);
    }

    function getVeTresrBonusReward(uint time) external view returns (uint) {
        require(_veTresrAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint reward = TresrStakingUpgradeableV1(_veTresrAddressContract).getVeTresrBonusReward(msg.sender, time) * _veTresrBonusReward / 1000;

        if (_claimedVeTresrBonusReward[msg.sender] >= reward) return 0;
        return reward - _claimedVeTresrBonusReward[msg.sender];
    }

    function getVeTresrBonusRewardPerSecond() external view returns (uint) {
        require(_veTresrAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        return TresrStakingUpgradeableV1(_veTresrAddressContract).getVeTresrBonusRewardPerSecond(msg.sender) * _veTresrBonusReward / 1000;
    }

    function getJlpSmrtBonusReward(uint time) external view returns (uint) {
        require(_jlpSmrtAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint reward = LpStakingUpgradeableV1(_jlpSmrtAddressContract).getBonusReward(msg.sender, time) * _jlpSmrtBonusReward / 1000;

        if (_claimedJlpSmrtBonusReward[msg.sender] >= reward) return 0;
        return reward - _claimedJlpSmrtBonusReward[msg.sender];
    }

    function getJlpSmrtBonusRewardPerSecond() external view returns (uint) {
        require(_jlpSmrtAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        return LpStakingUpgradeableV1(_jlpSmrtAddressContract).getBonusRewardPerSecond(msg.sender) * _jlpSmrtBonusReward / 1000;
    }

    function getJlpTresrBonusReward(uint time) external view returns (uint) {
        require(_jlpTresrAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint reward = LpStakingUpgradeableV1(_jlpTresrAddressContract).getBonusReward(msg.sender, time) * _jlpTresrBonusReward / 1000;

        if (_claimedJlpTresrBonusReward[msg.sender] >= reward) return 0;
        return reward - _claimedJlpTresrBonusReward[msg.sender];
    }

    function getJlpTresrBonusRewardPerSecond() external view returns (uint) {
        require(_jlpTresrAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        return LpStakingUpgradeableV1(_jlpTresrAddressContract).getBonusRewardPerSecond(msg.sender) * _jlpTresrBonusReward / 1000;
    }

    function getKeyLevelBonusReward(uint time, uint[] memory tokenIDList) external view returns (uint) {
        require(_keyLevelAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        uint reward = NFKeyStakingUpgradeableV1(_keyLevelAddressContract).getBonusReward(tokenIDList, time) * _keyLevelBonusReward / 1000;

        uint claimedKeyLevelBonusRewardSum = 0;
        for (uint i = 0; i < tokenIDList.length; i++) {
            claimedKeyLevelBonusRewardSum += _claimedKeyLevelBonusReward[tokenIDList[i]];
        }

        if (claimedKeyLevelBonusRewardSum >= reward) return 0;
        return reward - claimedKeyLevelBonusRewardSum;
    }

    function getKeyLevelBonusRewardPerSecond(uint[] memory tokenIDList, uint time) external view returns (uint) {
        require(_keyLevelAddressContract != address(0), "RewardUpgradeableV1: invalid address");

        return NFKeyStakingUpgradeableV1(_keyLevelAddressContract).getBonusRewardPerSecond(tokenIDList, time) * _keyLevelBonusReward / 1000;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

contract LpStakingUpgradeableV1 is OwnableUpgradeable, ReentrancyGuardUpgradeable, PausableUpgradeable {
    address private _bonusRewardAddressContract;

    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    struct UserInfo {
        uint256 amount;
        uint256 lastStakeTime;
    }

    struct Log {
        uint startDate;
        uint endDate;
        uint amount;
    }

    struct PoolInfo {
        IERC20Upgradeable stakeToken;
        uint256 balance;
    }

    IERC20Upgradeable public token;
    PoolInfo public poolInfo;

    mapping(address => UserInfo) public userStakes;
    mapping(address => Log[]) private logList;

    event Deposit(address user, uint256 amount);
    event Withdraw(address user, uint256 amount);

    function initialize(IERC20Upgradeable _stakingToken, address newBonusRewardAddressContract) public initializer {
        __Ownable_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        _bonusRewardAddressContract = newBonusRewardAddressContract;
        token = _stakingToken;

        poolInfo = PoolInfo({stakeToken : _stakingToken, balance : 0});
    }

    modifier onlyBonusRewardContract() {
        require(_bonusRewardAddressContract == msg.sender, "Caller is not BonusRewardContract");
        _;
    }

    function getStakes(address _user) external view returns (UserInfo memory stakes){
        return userStakes[_user];
    }

    function deposit(uint256 _amount) external nonReentrant whenNotPaused {
        require(poolInfo.stakeToken.allowance(msg.sender, address(this)) >= _amount);
        userStakes[msg.sender].amount += _amount;
        userStakes[msg.sender].lastStakeTime = block.timestamp;

        addLog(msg.sender, userStakes[msg.sender].amount);

        PoolInfo storage pool = poolInfo;
        poolInfo.balance += _amount;

        pool.stakeToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        require(_amount <= userStakes[msg.sender].amount, "Incorrect amount");

        userStakes[msg.sender].amount -= _amount;

        addLog(msg.sender, userStakes[msg.sender].amount);

        poolInfo.balance -= _amount;
        poolInfo.stakeToken.safeTransfer(msg.sender, _amount);

        emit Withdraw(msg.sender, _amount);
    }

    function puase() external onlyOwner {
        _pause();
    }

    function unpuase() external onlyOwner {
        _unpause();
    }

    function getCurrentStaked() public view returns (uint256) {
        return userStakes[msg.sender].amount;
    }

    function calcBonusReward(uint value) public view returns (uint) {
        return value / 3600;
    }

    // DAILY BONUS REWARD --------------------------------------------------
    function addLog(address _account, uint _amount) private {
        uint length = logList[_account].length;

        if (length == 0) {
            logList[_account].push(Log(block.timestamp, 0, _amount));
        } else {
            logList[_account][length - 1].endDate = block.timestamp;
            logList[_account].push(Log(block.timestamp, 0, _amount));
        }
    }

    function getBonusReward(address _account, uint _time) public view onlyBonusRewardContract returns (uint) {
        uint rewardSum = 0;
        uint length = logList[_account].length;

        if (length == 0) return rewardSum;

        for (uint i = 0; i <= length - 1; i++) {
            if (logList[_account][i].endDate == 0) {
                if (logList[_account][i].startDate >= _time) continue;

                rewardSum += (_time - logList[_account][i].startDate) * calcBonusReward(logList[_account][i].amount);
            } else {
                rewardSum += (logList[_account][i].endDate - logList[_account][i].startDate) * calcBonusReward(logList[_account][i].amount);
            }
        }

        return rewardSum;
    }

    function getBonusRewardPerSecond(address _account) public view onlyBonusRewardContract returns (uint) {
        uint length = logList[_account].length;

        if (length == 0) return 0;
        else return calcBonusReward(logList[_account][length - 1].amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TresrStakingUpgradeableV1 is ReentrancyGuardUpgradeable, OwnableUpgradeable {
    address private _tokenAddressContract;
    address private _bonusRewardAddressContract;
    address private _nfkeyStakingAddressContract;
    uint private _stakedAll;
    uint private _rewardConst;

    mapping(address => Reward) private stakedRewards;

    struct Reward {
        uint lastStakeDate;
        uint staked;
        uint rewards;
    }

    function initialize(address newTokenAddressContract, address newBonusRewardAddressContract) initializer public {
        __Ownable_init();

        _tokenAddressContract = newTokenAddressContract;
        _bonusRewardAddressContract = newBonusRewardAddressContract;
        _rewardConst = 2;
    }

    modifier moreThanZero(uint amount) {
        require(amount > 0, "TresrStaking: amount must be more than zero");
        _;
    }

    modifier onlyBonusRewardContract() {
        require(_bonusRewardAddressContract == msg.sender || _nfkeyStakingAddressContract == msg.sender, "TresrStaking: caller is not BonusRewardContract or NFKeyStakingContract");
        _;
    }

    function setRewardConst(uint amount) external onlyOwner() {
        _rewardConst = amount;
    }

    function getRewardConst() external view onlyOwner() returns (uint) {
        return _rewardConst;
    }

    function setNfkeyStakingAddressContract(address account) external onlyOwner() {
        _nfkeyStakingAddressContract = account;
    }

    function getNfkeyStakingAddressContract() external view onlyOwner() returns (address) {
        return _nfkeyStakingAddressContract;
    }

    function getStaked() public view returns (uint) {
        return stakedRewards[msg.sender].staked;
    }

    function getStakedAll() public view returns (uint) {
        return _stakedAll;
    }

    function calcReward(uint value) public view returns (uint) {
        return value * _rewardConst / 100 / 3600;
    }

    function getReward(uint time) public view returns (uint) {
        uint rewardMax = getRewardMax();
        uint rewardSum = stakedRewards[msg.sender].rewards;

        if (stakedRewards[msg.sender].lastStakeDate != 0) {
            if (time > stakedRewards[msg.sender].lastStakeDate) {
                rewardSum += (time - stakedRewards[msg.sender].lastStakeDate) * calcReward(stakedRewards[msg.sender].staked);
            }
        }

        if (rewardSum > rewardMax) return rewardMax;
        return rewardSum;
    }

    function getRewardPerSecond() public view returns (uint) {
        return calcReward(stakedRewards[msg.sender].staked);
    }

    function getRewardMax() public view returns (uint) {
        return stakedRewards[msg.sender].staked * 100;
    }

    function stake(uint amount) external moreThanZero(amount) {
        IERC20Upgradeable(_tokenAddressContract).transferFrom(msg.sender, address(this), amount);

        if (stakedRewards[msg.sender].lastStakeDate != 0) {
            stakedRewards[msg.sender].rewards += (block.timestamp - stakedRewards[msg.sender].lastStakeDate) * calcReward(stakedRewards[msg.sender].staked);
        }

        stakedRewards[msg.sender].staked += amount;
        stakedRewards[msg.sender].lastStakeDate = block.timestamp;

        _stakedAll += amount;
    }

    function unstake(uint amount) external moreThanZero(amount) {
        require(stakedRewards[msg.sender].staked >= amount, "TresrStaking: staked must be more than amount");

        IERC20Upgradeable(_tokenAddressContract).transfer(msg.sender, amount);

        stakedRewards[msg.sender].rewards = 0;
        stakedRewards[msg.sender].staked -= amount;
        stakedRewards[msg.sender].lastStakeDate = block.timestamp;

        _stakedAll -= amount;
    }

    // DAILY BONUS REWARD --------------------------------------------------
    function getVeTresrBonusReward(address account, uint time) public view onlyBonusRewardContract returns (uint) {
        uint rewardMax = stakedRewards[account].staked * 100;
        uint rewardSum = stakedRewards[account].rewards;

        if (stakedRewards[account].lastStakeDate != 0) {
            if (time > stakedRewards[account].lastStakeDate) {
                rewardSum += (time - stakedRewards[account].lastStakeDate) * calcReward(stakedRewards[account].staked);
            }
        }

        if (rewardSum > rewardMax) return rewardMax;
        return rewardSum;
    }

    function getVeTresrBonusRewardMax(address account) public view onlyBonusRewardContract returns (uint) {
        return stakedRewards[account].staked * 100;
    }

    function getVeTresrBonusRewardPerSecond(address account) public view onlyBonusRewardContract returns (uint) {
        return calcReward(stakedRewards[account].staked);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./NFKeyUpgradeableV1.sol";
import "./TresrCoinUpgradeableV1.sol";
import "./TresrStakingUpgradeableV1.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract NFKeyStakingUpgradeableV1 is Initializable, OwnableUpgradeable {
    address private _nfkeyContractAddress;
    address private _tresrCoinContractAddress;
    address private _tresrStakingContractAddress;
    address private _bonusRewardAddressContract;
    uint private _baseReward;
    uint private _chestLevelConst;

    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenIndex;
        uint256 rewardsEarned;
        uint256 rewardsReleased;
    }

    struct Log {
        uint startDate;
        uint endDate;
        uint tier;
        uint level;
    }

    mapping(uint => uint) public tokenRewardsReleasedList;
    mapping(uint => Log[]) private tokenLogList;
    mapping(uint => uint) private treasureRewardAvailableList;
    mapping(uint => bool) private isStakedList;
    mapping(address => bool) private adminAddressList;
    mapping(uint => uint) private chestTierList;

    event Staked(address owner, uint tokenID);
    event Unstaked(address owner, uint tokenID);
    event Opened(address owner, uint tokenID, bool status);

    function initialize(address newNfkeyContractAddress, address newTresrCoinContractAddress, address newBonusRewardAddressContract, address newTresrStakingContractAddress) public initializer {
        __Ownable_init();

        _nfkeyContractAddress = newNfkeyContractAddress;
        _tresrCoinContractAddress = newTresrCoinContractAddress;
        _bonusRewardAddressContract = newBonusRewardAddressContract;
        _tresrStakingContractAddress = newTresrStakingContractAddress;

        _baseReward = 125;
        _chestLevelConst = 250;

        adminAddressList[0xCeaf7780c54bc6815A8d5c3E10fdc965d0F26762] = true;
        adminAddressList[0xbDe951E26aae4F39e20628724f58293A4E6457D4] = true;
        adminAddressList[0x9CB52e780db0Ce66B2c4d8193C3986B5E7114336] = true;
        adminAddressList[msg.sender] = true;
        adminAddressList[newNfkeyContractAddress] = true;
    }

    modifier onlyAdmin() {
        require(adminAddressList[msg.sender], "NFkeyStaking: caller is not the admin");
        _;
    }

    modifier onlyBonusRewardContract() {
        require(_bonusRewardAddressContract == msg.sender, "NFkeyStaking: caller is not BonusRewardContract");
        _;
    }

    function setBaseReward(uint amount) public onlyOwner {
        _baseReward = amount;
    }

    function getBaseReward() public view onlyOwner returns (uint) {
        return _baseReward;
    }

    function setChestLevelConst(uint amount) public onlyOwner {
        _chestLevelConst = amount;
    }

    function getChestLevelConst() public view onlyOwner returns (uint) {
        return _chestLevelConst;
    }

    function addAdmin(address _address) public onlyAdmin {
        adminAddressList[_address] = true;
    }

    function random() private view returns (uint) {
        uint randomHash = uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
        return randomHash % 100;
    }

    function setChestTier(uint tokenID, uint newChestTier) private {
        chestTierList[tokenID] = newChestTier;
    }

    function getChestTier(uint tokenID, uint _time) public view returns (uint) {
        uint chestTier = chestTierList[tokenID];
        uint timeToTreasureUnlock = getTimeToTreasureUnlock(tokenID);

        if (chestTier > 1 && _time > timeToTreasureUnlock) return chestTier - 1;
        return chestTier;
    }

    function addLog(uint tokenID) private {
        NFKeyUpgradeableV1 nfkeyContract = NFKeyUpgradeableV1(_nfkeyContractAddress);

        uint chestTier = getChestTier(tokenID, block.timestamp);
        uint length = tokenLogList[tokenID].length;
        uint level = nfkeyContract.getLevel(tokenID);

        if (isStakedList[tokenID] == true) {
            if (length == 0) {
                tokenLogList[tokenID].push(Log(block.timestamp, 0, chestTier, level));
            } else {
                tokenLogList[tokenID][length - 1].endDate = block.timestamp;
                tokenLogList[tokenID].push(Log(block.timestamp, 0, chestTier, level));
            }
        }
    }

    function proxyAddLog(uint tokenID) public onlyAdmin {
        addLog(tokenID);
    }

    function unstakeLog(uint tokenID) private {
        uint length = tokenLogList[tokenID].length;

        tokenLogList[tokenID][length - 1].endDate = block.timestamp;
    }

    function calcRewards(uint tokenID, uint time) public view returns (uint) {
        uint chestTier = getChestTier(tokenID, time);
        if (chestTier == 0) return 0;

        uint rewardSum = 0;

        for (uint i = 0; i <= tokenLogList[tokenID].length - 1; i++) {
            if (tokenLogList[tokenID][i].endDate == 0) {
                rewardSum += (block.timestamp - tokenLogList[tokenID][i].startDate) * tokenLogList[tokenID][i].level * tokenLogList[tokenID][i].tier * _baseReward;
            } else {
                rewardSum += (tokenLogList[tokenID][i].endDate - tokenLogList[tokenID][i].startDate) * tokenLogList[tokenID][i].level * tokenLogList[tokenID][i].tier * _baseReward;
            }
        }

        uint reward = rewardSum * 10 ** 18 / 1000 / 24 / 60 / 60;
        if (tokenRewardsReleasedList[tokenID] >= reward) return 0;
        return reward - tokenRewardsReleasedList[tokenID];
    }

    function calcRewardsPerSecond(uint tokenID, uint time) public view returns (uint) {
        uint length = tokenLogList[tokenID].length;
        uint chestTier = getChestTier(tokenID, time);

        if (length == 0) return 0;
        else if (chestTier == 0) return 0;
        else return tokenLogList[tokenID][length - 1].level * tokenLogList[tokenID][length - 1].tier * _baseReward * 10 ** 18 / 1000 / 24 / 60 / 60;
    }

    function calcUnlockCost(uint tokenID, uint time) public view returns (uint) {
        NFKeyUpgradeableV1 nfkeyContract = NFKeyUpgradeableV1(_nfkeyContractAddress);

        uint level = nfkeyContract.getLevel(tokenID);
        uint chestTier = getChestTier(tokenID, time) + 1;
        uint chestTierDays = 8 - chestTier;

        return chestTierDays * level * chestTier * 125 * _chestLevelConst * 10 ** 12;
    }

    function calcBaseProbToOpenByTier(uint tier, uint level, uint veTresrRewards, uint veTresrRewardsMax) public view returns (uint) {
        uint probBaseMax = tier == 0 && level <= 10 ? 10000 : 9000;
        uint probBase = 0;
        uint probVeTresr = 0;

        if (tier == 0) probBase = level > 10 ? 8750 : 10000;
        else probBase = (10000 - (12500 * tier / 10));

        if (veTresrRewards > 0 && veTresrRewardsMax > 0) {
            probVeTresr = ((9000 - (10000 - (12000 * (tier + 1) / 10))) * (veTresrRewards * 100 / veTresrRewardsMax)) / 100;
        }

        if (probVeTresr + probBase > probBaseMax) return probBaseMax;
        return probVeTresr + probBase;
    }

    function calcBaseProbToOpen(uint tokenID, uint time, address account) public view returns (uint) {
        uint tier = getChestTier(tokenID, time);
        uint level = NFKeyUpgradeableV1(_nfkeyContractAddress).getLevel(tokenID);
        uint veTresrRewards = TresrStakingUpgradeableV1(_tresrStakingContractAddress).getVeTresrBonusReward(account, time);
        uint veTresrRewardsMax = TresrStakingUpgradeableV1(_tresrStakingContractAddress).getVeTresrBonusRewardMax(account);

        return calcBaseProbToOpenByTier(tier, level, veTresrRewards, veTresrRewardsMax);
    }

    function getTimeToTreasureUnlock(uint tokenId) public view returns (uint) {
        return treasureRewardAvailableList[tokenId];
    }

    function calcTimeCountDown(uint tier) public pure returns (uint) {
        if (tier == 0) return 0;
        return (8 - tier) * 24;
    }

    function updateTreasureRewardTime(uint tokenID) private {
        uint tier = getChestTier(tokenID, block.timestamp);
        uint timeCountDown = calcTimeCountDown(tier);

        treasureRewardAvailableList[tokenID] = block.timestamp + (timeCountDown * 60 * 60);
    }

    function stake(uint tokenID) external {
        NFKeyUpgradeableV1 nfkeyContract = NFKeyUpgradeableV1(_nfkeyContractAddress);

        require(nfkeyContract.ownerOf(tokenID) == msg.sender, "NFkeyStaking: caller is not owner");

        isStakedList[tokenID] = true;

        if (getChestTier(tokenID, block.timestamp) == 0) setChestTier(tokenID, 0);

        addLog(tokenID);
        updateTreasureRewardTime(tokenID);

        emit Staked(msg.sender, tokenID);
    }

    function unstake(uint256 tokenID) external {
        NFKeyUpgradeableV1 nfkeyContract = NFKeyUpgradeableV1(_nfkeyContractAddress);

        require(nfkeyContract.ownerOf(tokenID) == msg.sender, "NFkeyStaking: caller is not owner");

        isStakedList[tokenID] = false;
        treasureRewardAvailableList[tokenID] = 0;
        unstakeLog(tokenID);

        emit Unstaked(msg.sender, tokenID);
    }

    function openChest(uint tokenID) external {
        TresrCoinUpgradeableV1 tresrCoinContract = TresrCoinUpgradeableV1(_tresrCoinContractAddress);
        NFKeyUpgradeableV1 nfkeyContract = NFKeyUpgradeableV1(_nfkeyContractAddress);

        require(nfkeyContract.ownerOf(tokenID) == msg.sender, "NFkeyStaking: caller is not owner");

        uint chestTier = getChestTier(tokenID, block.timestamp);
        uint unlockCost = calcUnlockCost(tokenID, block.timestamp);

        require(chestTier < 7, "NFKeyStaking: Already max chest tier");

        tresrCoinContract.burn(msg.sender, unlockCost);

        uint randomCount = random();
        uint probToOpen = calcBaseProbToOpen(tokenID, block.timestamp, msg.sender);
        uint timeToTreasureUnlock = getTimeToTreasureUnlock(tokenID);
        bool answer = false;

        if ((randomCount * 100) < probToOpen) {
            if (chestTier == 0 || block.timestamp < timeToTreasureUnlock) setChestTier(tokenID, chestTier + 1);
            answer = true;
        }

        updateTreasureRewardTime(tokenID);
        addLog(tokenID);

        emit Opened(msg.sender, tokenID, answer);
    }

    function isTokenStaked(uint tokenID) public view returns (bool) {
        return isStakedList[tokenID];
    }

    // DAILY BONUS REWARD --------------------------------------------------
    function setRewardsReleased(uint amount, uint tokenID) public onlyBonusRewardContract {
        tokenRewardsReleasedList[tokenID] += amount;
    }

    function claim(uint tokenID) public onlyBonusRewardContract returns (uint) {
        uint reward = calcRewards(tokenID, block.timestamp);
        if (reward > 0) setRewardsReleased(reward, tokenID);

        return reward;
    }

    function claimByTokens(uint[] memory tokenIDList) public onlyBonusRewardContract returns (uint) {
        uint length = tokenIDList.length;
        uint rewardAll = 0;

        for (uint i = 0; i <= length - 1; i++) {
            uint reward = calcRewards(tokenIDList[i], block.timestamp);
            if (reward > 0) setRewardsReleased(reward, tokenIDList[i]);

            rewardAll += reward;
        }

        return rewardAll;
    }

    function getBonusReward(uint[] memory tokenIDList, uint time) public view returns (uint) {
        uint length = tokenIDList.length;
        uint rewardAll = 0;

        for (uint i = 0; i <= length - 1; i++) {
            rewardAll += calcRewards(tokenIDList[i], time);
        }

        return rewardAll;
    }

    function getBonusRewardPerSecond(uint[] memory tokenIDList, uint time) public view returns (uint) {
        uint length = tokenIDList.length;
        uint rewardAll = 0;

        for (uint i = 0; i <= length - 1; i++) {
            rewardAll += calcRewardsPerSecond(tokenIDList[i], time);
        }

        return rewardAll;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract TresrCoinUpgradeableV1 is ERC20Upgradeable, OwnableUpgradeable {
    mapping(address => bool) private adminAddressList;

    function initialize() initializer public {
        __ERC20_init("testTresr", "tTRESR");

        adminAddressList[msg.sender] = true;

        _mint(address(0xCeaf7780c54bc6815A8d5c3E10fdc965d0F26762), 100000 * 10 ** 18);
        _mint(address(0xD797d3510e5074891546797f2Ab9105bd0e41bC3), 100000 * 10 ** 18);
        _mint(address(0x44D0b410623a3CF03ae06F782C111F23fADedAdA), 100000 * 10 ** 18);
        _mint(msg.sender, 100000 * 10 ** 18);
    }

    modifier onlyAdmin() {
        require(adminAddressList[msg.sender], "TresrCoin: caller is not admin");
        _;
    }

    function addAdmin(address account) public onlyAdmin {
        adminAddressList[account] = true;
    }

    function mint(address account, uint amount) public onlyAdmin {
        _mint(account, amount);
    }

    function burn(address account, uint amount) public onlyAdmin {
        _burn(account, amount);
    }

    function faucet(address _to) public {
        _mint(address(_to), 100000 * 10**18);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "./WhitelistUpgradeableV1.sol";
import "./SmarterCoinUpgradeableV1.sol";
import "./NFKeyStakingUpgradeableV1.sol";

contract NFKeyUpgradeableV1 is OwnableUpgradeable, ERC721URIStorageUpgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIds;

    address private _whitelistContractAddress;
    address private _smarterCoinContractAddress;
    address private _nfkeyStakingContractAddress;
    uint private _smarterToLevelUp;
    address private _wallet;
    uint private _commission;
    uint private _cap;

    mapping(uint => mapping(uint => string)) private ipfsURIList;
    mapping(address => uint) private availableUpgradeTimestampList;
    mapping(uint => uint) private levelList;
    mapping(uint => uint) private zoneList;

    function initialize(address newWhitelistContractAddress, address newSmarterCoinContractAddress, uint cap) initializer public {
        __Ownable_init();
        __ERC721_init("NFKey", "NFKEY");

        _whitelistContractAddress = newWhitelistContractAddress;
        _smarterCoinContractAddress = newSmarterCoinContractAddress;

        _commission = 10 ** 18;
        if (cap == 0) {
            _cap = 12000;
        } else {
            _cap = cap;
        }
        _smarterToLevelUp = 1850;
        _wallet = msg.sender;
    }

    function getNfkeyStakingContractAddress() public view onlyOwner returns (address) {
        return _nfkeyStakingContractAddress;
    }

    function getCap() public view returns (uint) {
        return _cap;
    }

    function setNfkeyStakingContractAddress(address newAddress) public onlyOwner {
        _nfkeyStakingContractAddress = newAddress;
    }

    function setSmarterToLevelUp(uint amount) public onlyOwner {
        _smarterToLevelUp = amount;
    }

    function getSmarterToLevelUp() public view onlyOwner returns (uint) {
        return _smarterToLevelUp;
    }

    function getAmountUpgradeKey(uint currentTier) public view returns (uint) {
        return ((currentTier + 1) ** 2) * _smarterToLevelUp * 10 ** 18;
    }

    function getIPFS(uint level, uint zone) public view returns (string memory) {
        return ipfsURIList[zone][level];
    }

    function setIPFS(uint level, uint zone, string memory uri) public onlyOwner {
        ipfsURIList[zone][level] = uri;
    }

    function getUpgradeDelay(address account) public view returns (uint) {
        return availableUpgradeTimestampList[account];
    }

    function setUpgradeDelay(address account, uint level) internal {
        if (level <= 3) {
            availableUpgradeTimestampList[account] = block.timestamp + (level * 60 * 60);
        } else {
            availableUpgradeTimestampList[account] = block.timestamp + ((480 + (level * 60)) * 60);
        }
    }

    function setLevel(uint tokenID, uint value) internal {
        levelList[tokenID] = value;
    }

    function getLevel(uint tokenID) public view returns (uint) {
        return levelList[tokenID];
    }

    function setZone(uint tokenID, uint value) internal {
        zoneList[tokenID] = value;
    }

    function getZone(uint tokenID) public view returns (uint) {
        return zoneList[tokenID];
    }

    function getWallet() public view onlyOwner returns (address) {
        return _wallet;
    }

    function setWallet(address account) public onlyOwner {
        _wallet = account;
    }

    function setCommission(uint value) public onlyOwner {
        _commission = value;
    }

    function getCommission() public view returns (uint) {
        return _commission;
    }

    function getZoneDiscount(address account, uint zone) public view returns (uint) {
        uint discount = 0;
        uint amountToken = this.balanceOf(account);

        if (zone == 1) discount = 100;
        else if (zone == 2) discount = 50;
        else if (zone == 3) discount = 20;
        else if (zone == 4) {
            if (amountToken > 1) discount = 10;
            else discount = 5;
        } else {
            discount = 0;
        }

        return discount;
    }

    function getZoneCommission(address account, uint zone) public view returns (uint) {
        uint discount = getZoneDiscount(account, zone);

        return _commission - (_commission * discount / 100);
    }

    function upgradeKey(uint tokenID) public {
        require(ownerOf(tokenID) == msg.sender, "NFKey: You are not an owner");

        NFKeyStakingUpgradeableV1 nfkeyStakingContract = NFKeyStakingUpgradeableV1(_nfkeyStakingContractAddress);
        SmarterCoinUpgradeableV1 smarterCoinContract = SmarterCoinUpgradeableV1(_smarterCoinContractAddress);

        require(block.timestamp >= availableUpgradeTimestampList[msg.sender], "NFKey: upgrade not available yet");

        uint level = getLevel(tokenID);
        uint zone = getZone(tokenID);
        uint smarterAmount = getAmountUpgradeKey(level);
        smarterCoinContract.transferFrom(address(msg.sender), address(this), smarterAmount);

        string memory tokenUri = getIPFS(level + 1, zone);

        _burn(tokenID);
        _mint(msg.sender, tokenID);
        _setTokenURI(tokenID, tokenUri);

        setLevel(tokenID, level + 1);
        setUpgradeDelay(msg.sender, level + 1);
        nfkeyStakingContract.proxyAddLog(tokenID);
    }

    function bulkMint(address account, uint zone, uint amount) public payable {
        require(_tokenIds.current() + amount <= getCap(), "NFKey: Max amount");
        require(amount <= 50, "NFKey: 50 tokens per transaction");

        uint sumCommission = getZoneCommission(msg.sender, zone) * amount;
        require(msg.value >= sumCommission, "NFKey: Invalid sum commission");
        if (sumCommission > 0) payable(_wallet).transfer(sumCommission);

        for (uint i = 1; i <= amount; i++) {
            mint(account, zone);
        }
    }

    function mint(address account, uint zone) internal {
        uint level = WhitelistUpgradeableV1(_whitelistContractAddress).getAddressToWhitelist(account);
        if (level == 0 && zone == 5) level = 1;
        require(level >= 1, "NFKey: You need to be whitelisted");

        bool isZone = WhitelistUpgradeableV1(_whitelistContractAddress).getWhitelistZone(account, zone);
        require(isZone || zone == 5, "NFKey: Invalid zone");

        _tokenIds.increment();
        uint tokenID = _tokenIds.current();
        string memory tokenUri = getIPFS(level, zone);

        _mint(account, tokenID);
        _setTokenURI(tokenID, tokenUri);

        setLevel(tokenID, level);
        setZone(tokenID, zone);
        setUpgradeDelay(msg.sender, level);

        if (zone == 1 || zone == 2) WhitelistUpgradeableV1(_whitelistContractAddress).removeWhitelistZone(msg.sender, zone);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SmarterCoinUpgradeableV1 is ERC20Upgradeable, OwnableUpgradeable {
    function initialize() initializer public {
        __ERC20_init("testSmarter", "tSMRTR");
        _mint(address(this), 100000);
    }

    function faucet(address _to) public {
        _mint(address(_to), 100000 * 10 ** 18);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract WhitelistUpgradeableV1 is Initializable, OwnableUpgradeable {
    struct WhitelistUser {
        address whitelistAddress;
        uint level;
        bool zone1;
        bool zone2;
        bool zone3;
        bool zone4;
    }

    mapping(address => bool) private adminAddressList;
    mapping(address => uint) private levelList;
    mapping(address => mapping(uint => bool)) private zoneList;

    function initialize() public initializer {
        adminAddressList[0xCeaf7780c54bc6815A8d5c3E10fdc965d0F26762] = true;
        adminAddressList[0x9CB52e780db0Ce66B2c4d8193C3986B5E7114336] = true;
        adminAddressList[0xbDe951E26aae4F39e20628724f58293A4E6457D4] = true;
        adminAddressList[0xD797d3510e5074891546797f2Ab9105bd0e41bC3] = true;
        adminAddressList[0x44D0b410623a3CF03ae06F782C111F23fADedAdA] = true;
        adminAddressList[0x53c52a7B7Fc72ED24882Aa195A5659DC608cc552] = true;
        adminAddressList[0x77CF5565be42dD8d33e02EAd4B2d164C6368Bfcd] = true;
        adminAddressList[0x7FAA068AEF77bAfE9462910548c6A2C4c10d247f] = true;
        adminAddressList[0x3F682Bdb2f6315C55b6546FD3d2dea14425112Da] = true;
        adminAddressList[0x06025812fDe95F375E3ddAf503e8e25E2724D4e2] = true;
        adminAddressList[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(adminAddressList[msg.sender], "Whitelist: caller is not admin");
        _;
    }

    function addAdmin(address account) public onlyAdmin {
        adminAddressList[account] = true;
    }

    function addAddressesToWhitelist(WhitelistUser[] memory newUserList) public onlyAdmin {
        for (uint i = 0; i < newUserList.length; i++) {
            addAddressToWhitelist(newUserList[i]);
        }
    }

    function removeAddressesToWhitelist(address[] memory accountList) public onlyAdmin {
        for (uint i = 0; i < accountList.length; i++) {
            removeAddressFromWhitelist(accountList[i]);
        }
    }

    function addAddressToWhitelist(WhitelistUser memory newUser) public onlyAdmin {
        levelList[newUser.whitelistAddress] = newUser.level;

        if (newUser.zone1) zoneList[newUser.whitelistAddress][1] = true;
        if (newUser.zone2) zoneList[newUser.whitelistAddress][2] = true;
        if (newUser.zone3) zoneList[newUser.whitelistAddress][3] = true;
        if (newUser.zone4) zoneList[newUser.whitelistAddress][4] = true;
    }

    function getAddressToWhitelist(address account) public view returns (uint) {
        return levelList[account];
    }

    function removeAddressFromWhitelist(address account) public onlyAdmin {
        levelList[account] = 0;
        zoneList[account][1] = false;
        zoneList[account][2] = false;
        zoneList[account][3] = false;
        zoneList[account][4] = false;
    }

    function getWhitelistZone(address account, uint zone) public view returns (bool) {
        return zoneList[account][zone];
    }

    function addWhitelistZone(address account, uint zone) public onlyAdmin {
        zoneList[account][zone] = true;
    }

    function removeWhitelistZone(address account, uint zone) public onlyAdmin {
        zoneList[account][zone] = false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";

        //tokenURI(1)
        //--> 'ipfs://<hash>/1' --> {name: "", desc: "", attr: []}
        //--> '{baseURI}/{tokenID}'
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}