// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

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

pragma solidity ^0.8.0;

import "./IFractionalNFT.sol";
import "./IFractionalToken.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

contract NFTVault is Ownable, KeeperCompatibleInterface {
    IFractionalNFT public nftContract;
    IFractionalToken public fractionalToken;
    AggregatorV3Interface public priceFeed;
    mapping(uint256 => address) public depositor;

    constructor(
        address _nftContract,
        address _fractionalToken,
        address _priceFeed
    ) {
        nftContract = IFractionalNFT(_nftContract);
        fractionalToken = IFractionalToken(_fractionalToken);
        priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getDepositor(
        uint256 tokenId
    ) external view returns (address depositorAddress) {
        depositorAddress = depositor[tokenId];
    }

    function depositNFT(uint256 nftTokenId) public onlyOwner {
        require(
            !nftContract.getIsFractionalized(nftTokenId),
            "Fractional tokens already minted"
        );
        depositor[nftTokenId] = nftContract.ownerOf(nftTokenId);
        // Get the latest price of gold from the Chainlink Price Feed
        // (, int256 price, , , ) = priceFeed.latestRoundData();

        // Transfer the NFT to the vault
        nftContract.transferFrom(
            nftContract.ownerOf(nftTokenId),
            address(this),
            nftTokenId
        );
        _fractionalize(nftTokenId);
    }

    function withdrawNFT(uint256 nftTokenId) public onlyOwner {
        //burn function
        fractionalToken.burn(
            depositor[nftTokenId],
            nftContract.getFractionalSupply(nftTokenId)
        );
        //transfer nft to sender
        nftContract.transferFrom(
            address(this),
            depositor[nftTokenId],
            nftTokenId
        );
        //wipe depositor from mapping
        delete (depositor[nftTokenId]);
    }

    function _fractionalize(uint256 tokenId) private {
        require(nftContract.exists(tokenId), "Token ID does not exist");
        require(
            !nftContract.getIsFractionalized(tokenId),
            "Token ID is already fractionalized"
        );
        uint256 totalSupply = nftContract.getFractionalSupply(tokenId);
        nftContract.updateIsFractionalized(tokenId, true);
        fractionalToken.mint(depositor[tokenId], totalSupply);
    }

    //-------->>>IMPLEMENT FOR  PHASE 2
    //Chainlink Keeper function
    function checkUpkeep(
        bytes calldata checkData
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        uint256[] memory tokensToFractionalize = new uint256[](
            nftContract.getTokenIdsCount()
        );
        uint256 count = 0;
        for (uint256 i = 0; i < nftContract.getTokenIdsCount(); i++) {
            uint256 tokenId = nftContract.getTokenIdByIndex(i);
            bool isFractionalized = nftContract.getIsFractionalized(tokenId);
            if (!isFractionalized) {
                tokensToFractionalize[count] = tokenId;
                count++;
            }
        }
        if (count > 0) {
            upkeepNeeded = true;
            performData = abi.encode(tokensToFractionalize, count);
        } else {
            upkeepNeeded = false;
            performData = "0x";
        }
    }

    // Chainlink Keeper function
    function performUpkeep(bytes calldata performData) external override {
        (uint256[] memory tokensToFractionalize, uint256 count) = abi.decode(
            performData,
            (uint256[], uint256)
        );
        for (uint256 i = 0; i < count; i++) {
            uint256 tokenId = tokensToFractionalize[i];
            _fractionalize(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFractionalNFT {
    struct Fractionalization {
        address fractionalToken; // Use address type for the interface
        bool isFractionalized;
        uint256 totalSupply;
    }

    function mint(uint256 tokenId, uint256 totalSupply) external;

    function exists(uint256 tokenId) external view returns (bool);

    function ownerOf(uint256 tokenId) external view returns (address);

    function transferFrom(address from, address to, uint256 tokenId) external;

    // Get the Fractionalization struct for a specific token ID
    // function getFractionalization(
    //     uint256 tokenId
    // ) external view returns (Fractionalization memory);

    function getIsFractionalized(uint256 tokenId) external view returns (bool);

    function getFractionalSupply(
        uint256 tokenId
    ) external view returns (uint256);

    //update boool after fractionalization
    function updateIsFractionalized(uint tokenId, bool updateBool) external;

    //update totalSupply after burn
    function updateTotalSupply(uint256 tokenId, uint256 amount) external;

    // Get the total number of token IDs
    function getTokenIdsCount() external view returns (uint256);

    // Get a specific token ID by index
    function getTokenIdByIndex(uint256 index) external view returns (uint256);

    // Fractionalize a specific token ID
    function fractionalize(uint256 tokenId) external;

    // Event emitted when a token is fractionalized
    event TokenFractionalized(
        uint256 indexed tokenId,
        address fractionalToken,
        uint256 totalSupply
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IFractionalToken {
    function totalSupply() external view returns (uint256);

    function setClaimAmount(
        address _claimAddress,
        uint256 _claimAmount
    ) external;

    function claim(address to) external view returns (bool);

    function mint(address to, uint256 amount) external;

    function burn(address account, uint256 amount) external;
}