/**
 *Submitted for verification at snowtrace.io on 2023-05-08
*/

/**
 *Submitted for verification at snowtrace.io on 2022-05-26
*/
// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// File: gladiator-finance-contracts/contracts/IWhitelist.sol



pragma solidity ^0.8.9;

interface IWhitelist {
    // total size of the whitelist
    function wlSize() external view returns (uint256);
    // max number of wl spot sales
    function maxSpots() external view returns (uint256);
    // price of the WL spot
    function spotPrice() external view returns (uint256);
    // number of wl spots sold
    function spotCount() external view returns (uint256);
    // glad/wl sale has started
    function started() external view returns (bool);
    // wl sale has ended
    function wlEnded() external view returns (bool);
    // glad sale has ended
    function gladEnded() external view returns (bool);
    // total glad sold (wl included)
    function totalPGlad() external view returns (uint256);
    // total whitelisted glad sold
    function totalPGladWl() external view returns (uint256);

    // minimum glad amount buyable
    function minGladBuy() external view returns (uint256);
    // max glad that a whitelisted can buy @ discounted price
    function maxWlAmount() external view returns (uint256);

    // pglad sale price (for 100 units, so 30 means 0.3 avax / pglad)
    function pGladPrice() external view returns (uint256);
    // pglad wl sale price (for 100 units, so 20 means 0.2 avax / pglad)
    function pGladWlPrice() external view returns (uint256);

    // get the amount of pglad purchased by user (wl buys included)
    function pGlad(address _a) external view returns (uint256);
    // get the amount of wl plgad purchased
    function pGladWl(address _a) external view returns (uint256);

    // buy whitelist spot, avax value must be sent with transaction
    function buyWhitelistSpot() external payable;

    // buy pglad, avax value must be sent with transaction
    function buyPGlad(uint256 _amount) external payable;

    // check if an address is whitelisted
    function isWhitelisted(address _a) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
}

// File: gladiator-finance-contracts/contracts/Controllable.sol



pragma solidity ^0.8.9;


contract Controllable is Ownable {
    mapping (address => bool) controllers;

    event ControllerAdded(address);
    event ControllerRemoved(address);

    modifier onlyController() {
        require(controllers[_msgSender()] || _msgSender() ==  owner(), "Only controllers can do that");
        _;
    }

    /*** ADMIN  ***/
    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        if (!controllers[controller]) {
            controllers[controller] = true;
            emit ControllerAdded(controller);
        }
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        if (controllers[controller]) {
            controllers[controller] = false;
            emit ControllerRemoved(controller);
        }
    }


}

