/**
 *Submitted for verification at snowtrace.io on 2021-12-06
*/

// File: contracts/interfaces/IServiceIncentive.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's si interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IServiceIncentive  {
	function setCircuitBreakWithOwner(bool emergency) external returns (bool);
	function setCircuitBreaker(bool emergency) external returns (bool);

	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) external returns (bool);
	function updateRewardLane(address payable userAddr) external returns (bool);

	function getBetaRateBaseTotalAmount() external view returns (uint256);
	function getBetaRateBaseUserAmount(address payable userAddr) external view returns (uint256);

	function getMarketRewardInfo() external view returns (uint256, uint256, uint256);

	function getUserRewardInfo(address payable userAddr) external view returns (uint256, uint256, uint256);

	function claimRewardAmountUser(address payable userAddr) external returns (uint256);
}

// File: contracts/interfaces/IMarketHandlerDataStorage.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market handler data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketHandlerDataStorage  {
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function setNewCustomer(address payable userAddr) external returns (bool);

	function getUserAccessed(address payable userAddr) external view returns (bool);
	function setUserAccessed(address payable userAddr, bool _accessed) external returns (bool);

	function getReservedAddr() external view returns (address payable);
	function setReservedAddr(address payable reservedAddress) external returns (bool);

	function getReservedAmount() external view returns (int256);
	function addReservedAmount(uint256 amount) external returns (int256);
	function subReservedAmount(uint256 amount) external returns (int256);
	function updateSignedReservedAmount(int256 amount) external returns (int256);

	function setTokenHandler(address _marketHandlerAddr, address _interestModelAddr) external returns (bool);
	function setCoinHandler(address _marketHandlerAddr, address _interestModelAddr) external returns (bool);

	function getDepositTotalAmount() external view returns (uint256);
	function addDepositTotalAmount(uint256 amount) external returns (uint256);
	function subDepositTotalAmount(uint256 amount) external returns (uint256);

	function getBorrowTotalAmount() external view returns (uint256);
	function addBorrowTotalAmount(uint256 amount) external returns (uint256);
	function subBorrowTotalAmount(uint256 amount) external returns (uint256);

	function getUserIntraDepositAmount(address payable userAddr) external view returns (uint256);
	function addUserIntraDepositAmount(address payable userAddr, uint256 amount) external returns (uint256);
	function subUserIntraDepositAmount(address payable userAddr, uint256 amount) external returns (uint256);

	function getUserIntraBorrowAmount(address payable userAddr) external view returns (uint256);
	function addUserIntraBorrowAmount(address payable userAddr, uint256 amount) external returns (uint256);
	function subUserIntraBorrowAmount(address payable userAddr, uint256 amount) external returns (uint256);

	function addDepositAmount(address payable userAddr, uint256 amount) external returns (bool);
	function subDepositAmount(address payable userAddr, uint256 amount) external returns (bool);

	function addBorrowAmount(address payable userAddr, uint256 amount) external returns (bool);
	function subBorrowAmount(address payable userAddr, uint256 amount) external returns (bool);

	function getUserAmount(address payable userAddr) external view returns (uint256, uint256);
	function getHandlerAmount() external view returns (uint256, uint256);

	function getAmount(address payable userAddr) external view returns (uint256, uint256, uint256, uint256);
	function setAmount(address payable userAddr, uint256 depositTotalAmount, uint256 borrowTotalAmount, uint256 depositAmount, uint256 borrowAmount) external returns (uint256);

	function setBlocks(uint256 lastUpdatedBlock, uint256 inactiveActionDelta) external returns (bool);

	function getLastUpdatedBlock() external view returns (uint256);
	function setLastUpdatedBlock(uint256 _lastUpdatedBlock) external returns (bool);

	function getInactiveActionDelta() external view returns (uint256);
	function setInactiveActionDelta(uint256 inactiveActionDelta) external returns (bool);

	function syncActionEXR() external returns (bool);

	function getActionEXR() external view returns (uint256, uint256);
	function setActionEXR(uint256 actionDepositExRate, uint256 actionBorrowExRate) external returns (bool);

	function getGlobalDepositEXR() external view returns (uint256);
	function getGlobalBorrowEXR() external view returns (uint256);

	function setEXR(address payable userAddr, uint256 globalDepositEXR, uint256 globalBorrowEXR) external returns (bool);

	function getUserEXR(address payable userAddr) external view returns (uint256, uint256);
	function setUserEXR(address payable userAddr, uint256 depositEXR, uint256 borrowEXR) external returns (bool);

	function getGlobalEXR() external view returns (uint256, uint256);

	function getMarketHandlerAddr() external view returns (address);
	function setMarketHandlerAddr(address marketHandlerAddr) external returns (bool);

	function getInterestModelAddr() external view returns (address);
	function setInterestModelAddr(address interestModelAddr) external returns (bool);


	function getMinimumInterestRate() external view returns (uint256);
	function setMinimumInterestRate(uint256 _minimumInterestRate) external returns (bool);

	function getLiquiditySensitivity() external view returns (uint256);
	function setLiquiditySensitivity(uint256 _liquiditySensitivity) external returns (bool);

	function getLimit() external view returns (uint256, uint256);

	function getBorrowLimit() external view returns (uint256);
	function setBorrowLimit(uint256 _borrowLimit) external returns (bool);

	function getMarginCallLimit() external view returns (uint256);
	function setMarginCallLimit(uint256 _marginCallLimit) external returns (bool);

	function getLimitOfAction() external view returns (uint256);
	function setLimitOfAction(uint256 limitOfAction) external returns (bool);

	function getLiquidityLimit() external view returns (uint256);
	function setLiquidityLimit(uint256 liquidityLimit) external returns (bool);
}

