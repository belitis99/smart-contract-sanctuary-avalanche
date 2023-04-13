// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
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
library Counters {
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

pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Bridge is Ownable, ReentrancyGuard {

    using Counters for Counters.Counter;
    Counters.Counter private _bridgeIdCounter;

    enum BridgeStatus {
        Initiated,
        Completed,
        Failed
    }

    struct BridgeRequest {
        address user;
        address token;
        uint256 amount;
        string targetChain;
        BridgeStatus status;
        uint256 timestamp;
    }

    mapping(uint256 => BridgeRequest) public bridgeRequests;
    mapping(address => bool) public supportedTokens;
    mapping(string => bool) public supportedChains;

    event BridgeInitiated(
        uint256 indexed bridgeId, 
        address indexed user, 
        address indexed token, 
        uint256 amount, 
        string targetChain
    );
    event BridgeCompleted(
        uint256 indexed bridgeId, 
        address indexed user, 
        address indexed token, 
        uint256 amount, 
        string targetChain
    );
    event BridgeFailed(
        uint256 indexed bridgeId, 
        address indexed user, 
        address indexed token, 
        uint256 amount, 
        string targetChain
    );

    function addSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Bridge: token address cannot be 0");
        supportedTokens[_token] = true;
    }

    function removeSupportedToken(address _token) external onlyOwner {
        require(_token != address(0), "Bridge: token address cannot be 0");
        supportedTokens[_token] = false;
    }

    function isSupportedToken(address _token) public view returns (bool) {
        return supportedTokens[_token];
    }

    function addSupportedChain(string memory _chain) external onlyOwner {
        require(bytes(_chain).length > 0, "Bridge: chain name cannot be empty");
        supportedChains[_chain] = true;
    }

    function removeSupportedChain(string memory _chain) external onlyOwner {
        require(bytes(_chain).length > 0, "Bridge: chain name cannot be empty");
        supportedChains[_chain] = false;
    }

    function isSupportedChain(string memory _chain) public view returns (bool) {
        return supportedChains[_chain];
    }

    function initiateBridge(
        address _token, 
        uint256 _amount, 
        string memory _chain
    ) external nonReentrant {
        require(isSupportedToken(_token), "Bridge: token is not supported");
        require(isSupportedChain(_chain), "Bridge: chain is not supported");
        require(_amount > 0, "Bridge: amount must be greater than 0");
        require(bytes(_chain).length > 0, "Bridge: target chain cannot be empty");

        // Check that the user has sufficient allowance
        require(IERC20(_token).allowance(msg.sender, address(this)) >= _amount, "Bridge: insufficient allowance");

        // Increment the bridge ID counter and create a new bridge request
        _bridgeIdCounter.increment();
        uint256 bridgeId = _bridgeIdCounter.current();
        bridgeRequests[bridgeId] = BridgeRequest(msg.sender, _token, _amount, _chain, BridgeStatus.Initiated, block.timestamp);

        emit BridgeInitiated(bridgeId, msg.sender, _token, _amount, _chain);

        // Transfer the tokens from the user to the contract
        bool success = IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        require(success, "Bridge: token transfer failed");
    }

    function bridge(
        uint256 _bridgeId,
        address _to
    ) external onlyOwner nonReentrant {
        require(bridgeRequests[_bridgeId].status == BridgeStatus.Initiated, "Bridge request is not in initiated state");
        require(_to != address(0), "Bridge: recipient address cannot be 0");

        // Transfer the tokens from the contract to the recipient
        bool success = IERC20(bridgeRequests[_bridgeId].token).transfer(_to, bridgeRequests[_bridgeId].amount);
        require(success, "Bridge: token transfer failed");
    }

    function completeBridge(uint256 _bridgeId) external onlyOwner {
        require(bridgeRequests[_bridgeId].status == BridgeStatus.Initiated, "Bridge request is not in initiated state");
        
        bridgeRequests[_bridgeId].status = BridgeStatus.Completed;
        
        emit BridgeCompleted(_bridgeId, bridgeRequests[_bridgeId].user, bridgeRequests[_bridgeId].token, bridgeRequests[_bridgeId].amount, bridgeRequests[_bridgeId].targetChain);
    }

    function failBridge(uint256 _bridgeId) external onlyOwner {
        require(bridgeRequests[_bridgeId].status == BridgeStatus.Initiated, "Bridge request is not in initiated state");
        
        bridgeRequests[_bridgeId].status = BridgeStatus.Failed;
        
        emit BridgeFailed(_bridgeId, bridgeRequests[_bridgeId].user, bridgeRequests[_bridgeId].token, bridgeRequests[_bridgeId].amount, bridgeRequests[_bridgeId].targetChain);
    }


}