interface IDEXRouter {
 
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: gladiator-finance-contracts/contracts/Whitelist.sol



pragma solidity ^0.8.9;




contract Whitelist is IWhitelist, Controllable {
    mapping (address => bool) public whitelisted;
    uint256 public wlSize;
    uint256 public maxSpots = 150;
    uint256 public spotCount;
    uint256 public spotPrice = 3 ether;
    bool public started;
    bool public wlEnded;
    bool public gladEnded;
    uint256 public totalPGlad;
    uint256 public totalPGladWl;
    bool public wlLocked;

    uint256 public minGladBuy = 1 ether;
    uint256 public maxWlAmount = 1000 ether;
    // per 100 wei
    uint256 public pGladPrice = 30;
    // per 100 wei
    uint256 public pGladWlPrice = 20;


    mapping (address => uint256) public pGlad;
    mapping (address => uint256) public pGladWl;


    event PGladBuyWl(address user, uint256 amount);
    event PGladBuy(address user, uint256 amount);
    event Whitelisted(address user);
    event RemovedFromWhitelist(address user);

    constructor () {
    }

    function buyWhitelistSpot() external payable {
        require(started, "Sale not started yet");
        require(!wlEnded, "Whitelist sale already ended");
        require(!whitelisted[_msgSender()], "Already whitelisted");
        require(spotCount < maxSpots, "Wl spots sold out");
        require(msg.value == spotPrice, "Please send exact price");
        whitelisted[_msgSender()] = true;
        spotCount++;
        wlSize++;
        Address.sendValue(payable(owner()), msg.value);
        emit Whitelisted(_msgSender());
    }

    function buyPGlad(uint256 _amount) external payable {
        require(started, "Sale not started yet");
        require(!gladEnded, "pGlad sale already ended");
        require(_amount >= 1 ether, "Buy at least 1");
        uint256 sumPrice;
        uint256 wlAmount;
        if (whitelisted[_msgSender()] && pGladWl[_msgSender()] < maxWlAmount) {
            wlAmount = maxWlAmount - pGladWl[_msgSender()];
            if (wlAmount > _amount) {
                wlAmount = _amount;
            }
            pGladWl[_msgSender()] += wlAmount;
            totalPGladWl += wlAmount;
            emit PGladBuyWl(_msgSender(), wlAmount);
            sumPrice = wlAmount * pGladWlPrice / 100;
        }
        sumPrice += (_amount - wlAmount) * pGladPrice / 100;
        pGlad[_msgSender()] += _amount;
        require(msg.value == sumPrice, "Send exact amount pls");
        emit PGladBuy(_msgSender(), _amount);
        totalPGlad += _amount;
        Address.sendValue(payable(owner()), msg.value);
    }

    /*** GETTERS ***/
    function isWhitelisted(address _a) external view returns (bool) {
        return whitelisted[_a];
    }

    /*** MANAGE ***/

    function batchAddToWhitelist(address[] calldata _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        for (uint256 i = 0; i < _a.length; i++) {
            _addToWhitelist(_a[i]);
        }
    }

    function addToWhitelist(address _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        _addToWhitelist(_a);
    }

    function _addToWhitelist(address _a) internal {
        if (!whitelisted[_a]) {
            whitelisted[_a] = true;
            wlSize++;
            emit Whitelisted(_a);
        }
    }

    function batchRemoveFromWhitelist(address[] calldata _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        for (uint256 i = 0; i < _a.length; i++) {
            _removeFromWhitelist(_a[i]);
        }
    }

    function removeFromWhitelist(address _a) external onlyController {
        require(!wlLocked, "Whitelist locked");
        _removeFromWhitelist(_a);
    }

    function _removeFromWhitelist(address _a) internal {
        if (whitelisted[_a]) {
            require(!started, "Wl purchase already started");
            whitelisted[_a] = false;
            wlSize--;
            emit RemovedFromWhitelist(_a);
        }
    }

    function lockWhitelist() external onlyOwner {
        require(!wlLocked, "Already locked");
        wlLocked = true;
    }

    function setMaxSpots(uint256 _x) external onlyOwner {
        require(_x >= spotCount, "There are already more spots sold");
        maxSpots = _x;
    }

    function setSpotPrice(uint256 _p) external onlyOwner {
        require(_p > 0, "make it > 0");
        spotPrice = _p;
    }

    function startSale() external onlyOwner {
        require(!started, "Sale already started");
        started = true;
    }

    function endWlSale() external onlyOwner {
        require(started, "Wl purchase did not start yet");
        wlEnded = true;
    }

    function endGladSale() external onlyOwner {
        require(started, "Glad purchase did not start yet");
        gladEnded = true;
    }

}

// File: gladiator-finance-contracts/contracts/ITournament.sol



pragma solidity ^0.8.9;

interface ITournament {
    function winner() external returns (address); // returns address of the last bidder
    function claimed() external returns (bool); // returns true if the winner has already claimed the prize

    function lastTs() external returns (uint256); // last buy time
    function CLAIM_PERIOD() external returns (uint256); // reward can be claimed for this many time until expiration(latTs)
    function PERIOD() external returns (uint256); // time to win

    function TICKET_SIZE() external returns (uint256); // 10000th of pot
    function POT_SHARE() external returns (uint256); // 10000th of ticketprice

    
    event TicketBought(uint256 timestamp, uint256 ticketPrice, address oldWinner, address newWinner, uint256 reward);
    event WinnerClaimed(uint256 timestamp, address winner, uint256 reward);



    function getPotSize() external view returns (uint256); // returns actual pot size

    function getTicketPrice() external view returns (uint256); // return current ticket price

    function buy() external payable; // buy a ticket (token should be approved, if native then exact amount must be sent)

    function claimWinner() external; // winner can claim pot