// File: contracts/interfaces/IMarketManager.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market manager interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketManager  {
	function setBreakerTable(address _target, bool _status) external returns (bool);

	function getCircuitBreaker() external view returns (bool);
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function getTokenHandlerInfo(uint256 handlerID) external view returns (bool, address, string memory);

	function handlerRegister(uint256 handlerID, address tokenHandlerAddr, uint256 flashFeeRate) external returns (bool);

	function applyInterestHandlers(address payable userAddr, uint256 callerID, bool allFlag) external returns (uint256, uint256, uint256, uint256, uint256, uint256);

	function getTokenHandlerPrice(uint256 handlerID) external view returns (uint256);
	function getTokenHandlerBorrowLimit(uint256 handlerID) external view returns (uint256);
	function getTokenHandlerSupport(uint256 handlerID) external view returns (bool);

	function getTokenHandlersLength() external view returns (uint256);
	function setTokenHandlersLength(uint256 _tokenHandlerLength) external returns (bool);

	function getTokenHandlerID(uint256 index) external view returns (uint256);
	function getTokenHandlerMarginCallLimit(uint256 handlerID) external view returns (uint256);

	function getUserIntraHandlerAssetWithInterest(address payable userAddr, uint256 handlerID) external view returns (uint256, uint256);

	function getUserTotalIntraCreditAsset(address payable userAddr) external view returns (uint256, uint256);

	function getUserLimitIntraAsset(address payable userAddr) external view returns (uint256, uint256);

	function getUserCollateralizableAmount(address payable userAddr, uint256 handlerID) external view returns (uint256);

	function getUserExtraLiquidityAmount(address payable userAddr, uint256 handlerID) external view returns (uint256);
	function partialLiquidationUser(address payable delinquentBorrower, uint256 liquidateAmount, address payable liquidator, uint256 liquidateHandlerID, uint256 rewardHandlerID) external returns (uint256, uint256, uint256);

	function getMaxLiquidationReward(address payable delinquentBorrower, uint256 liquidateHandlerID, uint256 liquidateAmount, uint256 rewardHandlerID, uint256 rewardRatio) external view returns (uint256);
	function partialLiquidationUserReward(address payable delinquentBorrower, uint256 rewardAmount, address payable liquidator, uint256 handlerID) external returns (uint256);

	function setLiquidationManager(address liquidationManagerAddr) external returns (bool);

	function rewardClaimAll(address payable userAddr) external returns (uint256);

	function updateRewardParams(address payable userAddr) external returns (bool);
	function interestUpdateReward() external returns (bool);
	function getGlobalRewardInfo() external view returns (uint256, uint256, uint256);

	function setOracleProxy(address oracleProxyAddr) external returns (bool);

	function rewardUpdateOfInAction(address payable userAddr, uint256 callerID) external returns (bool);
	function ownerRewardTransfer(uint256 _amount) external returns (bool);
 	function getFeeTotal(uint256 handlerID) external returns (uint256);
  function getFeeFromArguments(uint256 handlerID, uint256 amount, uint256 bifiAmount) external returns (uint256);
}

