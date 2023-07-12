// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is Ownable, ReentrancyGuard, IERC721Receiver {
    // address of the NFT
    address public _addressNFTCollection;
    // address of the payment token
    address public _addressPaymentToken;

    // Index of auctions
    uint256 public index;

    // Structure to define auction properties
    struct NFTDetail {
        uint256 index; // Index
        uint256 nftId; // NFT Id
        address creator; // Creator of the Auction
        uint256 bidCount; // Number of bid placed on the auction
        uint256 endAuction; // Timestamp for the end day&time of the auction
        uint256 currentBidPrice; // Current highest bid for the auction
        address addressPaymentToken; // Address of the ERC20 Payment Token contract
        address payable currentBidOwner; // Address of the highest bider
        bool forSale; // On Sale or Auction
    }

    // Array will all auctions
    mapping(uint256 => NFTDetail) public nftDetails;

    // Public event to notify that a new auction has been created
    event NewAuction(
        uint256 index,
        uint256 nftId,
        address mintedBy,
        address currentBidOwner,
        uint256 currentBidPrice,
        uint256 endAuction,
        uint256 bidCount
    );
    // Public event to notify that a new sale has been created
    event NewSale(
        uint256 index,
        uint256 nftId,
        address mintedBy,
        uint256 price
    );

    // Public event to notify that nft sold
    event NFTSold(uint256 nftId, uint256 _price);

    // Public event to notify that a new bid has been placed
    event NewBidOnAuction(uint256 nftId, uint256 newBid);

    // Public event to notif that winner of an
    // auction claim for his reward
    event AuctionFinalized(uint256 nftId, address finalizedBy);

    // Public event to notify that an NFT has been refunded to the
    // creator of an auction
    event NFTRefunded(uint256 nftId, address claimedBy);

    // constructor of the contract
    constructor(address _nft, address _paymentToken) {
        _addressNFTCollection = _nft;
        _addressPaymentToken = _paymentToken;
    }
    
    /**
     * Check if a specific address is
     * a contract address
     * @param _addr: address to verify
     */
    function isContract(address _addr) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    /**
     * Create a new auction of a specific NFT
     * @param _nftId Id of the NFT for sale
     * @param _initialBid Inital bid decided by the creator of the auction
     * @param _endAuction Timestamp with the end date and time of the auction
     */
    function createAuction(
        uint256 _nftId,
        uint256 _initialBid,
        uint256 _endAuction
    ) external returns (uint256) {
        // Check if already on sale.
        require(!nftDetails[_nftId].forSale, "Already on sale!");

        // Check if the endAuction time is valid
        require(_endAuction > block.timestamp, "Invalid end date for auction");

        // Check if the initial bid price is > 0
        require(_initialBid != 0, "Invalid initial bid price");

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(_addressNFTCollection);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // Lock NFT in Marketplace contract
        // nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);

        //Casting from address to address payable
        address payable currentBidOwner = payable(address(0));
        // Create new Auction object
        NFTDetail memory newAuction = NFTDetail({
            index: index,
            addressPaymentToken: _addressPaymentToken,
            nftId: _nftId,
            creator: msg.sender,
            currentBidOwner: currentBidOwner,
            currentBidPrice: _initialBid,
            endAuction: _endAuction,
            bidCount: 0,
            forSale: true
        });

        //update list
        nftDetails[_nftId] = newAuction;

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewAuction(
            index,
            _nftId,
            msg.sender,
            currentBidOwner,
            _initialBid,
            _endAuction,
            0
        );
        return index;
    }

    /**
     * Create a new sale of a specific NFT
     * @param _nftId Id of the NFT for sale
     * @param _nftPrice Inital bid decided by the creator of the auction
     */
    function createSale(uint256 _nftId, uint256 _nftPrice)
        external
        returns (uint256)
    {
        // Check if already on sale
        require(!nftDetails[_nftId].forSale, "Already on sale!");
        //Check is addresses are valid

        require(_nftPrice != 0, "Invalid nft price");

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(_addressNFTCollection);

        // Make sure the sender that wants to create a new auction
        // for a specific NFT is the owner of this NFT
        require(
            nftCollection.ownerOf(_nftId) == msg.sender,
            "Caller is not the owner of the NFT"
        );

        // Lock NFT in Marketplace contract
        // nftCollection.safeTransferFrom(msg.sender, address(this), _nftId);

        // Create new Auction object
        NFTDetail memory newSale = NFTDetail({
            index: index,
            nftId: _nftId,
            forSale: true,
            addressPaymentToken: _addressPaymentToken,
            creator: msg.sender,
            currentBidOwner: payable(address(0)),
            currentBidPrice: _nftPrice,
            endAuction: 0,
            bidCount: 0
        });

        //update list
        nftDetails[_nftId] = newSale;

        // increment auction sequence
        index++;

        // Trigger event and return index of new auction
        emit NewSale(index, _nftId, msg.sender, _nftPrice);
        return index;
    }

    function cancelNFTSale(uint256 _nftId) external nonReentrant {
        // Get NFT detail
        NFTDetail storage nftInfo = nftDetails[_nftId];
        // Check if already on sale
        require(nftInfo.forSale, "Not for sale!");

        // Check if the caller is the winner of the auction
        require(
            nftInfo.creator == msg.sender,
            "Sale can be cancelled only by the current owner"
        );

        // Get NFT collection contract
        // IERC721 nftCollection = IERC721(_addressNFTCollection);
        // nftCollection.safeTransferFrom(address(this), nftInfo.creator, _nftId);

        if (nftInfo.currentBidOwner != address(0)) {
            // Get ERC20 Payment token contract
            IERC20 paymentToken = IERC20(nftInfo.addressPaymentToken);
            require(
                paymentToken.transfer(
                    nftInfo.currentBidOwner,
                    nftInfo.currentBidPrice
                )
            );
        }

        delete nftDetails[_nftId];
    }

    /**
     * Check if an auction is open
     * @param _nftId id of nft
     */
    function isOpen(uint256 _nftId) public view returns (bool) {
        NFTDetail storage auction = nftDetails[_nftId];
        if (!auction.forSale) return false;
        if (block.timestamp >= auction.endAuction) return false;
        return true;
    }

    /**
     * Return the address of the current highest bider
     * for a specific auction
     * @param _nftId id of nft
     */
    function getCurrentBidOwner(uint256 _nftId) public view returns (address) {
        require(nftDetails[_nftId].forSale, "Not for sale");
        return nftDetails[_nftId].currentBidOwner;
    }

    /**
     * Return the current highest bid price
     * for a specific auction
     * @param _nftId id of nft
     */
    function getCurrentBid(uint256 _nftId) public view returns (uint256) {
        require(nftDetails[_nftId].forSale, "Not for sale");
        return nftDetails[_nftId].currentBidPrice;
    }

    /**
     * Place new bid on a specific auction
     * @param _nftId id of nft
     * @param _newBid New bid price
     */
    function bid(uint256 _nftId, uint256 _newBid) external nonReentrant {
        NFTDetail storage auction = nftDetails[_nftId];

        // check if auction is still open
        require(
            auction.endAuction != 0 && auction.forSale,
            "Auction is not open"
        );

        // check if auction is still open
        require(isOpen(_nftId), "Auction is not open");

        // check if new bid price is higher than the current one
        require(
            _newBid > auction.currentBidPrice,
            "New bid price must be higher than the current bid"
        );

        // check if new bider is not the owner
        require(
            msg.sender != auction.creator,
            "Creator of the auction cannot place new bid"
        );

        // get ERC20 token contract
        IERC20 paymentToken = IERC20(auction.addressPaymentToken);

        // transfer token from new bider account to the marketplace account
        // to lock the tokens
        paymentToken.transferFrom(msg.sender, address(this), _newBid);

        // new bid is valid so must refund the current bid owner (if there is one!)
        if (auction.bidCount > 0) {
            paymentToken.transfer(
                auction.currentBidOwner,
                auction.currentBidPrice
            );
        }

        // update auction info
        address payable newBidOwner = payable(msg.sender);
        auction.currentBidOwner = newBidOwner;
        auction.currentBidPrice = _newBid;
        auction.bidCount++;

        // Trigger public event
        emit NewBidOnAuction(_nftId, _newBid);
    }

    /**
     * Buy nft from fix price sale
     * @param _nftId id of nft
     */
    function buyNFTOnSale(uint256 _nftId) external nonReentrant returns (bool) {
        NFTDetail storage auction = nftDetails[_nftId];

        // check if auction is still open
        require(
            auction.endAuction == 0 && auction.forSale,
            "Not available for fix price"
        );

        // check if new bider is not the owner
        require(
            msg.sender != auction.creator,
            "Creator of the auction cannot buy"
        );

        // get ERC20 token contract
        IERC20 paymentToken = IERC20(auction.addressPaymentToken);
        // transfer token from new bider account to the owner
        require(
            paymentToken.transferFrom(
                msg.sender,
                auction.creator,
                auction.currentBidPrice
            ),
            "Tranfer of token failed"
        );

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(_addressNFTCollection);
        // Transfer NFT from marketplace contract
        // to the winner address
        nftCollection.safeTransferFrom(auction.creator, msg.sender, _nftId);

        // Trigger public event
        emit NFTSold(_nftId, auction.currentBidPrice);
        delete nftDetails[_nftId];

        return true;
    }

    /**
     * Function used to finalize an auction
     * to withdraw his NFT.
     * When the NFT is withdrawn, the creator of the
     * auction will receive the payment tokens in his wallet
     * @param _nftId id of nft
     */
    function finalizeAuction(uint256 _nftId) external {
        // Check if the auction is closed
        require(!isOpen(_nftId), "Auction is still open");

        // Get auction
        NFTDetail storage auction = nftDetails[_nftId];

        // Check if the caller is the winner of the auction
        require(
            msg.sender == auction.currentBidOwner ||
                msg.sender == auction.creator,
            "Auction can only be finalize by the current bid owner or creator"
        );

        // Get NFT collection contract
        IERC721 nftCollection = IERC721(_addressNFTCollection);
        // Transfer NFT from marketplace contract
        // to the winner address
        nftCollection.safeTransferFrom(
            auction.creator,
            auction.currentBidOwner,
            _nftId
        );

        // Get ERC20 Payment token contract
        IERC20 paymentToken = IERC20(auction.addressPaymentToken);
        // Transfer locked token from the marketplace
        // contract to the auction creator address
        require(
            paymentToken.transfer(auction.creator, auction.currentBidPrice)
        );

        delete nftDetails[_nftId];
        emit AuctionFinalized(_nftId, msg.sender);
    }

    function withdrawStuckTokens(address _token, uint256 _amount)
        external
        onlyOwner
    {
        IERC20(_token).transfer(owner(), _amount);
    }

    function withdrawFunds(uint256 _amount) external onlyOwner {
        payable(owner()).transfer(_amount);
    }

    function setNFTContract(address _nft) external onlyOwner {
        _addressNFTCollection = _nft;
    }

    function setTokenContract(address _token) external onlyOwner {
        _addressPaymentToken = _token;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
interface IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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