    function withdrawUnclaimed() external; // treasury can claim remaining after CLAIM_PERIOD
    
}

// File: gladiator-finance-contracts/contracts/TournamentNative.sol



pragma solidity ^0.8.9;

contract TournamentNative is Ownable, ITournament {
    address public winner;
    address public router = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public grave = 0x3700a92dd231F0CaC37D31dBcF4c0f5cCb1db6Ca;
    address public zombie = 0x431bDC9975D570da5eD69C4E97e27114BCd55a86;
    address public gravetournament = 0x119FFdDD541129f096884192452C89F29Eec23F8;
    address public zombietournament = 0x119FFdDD541129f096884192452C89F29Eec23F8;
    bool public claimed;

    uint256 public lastTs;
    uint256 public CLAIM_PERIOD = 60 days;
    uint256 public PERIOD = 21780 seconds;
    uint256 public DECAYPERIOD = 180 seconds;
    uint256 public INITIALPERIOD = 21600 seconds;
    uint256 public DECAYSTOP = 360 seconds;
    uint256 public ROUNDEND;
    uint256 public PEGSHARE;
    uint256 public TICKET_SIZE = 60; // 10000th of pot
    uint256 public POT_SHARE = 6000; // 10000th
    uint256 public TEAMSHARE = 4000;
    uint256 public ROLLOVER = 7000;
  

    uint256 public finalPotSize;

   


    function changePeriod(uint256 _period) external onlyOwner {
        PERIOD = _period;
    }

      function changeDecayPeriod(uint256 _decayperiod) external onlyOwner {
        DECAYPERIOD = _decayperiod;
    }

       function changeInitialPeriod(uint256 _initialperiod) external onlyOwner {
        INITIALPERIOD = _initialperiod;
    }

       function changeDecayStop(uint256 _decaystop) external onlyOwner {
        DECAYSTOP = _decaystop;
    }

       function changeTicketSize(uint256 _ticketsize) external onlyOwner {
        TICKET_SIZE = _ticketsize;
    }

        function changeGraveTournament(address _gravetournament) external onlyOwner {
        gravetournament = _gravetournament;
    }

       function changeZombieTournament(address _zombietournament) external onlyOwner {
        zombietournament = _zombietournament;
    }



    function getPotSize() public view returns (uint256) {
        return _getPotSize();
    }

    function _getPotSize() internal view returns (uint256) {
        return address(this).balance;
    }

  

    function getTicketPrice() public view returns (uint256) {
        return _getTicketPrice();
    }

    function _getTicketPrice() internal view returns (uint256) {
        return (_getPotSize() * TICKET_SIZE) / 10000;
    }



     function _getCorrectedTicketPrice(uint256 amount) internal view returns (uint256) {
        return ((_getPotSize() - amount)) * TICKET_SIZE / 10000;
    }
    
   

    function buy() external payable {
        if (winner != 0x0000000000000000000000000000000000000000) {
            require(claimed == true || block.timestamp < lastTs + PERIOD, "Winner hasn't claimed"); //Prevents buying ticket if winner hasn't claimed prize.
        }
        require(_getPotSize() > 0, "Pot not initialized yet");
        if (claimed == true) {
            claimed = false;
            PERIOD = INITIALPERIOD + DECAYPERIOD;
        }
        uint256 ticketPrice = _getCorrectedTicketPrice(msg.value);
        uint256 reward;
        lastTs = block.timestamp;
        emit TicketBought(block.timestamp, ticketPrice, winner, msg.sender, reward);
        require(msg.value == ticketPrice, "Please send exact ticket price");
        finalPotSize = _getPotSize();
        
        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(grave);
        IDEXRouter(router).swapExactAVAXForTokens{value: (ticketPrice / 3)}(
            0,
            path,
            address(gravetournament),
            block.timestamp
        
        );
        address[] memory path2 = new address[](2);
        path2[0] = WAVAX;
        path2[1] = address(zombie);
        IDEXRouter(router).swapExactAVAXForTokens{value: (ticketPrice / 3)}(
            0,
            path2,
            address(zombietournament),
            block.timestamp
        
        );
        winner = msg.sender;
         if (PERIOD > DECAYSTOP) 
            PERIOD = (PERIOD - DECAYPERIOD);
            ROUNDEND = lastTs + PERIOD;
    }

    function claimWinner() external {
        require(lastTs != 0, "Not started yet");
        require(block.timestamp >= lastTs + PERIOD, "Not finished yet");
        require(block.timestamp <= lastTs + CLAIM_PERIOD, "Claim period ended");
        require(!claimed, "Already claimed");
        claimed = true;
        emit WinnerClaimed(block.timestamp, msg.sender, finalPotSize);
        Address.sendValue(payable(winner), (finalPotSize * ROLLOVER) / 10000);
    }

    function withdrawUnclaimed() external {
        require(lastTs != 0, "Not started yet");
        require(block.timestamp >= lastTs + CLAIM_PERIOD, "Claim period not ended yet");
        Address.sendValue(payable(owner()), address(this).balance);
    }

    fallback() external payable {}

    receive() external payable {}
}