// File: contracts/interfaces/IInterestModel.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's interest model interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IInterestModel {
	function getInterestAmount(address handlerDataStorageAddr, address payable userAddr, bool isView) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function viewInterestAmount(address handlerDataStorageAddr, address payable userAddr) external view returns (bool, uint256, uint256, bool, uint256, uint256);
	function getSIRandBIR(uint256 depositTotalAmount, uint256 borrowTotalAmount) external view returns (uint256, uint256);
}

// File: contracts/interfaces/IERC20.sol
// from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
pragma solidity 0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external ;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external ;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IMarketSIHandlerDataStorage.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's market si handler data storage interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IMarketSIHandlerDataStorage  {
	function setCircuitBreaker(bool _emergency) external returns (bool);

	function updateRewardPerBlockStorage(uint256 _rewardPerBlock) external returns (bool);

	function getRewardInfo(address userAddr) external view returns (uint256, uint256, uint256, uint256, uint256, uint256);

	function getMarketRewardInfo() external view returns (uint256, uint256, uint256);
	function setMarketRewardInfo(uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardPerBlock) external returns (bool);

	function getUserRewardInfo(address userAddr) external view returns (uint256, uint256, uint256);
	function setUserRewardInfo(address userAddr, uint256 _rewardLane, uint256 _rewardLaneUpdateAt, uint256 _rewardAmount) external returns (bool);

	function getBetaRate() external view returns (uint256);
	function setBetaRate(uint256 _betaRate) external returns (bool);
}

// File: contracts/Errors.sol
pragma solidity 0.6.12;

contract Modifier {
    string internal constant ONLY_OWNER = "O";
    string internal constant ONLY_MANAGER = "M";
    string internal constant CIRCUIT_BREAKER = "emergency";
}

contract ManagerModifier is Modifier {
    string internal constant ONLY_HANDLER = "H";
    string internal constant ONLY_LIQUIDATION_MANAGER = "LM";
    string internal constant ONLY_BREAKER = "B";
}

contract HandlerDataStorageModifier is Modifier {
    string internal constant ONLY_BIFI_CONTRACT = "BF";
}

contract SIDataStorageModifier is Modifier {
    string internal constant ONLY_SI_HANDLER = "SI";
}

contract HandlerErrors is Modifier {
    string internal constant USE_VAULE = "use value";
    string internal constant USE_ARG = "use arg";
    string internal constant EXCEED_LIMIT = "exceed limit";
    string internal constant NO_LIQUIDATION = "no liquidation";
    string internal constant NO_LIQUIDATION_REWARD = "no enough reward";
    string internal constant NO_EFFECTIVE_BALANCE = "not enough balance";
    string internal constant TRANSFER = "err transfer";
}

contract SIErrors is Modifier { }

contract InterestErrors is Modifier { }

contract LiquidationManagerErrors is Modifier {
    string internal constant NO_DELINQUENT = "not delinquent";
}

contract ManagerErrors is ManagerModifier {
    string internal constant REWARD_TRANSFER = "RT";
    string internal constant UNSUPPORTED_TOKEN = "UT";
}

contract OracleProxyErrors is Modifier {
    string internal constant ZERO_PRICE = "price zero";
}

contract RequestProxyErrors is Modifier { }

contract ManagerDataStorageErrors is ManagerModifier {
    string internal constant NULL_ADDRESS = "err addr null";
}

// File: contracts/context/BlockContext.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's BlockContext contract
 * @notice BiFi getter Contract for Block Context Information
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract BlockContext {
    function _blockContext() internal view returns(uint256 context) {
        // block number chain
        // context = block.number;

        // block timestamp chain
        context = block.timestamp;
    }
}

// File: contracts/marketHandler/TokenSI.sol
pragma solidity 0.6.12;

