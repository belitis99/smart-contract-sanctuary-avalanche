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
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IAddressBook.sol";

/**
 * @title Address book with portals, synthesis etc.
 */
contract AddressBook is IAddressBook, Ownable {

    struct Record {
        /// @dev chainId chain id
        uint64 chainId;
        /// @dev portal/sinthesis address in chainId chain
        address clpEndPoint;
    }

    /// @dev chainId -> portal address
    mapping(uint64 => address) public portal;
    /// @dev chainId -> synthesis address
    mapping(uint64 => address) public synthesis;
    /// @dev chainId -> router address
    mapping(uint64 => address) public router;
    /// @dev chainId -> cryptoPoolAdapter address
    mapping(uint64 => address) public cryptoPoolAdapter;
    /// @dev chainId -> stablePoolAdapter address
    mapping(uint64 => address) public stablePoolAdapter;

    function setPortal(Record[] memory records) external onlyOwner {
        _setRecords(portal, records);
    }

    function setSynthesis(Record[] memory records) external onlyOwner {
        _setRecords(synthesis, records);
    }

    function setRouter(Record[] memory records) external onlyOwner {
        _setRecords(router, records);
    }

    function setCryptoPoolAdapter(Record[] memory records) external onlyOwner {
        _setRecords(cryptoPoolAdapter, records);
    }

    function setStablePoolAdapter(Record[] memory records) external onlyOwner {
        _setRecords(stablePoolAdapter, records);
    }

    function _setRecords(mapping(uint64 => address) storage map_, Record[] memory records) private {
        for (uint256 i = 0; i < records.length; ++i) {
            map_[records[i].chainId] = records[i].clpEndPoint;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;


interface IAddressBook {
    /// @dev returns portal by given chainId
    function portal(uint64 chainId) external returns (address);

    /// @dev returns synthesis by given chainId
    function synthesis(uint64 chainId) external returns (address);

    /// @dev returns router by given chainId
    function router(uint64 chainId) external returns (address);

    /// @dev returns cryptoPoolAdapter by given chainId
    function cryptoPoolAdapter(uint64 chainId) external returns (address);

    /// @dev returns stablePoolAdapter by given chainId
    function stablePoolAdapter(uint64 chainId) external returns (address);
}