/**
 * @title Bifi TokenSI Contract
 * @notice Service incentive logic
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract TokenSI is IServiceIncentive, SIErrors, BlockContext {
	event CircuitBreaked(bool breaked, uint256 blockNumber, uint256 handlerID);

	address payable owner;

	uint256 handlerID;

	string tokenName;

	uint256 constant unifiedPoint = 10 ** 18;

	uint256 unifiedTokenDecimal;

	uint256 underlyingTokenDecimal;

	IMarketManager marketManager;

	IInterestModel interestModelInstance;

	IMarketHandlerDataStorage handlerDataStorage;

	IMarketSIHandlerDataStorage SIHandlerDataStorage;

	IERC20 erc20Instance;

	struct MarketRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardPerBlock;
	}

	struct UserRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardAmount;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == address(owner), ONLY_OWNER);
		_;
	}

	/**
	* @dev Transfer ownership
	* @param _owner the address of the new owner
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers by owne
	* @param _emergency The status of the circuit breaker
	* @return true (TODO: validate results)
	*/
	function setCircuitBreakWithOwner(bool _emergency) onlyOwner external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Set circuitBreak to freeze/unfreeze all handlers by marketManager
	* @param _emergency The status of the circuit breaker
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyMarketManager external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Update the amount of rewards per block
	* @param _rewardPerBlock The amount of the reward amount per block
	* @return true (TODO: validate results)
	*/
	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) onlyMarketManager external override returns (bool)
	{
		return SIHandlerDataStorage.updateRewardPerBlockStorage(_rewardPerBlock);
	}

	/**
	* @dev Update the reward lane (the acculumated sum of the reward unit per block) of the market and user
	* @param userAddr The address of user
	* @return Whether or not this process has succeeded
	*/
	function updateRewardLane(address payable userAddr) external override returns (bool)
	{
		return _updateRewardLane(userAddr);
	}
	function _updateRewardLane(address payable userAddr) internal returns (bool)
  	{
		MarketRewardInfo memory market;
		UserRewardInfo memory user;
		IMarketSIHandlerDataStorage _SIHandlerDataStorage = SIHandlerDataStorage;
		(market.rewardLane, market.rewardLaneUpdateAt, market.rewardPerBlock, user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = _SIHandlerDataStorage.getRewardInfo(userAddr);

		uint256 currentBlockNum = _blockContext();
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositTotalAmount, borrowTotalAmount, depositUserAmount, borrowUserAmount) = handlerDataStorage.getAmount(userAddr);

		/* Unless the reward lane of the market is updated at the current block */
		if (market.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 _delta = sub(currentBlockNum, market.rewardLaneUpdateAt);
			uint256 betaRateBaseTotalAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
			if (betaRateBaseTotalAmount != 0)
			{
				/* update the reward lane */
				market.rewardLane = add(market.rewardLane, _calcRewardLaneDistance(_delta, market.rewardPerBlock, betaRateBaseTotalAmount));
			}

			_SIHandlerDataStorage.setMarketRewardInfo(market.rewardLane, currentBlockNum, market.rewardPerBlock);
		}

		/* Unless the reward lane of the user  is updated at the current block */
		if (user.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 betaRateBaseUserAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
			if (betaRateBaseUserAmount != 0)
			{
				user.rewardAmount = add(user.rewardAmount, unifiedMul(betaRateBaseUserAmount, sub(market.rewardLane, user.rewardLane)));
			}

			_SIHandlerDataStorage.setUserRewardInfo(userAddr, market.rewardLane, currentBlockNum, user.rewardAmount);
			return true;
		}

		return false;
	}

	/**
	* @dev Calculates the reward lane distance (for delta blocks) based on the given parameters.
	* @param _delta The blockNumber difference
	* @param _rewardPerBlock The amount of reward per block
	* @param _total The total amount of betaRate
	* @return The reward lane distance
	*/
	function _calcRewardLaneDistance(uint256 _delta, uint256 _rewardPerBlock, uint256 _total) internal pure returns (uint256)
	{
		return mul(_delta, unifiedDiv(_rewardPerBlock, _total));
	}

	/**
	* @dev Get the total amount of betaRate
	* @return The total amount of betaRate
	*/
	function getBetaRateBaseTotalAmount() external view override returns (uint256)
	{
		return _getBetaRateBaseTotalAmount();
	}

	/**
	* @dev Get the total amount of betaRate
	* @return The total amount of betaRate
	*/
	function _getBetaRateBaseTotalAmount() internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = handlerDataStorage.getHandlerAmount();
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev Calculate the rewards given to the user by using the beta score (external).
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The beta score of the user
	*/
	function getBetaRateBaseUserAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getBetaRateBaseUserAmount(userAddr);
	}

	/**
	* @dev Calculate the rewards given to the user by using the beta score (internal)
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The beta score of the user
	*/
	function _getBetaRateBaseUserAmount(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositUserAmount, borrowUserAmount) = handlerDataStorage.getUserAmount(userAddr);
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
	}

	function _calcBetaBaseAmount(uint256 _beta, uint256 _depositAmount, uint256 _borrowAmount) internal pure returns (uint256)
	{
		return add(unifiedMul(_depositAmount, _beta), unifiedMul(_borrowAmount, sub(unifiedPoint, _beta)));
	}

	/**
	* @dev Claim rewards for the user (external)
	* @param userAddr The address of user
	* @return The amount of user reward
	*/
	function claimRewardAmountUser(address payable userAddr) onlyMarketManager external override returns (uint256)
	{
		return _claimRewardAmountUser(userAddr);
	}

	/**
	* @dev Claim rewards for the user (internal)
	* @param userAddr The address of user
	* @return The amount of user reward
	*/
	function _claimRewardAmountUser(address payable userAddr) internal returns (uint256)
	{
		UserRewardInfo memory user;
		uint256 currentBlockNum = _blockContext();
		(user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = SIHandlerDataStorage.getUserRewardInfo(userAddr);

		/* reset the user reward */
		SIHandlerDataStorage.setUserRewardInfo(userAddr, user.rewardLane, currentBlockNum, 0);
		return user.rewardAmount;
	}

	/**
	* @dev Get the reward parameters of the market
	* @return (rewardLane, rewardLaneUpdateAt, rewardPerBlock)
	*/
	function getMarketRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getMarketRewardInfo();
	}

	/**
	* @dev Get reward parameters for the user
	* @return (uint256,uint256,uint256) (rewardLane, rewardLaneUpdateAt, rewardAmount)
	*/
	function getUserRewardInfo(address payable userAddr) external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getUserRewardInfo(userAddr);
	}

	/**
	* @dev Get the rate of beta (beta-score)
	* @return The rate of beta (beta-score)
	*/
	function getBetaRate() external view returns (uint256)
	{
		return SIHandlerDataStorage.getBetaRate();
	}

	/* ******************* Safe Math ******************* */
  // from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
  // Subject to the MIT license.

	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "add overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "sub overflow");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "div by zero");
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mod(a, b, "mod by zero");
	}

	function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a * b;
		require((c / a) == b, "mul overflow");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b != 0, errorMessage);
		return a % b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "unified div by zero");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
	}

	function signedAdd(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a + b;
		require(((b >= 0) && (c >= a)) || ((b < 0) && (c < a)), "SignedSafeMath: addition overflow");
		return c;
	}

	function signedSub(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a - b;
		require(((b >= 0) && (c <= a)) || ((b < 0) && (c > a)), "SignedSafeMath: subtraction overflow");
		return c;
	}
}

// File: contracts/marketHandler/CoinSI.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's CoinSI Contract
 * @notice Contract of CoinSI, where users can action with reward logic
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract CoinSI is IServiceIncentive, SIErrors, BlockContext {
	event CircuitBreaked(bool breaked, uint256 blockNumber, uint256 handlerID);

	address payable owner;

	uint256 handlerID;

	string tokenName;

	uint256 constant unifiedPoint = 10 ** 18;

	IMarketManager marketManager;

	IInterestModel interestModelInstance;

	IMarketHandlerDataStorage handlerDataStorage;

	IMarketSIHandlerDataStorage SIHandlerDataStorage;

	struct MarketRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardPerBlock;
	}

	struct UserRewardInfo {
		uint256 rewardLane;
		uint256 rewardLaneUpdateAt;
		uint256 rewardAmount;
	}

	modifier onlyMarketManager {
		address msgSender = msg.sender;
		require((msgSender == address(marketManager)) || (msgSender == owner), ONLY_MANAGER);
		_;
	}

	modifier onlyOwner {
		require(msg.sender == address(owner), ONLY_OWNER);
		_;
	}

	/**
	* @dev Replace the owner of the handler
	* @param _owner the address of the owner to be replaced
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address _owner) onlyOwner external returns (bool)
	{
		owner = address(uint160(_owner));
		return true;
	}

	/**
	* @dev Set circuitBreak which freeze all of handlers with owner
	* @param _emergency The status on whether to use circuitBreak
	* @return true (TODO: validate results)
	*/
	function setCircuitBreakWithOwner(bool _emergency) onlyOwner external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Set circuitBreak which freeze all of handlers with marketManager
	* @param _emergency The status on whether to use circuitBreak
	* @return true (TODO: validate results)
	*/
	function setCircuitBreaker(bool _emergency) onlyMarketManager external override returns (bool)
	{
		SIHandlerDataStorage.setCircuitBreaker(_emergency);
		emit CircuitBreaked(_emergency, block.number, handlerID);
		return true;
	}

	/**
	* @dev Update the amount of rewards per block
	* @param _rewardPerBlock The amount of rewards per block
	* @return true (TODO: validate results)
	*/
	function updateRewardPerBlockLogic(uint256 _rewardPerBlock) onlyMarketManager external override returns (bool)
	{
		return SIHandlerDataStorage.updateRewardPerBlockStorage(_rewardPerBlock);
	}

	/**
	* @dev Calculates the number of rewards given according to the gap of block number
	* @param userAddr The address of user
	* @return Whether or not updateRewardLane succeed
	*/
	function updateRewardLane(address payable userAddr) external override returns (bool)
	{
		return _updateRewardLane(userAddr);
	}
	function _updateRewardLane(address payable userAddr) internal returns (bool)
  	{
		MarketRewardInfo memory market;
		UserRewardInfo memory user;
		IMarketSIHandlerDataStorage _SIHandlerDataStorage = SIHandlerDataStorage;
		(market.rewardLane, market.rewardLaneUpdateAt, market.rewardPerBlock, user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = _SIHandlerDataStorage.getRewardInfo(userAddr);

		/* To calculate the amount of rewards that change as the block flows, bring in the user's deposit, borrow, and total deposit, total borrow of the market */
		uint256 currentBlockNum = _blockContext();
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositTotalAmount, borrowTotalAmount, depositUserAmount, borrowUserAmount) = handlerDataStorage.getAmount(userAddr);

		/* Update the market's reward parameter value according to the rate of beta(the rate of weight) if the time of call is later than when the reward was updated */
		if (market.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 _delta = sub(currentBlockNum, market.rewardLaneUpdateAt);
			uint256 betaRateBaseTotalAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
			if (betaRateBaseTotalAmount != 0)
			{
				market.rewardLane = add(market.rewardLane, _calcRewardLaneDistance(_delta, market.rewardPerBlock, betaRateBaseTotalAmount));
			}

			_SIHandlerDataStorage.setMarketRewardInfo(market.rewardLane, currentBlockNum, market.rewardPerBlock);
		}

		/* Update the user's reward parameter value according to the rate of beta(the rate of weight) if the time of call is later than when the reward was updated */
		if (user.rewardLaneUpdateAt < currentBlockNum)
		{
			uint256 betaRateBaseUserAmount = _calcBetaBaseAmount(_SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
			if (betaRateBaseUserAmount != 0)
			{
				user.rewardAmount = add(user.rewardAmount, unifiedMul(betaRateBaseUserAmount, sub(market.rewardLane, user.rewardLane)));
			}

			_SIHandlerDataStorage.setUserRewardInfo(userAddr, market.rewardLane, currentBlockNum, user.rewardAmount);
			return true;
		}

		return false;
	}

	/**
	* @dev Calculates the number of rewards given according to the gap of block number
	* @param _delta The amount of blockNumber's gap
	* @param _rewardPerBlock The amount of reward per block
	* @param _total The total amount of betaRate
	* @return The result of reward given according to the block number gap
	*/
	function _calcRewardLaneDistance(uint256 _delta, uint256 _rewardPerBlock, uint256 _total) internal pure returns (uint256)
	{
		return mul(_delta, unifiedDiv(_rewardPerBlock, _total));
	}

	/**
	* @dev Get the total amount of betaRate
	* @return The total amount of betaRate
	*/
	function getBetaRateBaseTotalAmount() external view override returns (uint256)
	{
		return _getBetaRateBaseTotalAmount();
	}

	/**
	* @dev Get the total amount of betaRate
	* @return The total amount of betaRate
	*/
	function _getBetaRateBaseTotalAmount() internal view returns (uint256)
	{
		uint256 depositTotalAmount;
		uint256 borrowTotalAmount;
		(depositTotalAmount, borrowTotalAmount) = handlerDataStorage.getHandlerAmount();
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositTotalAmount, borrowTotalAmount);
	}

	/**
	* @dev Calculate the rewards given to the user through calculation, Based on the data rate
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The amount of user's betaRate
	*/
	function getBetaRateBaseUserAmount(address payable userAddr) external view override returns (uint256)
	{
		return _getBetaRateBaseUserAmount(userAddr);
	}

	/**
	* @dev Calculate the rewards given to the user through calculation, Based on the data rate
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param userAddr The address of user
	* @return The amount of user's betaRate
	*/
	function _getBetaRateBaseUserAmount(address payable userAddr) internal view returns (uint256)
	{
		uint256 depositUserAmount;
		uint256 borrowUserAmount;
		(depositUserAmount, borrowUserAmount) = handlerDataStorage.getUserAmount(userAddr);
		return _calcBetaBaseAmount(SIHandlerDataStorage.getBetaRate(), depositUserAmount, borrowUserAmount);
	}

	/**
	* @dev Get the amount of user's accumulated rewards as tokens
	* and initialize user reward amount
	* @param userAddr The address of user who claimed
	* @return The amount of user's reward
	*/
	function claimRewardAmountUser(address payable userAddr) onlyMarketManager external override returns (uint256)
	{
		return _claimRewardAmountUser(userAddr);
	}

	/**
	* @dev Get the amount of user's accumulated rewards as tokens
	* and initialize user reward amount
	* @param userAddr The address of user who claimed
	* @return The amount of user's reward
	*/
	function _claimRewardAmountUser(address payable userAddr) internal returns (uint256)
	{
		UserRewardInfo memory user;
		uint256 currentBlockNum = _blockContext();
		(user.rewardLane, user.rewardLaneUpdateAt, user.rewardAmount) = SIHandlerDataStorage.getUserRewardInfo(userAddr);
		SIHandlerDataStorage.setUserRewardInfo(userAddr, user.rewardLane, currentBlockNum, 0);
		return user.rewardAmount;
	}

	/**
	* @dev Calculate the rewards given to the user through calculation, Based on the data rate
	* betaRateBaseAmount = (depositAmount * betaRate) + ((1 - betaRate) * borrowAmount)
	* @param _beta The rate of beta
	* @param _depositAmount The amount of user's deposit
	* @param _borrowAmount The amount of user's borrow
	* @return The amount of user's betaRate
	*/
	function _calcBetaBaseAmount(uint256 _beta, uint256 _depositAmount, uint256 _borrowAmount) internal pure returns (uint256)
	{
		return add(unifiedMul(_depositAmount, _beta), unifiedMul(_borrowAmount, sub(unifiedPoint, _beta)));
	}

	/**
	* @dev Get reward parameters related the market
	* @return (uint256,uint256,uint256) (rewardLane, rewardLaneUpdateAt, rewardPerBlock)
	*/
	function getMarketRewardInfo() external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getMarketRewardInfo();
	}

	/**
	* @dev Get reward parameters related the user
	* @return (uint256,uint256,uint256) (rewardLane, rewardLaneUpdateAt, rewardAmount)
	*/
	function getUserRewardInfo(address payable userAddr) external view override returns (uint256, uint256, uint256)
	{
		return SIHandlerDataStorage.getUserRewardInfo(userAddr);
	}

	/**
	* @dev Get the rate of beta
	* @return The rate of beta
	*/
	function getBetaRate() external view returns (uint256)
	{
		return SIHandlerDataStorage.getBetaRate();
	}

	/* ******************* Safe Math ******************* */
  // from: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
  // Subject to the MIT license.
	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		require(c >= a, "add overflow");
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _sub(a, b, "sub overflow");
	}

	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "div by zero");
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mod(a, b, "mod by zero");
	}

	function _sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b <= a, errorMessage);
		return a - b;
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a * b;
		require((c / a) == b, "mul overflow");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function _mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b != 0, errorMessage);
		return a % b;
	}

	function unifiedDiv(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, unifiedPoint), b, "unified div by zero");
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
	}

	function signedAdd(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a + b;
		require(((b >= 0) && (c >= a)) || ((b < 0) && (c < a)), "SignedSafeMath: addition overflow");
		return c;
	}

	function signedSub(int256 a, int256 b) internal pure returns (int256)
	{
		int256 c = a - b;
		require(((b >= 0) && (c <= a)) || ((b < 0) && (c > a)), "SignedSafeMath: subtraction overflow");
		return c;
	}
}