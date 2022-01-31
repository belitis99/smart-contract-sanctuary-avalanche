// contracts/utilities/AssetStore.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUtilityBase.sol";

contract AssetStore {
  uint16 public constant REGISTER_PERCENT = 200;
  uint16 public constant DISCOUNT_PERCENT = 1000;
  uint16 public constant REWARD_PERCENT = 2500;

  struct Asset {
    string name;
    string promo;
    string[] asset;
    address author;
    uint256 price;
    uint256 limit;
  }

  event AssetAdded(uint256 assetId, Asset asset);
  event AssetDiscounted(uint256 assetId, uint256 discount);
  event RewardsClaimed(address artist, uint256 rewards);

  uint8 public states;
  Asset[] public assets;

  mapping(uint256 => uint256) public discounts;

  mapping(uint256 => uint256) private rewardClaims;
  mapping(uint256 => uint256) private reserveClaims;
  mapping(uint256 => uint256) public mints;
  mapping(uint256 => uint256) public mintWithDiscounts;

  constructor(uint8 states_) {
    states = states_;
  }

  modifier onlyOnSale(uint256 assetId, uint256 amount) {
    require(mints[assetId] + amount <= assets[assetId].limit, "Fully minted already");
    _;
  }

  function registerAsset(
    string calldata name,
    string calldata promo,
    string[] calldata asset,
    uint256 price_,
    uint256 limit_
  ) external payable virtual {
    require(asset.length == states, "Asset invalid");
    if (msg.sender != IUtilityBase(address(this)).owner()) {
      require(msg.value >= (price_ * limit_ * REGISTER_PERCENT) / 10000, "Fee insufficient");
    }

    uint256 assetId = assets.length;
    assets.push(Asset(name, promo, asset, msg.sender, price_, limit_));
    emit AssetAdded(assetId, assets[assetId]);
  }

  function totalAssets() public view returns (uint256 total) {
    total = assets.length;
  }

  function registerDiscount(uint256 assetId, uint256 discount_) external {
    require(assets[assetId].author == msg.sender, "Permission denied");
    require(discount_ > block.timestamp, "Discount invalid");

    discounts[assetId] = discount_;
    emit AssetDiscounted(assetId, discounts[assetId]);
  }

  function isDiscount(uint256 assetId) public view returns (bool discounted) {
    discounted = discounts[assetId] > block.timestamp;
  }

  function priceOrigin(uint256 assetId) public view returns (uint256) {
    return assets[assetId].price;
  }

  function price(uint256 assetId) public view returns (uint256) {
    require(assetId < totalAssets(), "Asset invalid");
    if (isDiscount(assetId)) {
      return (priceOrigin(assetId) * (10000 - DISCOUNT_PERCENT)) / 10000;
    } else {
      return priceOrigin(assetId);
    }
  }

  function useAsset(uint256 assetId, uint256 amount) internal onlyOnSale(assetId, amount) returns (uint256 newLock) {
    mints[assetId] += amount;
    uint256 assetPrice = priceOrigin(assetId);
    if (isDiscount(assetId)) {
      mintWithDiscounts[assetId] += amount;
      newLock = ((assetPrice * (REWARD_PERCENT - DISCOUNT_PERCENT)) / 10000) * amount;
    } else {
      newLock = ((assetPrice * REWARD_PERCENT) / 10000) * amount;
    }
  }

  function reward(uint256 assetId) public view returns (uint256) {
    uint256 mintPrice = assets[assetId].price;
    uint256 mintReward = ((mintPrice * REWARD_PERCENT) / 10000) * mints[assetId];
    uint256 discounted = ((mintPrice * DISCOUNT_PERCENT) / 10000) * mintWithDiscounts[assetId];
    return mintReward - discounted - rewardClaims[assetId];
  }

  function rewards(uint256[] calldata assetIds) external view returns (uint256 total) {
    for (uint16 i = 0; i < assetIds.length; i++) {
      total += reward(assetIds[i]);
    }
  }

  function _claimRewards(uint256[] calldata assetIds) internal returns (uint256 total) {
    for (uint16 i = 0; i < assetIds.length; i++) {
      uint256 assetId = assetIds[i];
      require(assets[assetId].author == msg.sender, "Permission denied");
      uint256 assetReward = reward(assetId);
      rewardClaims[assetId] += assetReward;
      total += assetReward;
    }
    payable(msg.sender).transfer(total);
    emit RewardsClaimed(msg.sender, total);
  }
}

// contracts/utilities/IUtilityBase.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IUtilityBase {
  function factory() external view returns (address);

  function owner() external view returns (address);

  function transferOwnership(address) external;
}

// contracts/utilities/StatefulURIEnumerable.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetStore.sol";
import "./ERC721BatchEnumerable.sol";

contract StatefulURIEnumerable is ERC721BatchEnumerable, AssetStore {
  event StateUpdated(uint256 tokenId, uint8 state);

  string public baseURI;

  mapping(uint256 => uint256) public tokenAssets;
  mapping(uint256 => uint8) private tokenStates;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI_,
    uint8 states_
  ) ERC721(name, symbol) AssetStore(states_) {
    baseURI = baseURI_;
  }

  function tokenAsset(uint256 tokenId) internal view returns (Asset memory asset) {
    asset = assets[tokenAssets[tokenId]];
  }

  function _mintItem(
    uint256 index,
    address to,
    uint256 amount
  ) internal returns (uint256, uint256) {
    uint256 newLock = AssetStore.useAsset(index, amount);
    (uint256 start, uint256 end) = increments(amount);
    for (; start <= end; start++) {
      _mint(to, start);
      tokenAssets[start] = index;
    }
    return (end, newLock);
  }

  function tokenState(uint256 tokenId) public view returns (uint8) {
    return tokenStates[tokenId];
  }

  modifier onlyState(uint256 tokenId, uint8 state) {
    require(tokenState(tokenId) == state, "State invalid");
    _;
  }

  function setTokenState(uint256 tokenId, uint8 state) internal {
    require(state < states, "Invalid state");
    tokenStates[tokenId] = state;
    emit StateUpdated(tokenId, state);
  }

  function renewState(uint256 tokenId) internal {
    setTokenState(tokenId, 0);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseURI, tokenAsset(tokenId).asset[tokenStates[tokenId]]));
  }

  modifier onlyNFTOwner(uint256 tokenId, address owner) {
    require(ownerOf(tokenId) == owner, "Permission denied");
    _;
  }
}

// contracts/utilities/ERC721BatchEnumerable.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Counters.sol";

abstract contract ERC721BatchEnumerable is ERC721Enumerable {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  function batchTransfer(address to, uint256[] calldata tokenIds) external {
    for (uint8 i = 0; i < tokenIds.length; i++) {
      transferFrom(msg.sender, to, tokenIds[i]);
    }
  }

  function batchTransfers(address[] calldata to, uint256[] calldata tokenIds) external {
    require(to.length == tokenIds.length);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      transferFrom(msg.sender, to[i], tokenIds[i]);
    }
  }

  function increments(uint256 amount) internal returns (uint256, uint256) {
    return _tokenIds.increments(amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// contracts/utilities/PortableURI.sol
// SPDX-License-Identifier: MIT

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

  function increment(Counter storage counter) internal returns (uint256) {
    unchecked {
      counter._value += 1;
    }
    return counter._value;
  }

  function increments(Counter storage counter, uint256 amount) internal returns (uint256 start, uint256 end) {
    start = counter._value + 1;
    unchecked {
      counter._value += amount;
    }
    return (start, counter._value);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
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
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721Receiver.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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

// contracts/utilities/UTBGiftBox.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../features/StatefulURIEnumerable.sol";
import "../features/VaultMemeV2.sol";
import "../features/UtilityBase.sol";

contract UTBMysteryBox is StatefulURIEnumerable, VaultMemeV2, UtilityBase {
  uint8 public constant STATE_NORMAL = 0;
  uint8 public constant STATE_READY = 1;
  uint8 public constant STATE_SURPRISE = 2;

  struct Package {
    uint256 prize;
    uint256 stock;
  }

  struct Company {
    address owner;
    address treasury;
    string[] company;
    address token;
    uint256 totalPrize;
  }

  mapping(uint256 => Company) public companies;
  mapping(uint256 => Package[]) public packages;
  mapping(uint256 => uint256) public distributes;
  mapping(address => uint256) public timestamps;
  mapping(address => bool) public whitelists;

  uint256 seed;

  constructor(
    address factory,
    string memory baseURI,
    string memory promo
  ) StatefulURIEnumerable("Utilitybia - Mystery Box", "UTBMysteryBox", baseURI, 3) UtilityBase(factory, promo) {
    seed = uint256(keccak256(abi.encodePacked(block.timestamp, factory, msg.sender)));
  }

  function addWhitelist(address whitelist, bool state) external onlyOwner {
    whitelists[whitelist] = state;
  }

  function registerAsset(
    string calldata,
    string calldata,
    string[] calldata,
    uint256,
    uint256
  ) external payable virtual override {
    require(false, "Permission denied");
  }

  function registerCompanyAsset(
    string calldata name,
    string calldata promo,
    string[] calldata asset,
    uint256 price_,
    uint256 limit_,
    address treasury,
    string[] memory company,
    address token,
    uint256[] memory prizes
  ) external payable {
    if (msg.sender != owner && !whitelists[msg.sender]) {
      require(msg.value >= (price_ * limit_ * REGISTER_PERCENT) / 10000, "Fee insufficient");
    }
    require(prizes.length % 2 == 0, "Prize invalid");

    uint256 assetId = assets.length;
    assets.push(Asset(name, promo, asset, address(0), price_, limit_));

    uint256 totalPrize;
    for (uint256 i = 0; i < prizes.length; i += 2) {
      packages[assetId].push(Package(prizes[i], prizes[i + 1]));
      totalPrize += prizes[i] * prizes[i + 1];
    }

    IERC20(token).transferFrom(msg.sender, address(this), totalPrize);
    companies[assetId] = Company(msg.sender, treasury, company, token, totalPrize);
    emit AssetAdded(assetId, assets[assetId]);
  }

  function withdrawCompanyAsset(uint256 companyId) external {
    require(companies[companyId].owner == msg.sender, "Permission denied");
    uint256 totalPrize = companies[companyId].totalPrize;
    uint256 distributed = distributes[companyId];
    if (totalPrize < distributed) {
      IERC20(companies[companyId].token).transfer(msg.sender, totalPrize - distributed);
      distributes[companyId] = totalPrize;
    }
  }

  function depositCompanyAsset(uint256 companyId, uint256 amount) external {
    require(companies[companyId].owner == msg.sender, "Permission denied");
    uint256 distributed = distributes[companyId];
    if (amount <= distributed) {
      IERC20(companies[companyId].token).transfer(msg.sender, amount);
      distributes[companyId] -= amount;
    }
  }

  function getRandomPrize(
    uint256 companyId,
    uint256 totalLeft,
    uint256 total
  ) internal returns (uint256) {
    seed = uint256(keccak256(abi.encodePacked(block.timestamp, seed, msg.sender)));
    uint256 rand = totalLeft - (((seed % totalLeft) * total) % totalLeft);
    Package[] memory companyPackages = packages[companyId];
    uint256 count;
    for (uint256 i = 0; i < companyPackages.length; i++) {
      count += companyPackages[i].stock;
      if (rand <= count) {
        packages[companyId][i].stock -= 1;
        return companyPackages[i].prize;
      }
    }
    return 0;
  }

  function buyItem(uint256 assetId, uint256 amount) public payable returns (uint256) {
    require(msg.value >= price(assetId) * amount, "Fee insufficient");
    uint256 mintsMax = assets[assetId].limit;
    uint256 mintsLeft = mintsMax - mints[assetId];
    require(mintsLeft >= amount, "No more mints left");
    (uint256 end, ) = _mintItem(assetId, msg.sender, amount);

    address token = companies[assetId].token;
    uint256 totalPrize = companies[assetId].totalPrize;
    uint256 distributed = distributes[assetId];

    for (uint256 i = 0; i < amount; i++) {
      uint256 distribute = getRandomPrize(assetId, mintsLeft - i, mintsMax);
      distributed += distribute;
      require(distributed <= totalPrize);
      uint256 tokenId = end - i;
      VaultMemeV2.registerERC20(tokenId, token, distribute);
      setTokenState(tokenId, STATE_READY);
    }

    distributes[assetId] = distributed;
    payable(companies[assetId].treasury).transfer(msg.value);
    timestamps[msg.sender] = block.timestamp;
    return end;
  }

  function wrap(uint256 tokenId) public onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_NORMAL) {
    setTokenState(tokenId, STATE_READY);
  }

  function depositERC20(
    uint256 tokenId,
    address[] memory token,
    uint256[] memory amount
  ) public payable virtual override onlyState(tokenId, STATE_NORMAL) {
    if (msg.value > 0) {
      addLock(msg.value);
    }
    VaultMemeV2.depositERC20(tokenId, token, amount);
  }

  function depositERC20AndWrap(
    uint256 tokenId,
    address[] memory token,
    uint256[] memory amount
  ) public payable {
    depositERC20(tokenId, token, amount);
    wrap(tokenId);
  }

  function viewETH(uint256 tokenId) public view virtual override returns (uint256 amount) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      amount = VaultMemeV2.viewETH(tokenId);
    } else {
      amount = 0;
    }
  }

  function viewERC20s(uint256 tokenId) public view virtual override returns (address[] memory tokens) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      tokens = VaultMemeV2.viewERC20s(tokenId);
    }
  }

  function viewERC20Amount(uint256 tokenId, address token) public view virtual override returns (uint256 amount) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      amount = VaultMemeV2.viewERC20Amount(tokenId, token);
    }
  }

  function open(uint256 tokenId) external onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_READY) {
    setTokenState(tokenId, uint8(STATE_SURPRISE));
  }

  function claimDeposits(uint256 tokenId)
    external
    onlyNFTOwner(tokenId, msg.sender)
    onlyState(tokenId, STATE_SURPRISE)
  {
    uint256 newUnlock = _claimDeposits(tokenId);
    removeLock(newUnlock);
    renewState(tokenId);
  }

  function claimRewards(uint256[] calldata) external pure {
    require(false, "Permission denied");
  }

  function openable(address user) external view returns (uint256[] memory) {
    uint256 tokenCount = balanceOf(user);
    uint256[] memory tokenIds = new uint256[](tokenCount);
    for (uint256 index = 0; index < tokenCount; index++) {
      uint256 tokenId = tokenOfOwnerByIndex(user, index);
      if (tokenState(tokenId) == uint8(STATE_READY)) {
        tokenIds[index] = tokenId;
      }
    }
    return tokenIds;
  }

  function opens(uint256[] memory tokenIds) external {
    for (uint256 index = 0; index < tokenIds.length; index++) {
      uint256 tokenId = tokenIds[index];
      require(tokenState(tokenId) == uint8(STATE_READY));
      require(ownerOf(tokenId) == msg.sender);
      setTokenState(tokenId, uint8(STATE_SURPRISE));
    }
  }

  function openAll() external {
    address user = msg.sender;
    require(block.timestamp > timestamps[user]);

    uint256 tokenCount = balanceOf(user);
    for (uint256 index = 0; index < tokenCount; index++) {
      uint256 tokenId = tokenOfOwnerByIndex(user, index);
      if (tokenState(tokenId) == uint8(STATE_READY)) {
        setTokenState(tokenId, uint8(STATE_SURPRISE));
      }
    }
  }

  function claimAll() external {
    address user = msg.sender;
    uint256 tokenCount = balanceOf(user);
    for (uint256 index = 0; index < tokenCount; index++) {
      uint256 tokenId = tokenOfOwnerByIndex(user, index);
      if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
        uint256 newUnlock = _claimDeposits(tokenId);
        removeLock(newUnlock);
        renewState(tokenId);
      }
    }
  }
}

// contracts/utilities/VaultMemeV2.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IUtilityBase.sol";

contract VaultMemeV2 {
  mapping(uint256 => uint256) private deposits;
  mapping(uint256 => address[]) private tokenERC20s;
  mapping(uint256 => mapping(address => uint256)) private depositERC20s;

  constructor() {}

  function depositERC20(
    uint256 tokenId,
    address[] memory tokens,
    uint256[] memory amounts
  ) public payable virtual {
    if (msg.value > 0) {
      deposits[tokenId] += msg.value;
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 amount = amounts[i];
      IERC20(token).transferFrom(msg.sender, address(this), amount);
      if (depositERC20s[tokenId][token] == 0) {
        tokenERC20s[tokenId].push(token);
      }
      depositERC20s[tokenId][token] += amount;
    }
  }

  function registerERC20(
    uint256 tokenId,
    address token,
    uint256 amount
  ) internal {
    if (depositERC20s[tokenId][token] == 0) {
      tokenERC20s[tokenId].push(token);
    }
    depositERC20s[tokenId][token] += amount;
  }

  function viewETH(uint256 tokenId) public view virtual returns (uint256 amount) {
    amount = deposits[tokenId];
  }

  function viewERC20s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC20s[tokenId];
  }

  function viewERC20Amount(uint256 tokenId, address token) public view virtual returns (uint256 amount) {
    amount = depositERC20s[tokenId][token];
  }

  function _claimDeposits(uint256 tokenId) internal returns (uint256 newUnlock) {
    if (deposits[tokenId] > 0) {
      payable(msg.sender).transfer(deposits[tokenId]);
      newUnlock = deposits[tokenId];
      delete deposits[tokenId];
    }

    if (tokenERC20s[tokenId].length > 0) {
      mapping(address => uint256) storage tokenDeposits = depositERC20s[tokenId];
      for (uint256 i = 0; i < tokenERC20s[tokenId].length; i++) {
        IERC20(tokenERC20s[tokenId][i]).transfer(msg.sender, tokenDeposits[tokenERC20s[tokenId][i]]);
        delete depositERC20s[tokenId][tokenERC20s[tokenId][i]];
      }
      delete tokenERC20s[tokenId];
    }
  }
}

// contracts/utilities/UtilityBase.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/IUtilitybia.sol";

contract UtilityBase {
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  IUtilitybia public factory;
  address public owner;
  string public promo;

  uint256 public locked;

  constructor(address _factory, string memory _promo) {
    factory = IUtilitybia(_factory);
    owner = msg.sender;
    promo = _promo;
  }

  modifier onlyFactory() {
    require(address(factory) == msg.sender, "Permission denied");
    _;
  }

  modifier onlyOwner() {
    require(owner == msg.sender, "Permission denied");
    _;
  }

  function transferOwnership(address newOwner) external onlyFactory {
    withdrawFunds();
    address oldOwner = owner;
    owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function updatePromo(string calldata _promo) external onlyOwner {
    promo = _promo;
  }

  function withdraw() external onlyOwner {
    withdrawFunds();
  }

  function withdrawFunds() internal {
    uint256 funds = address(this).balance - locked;
    if (funds > 0) {
      if (owner == factory.owner()) {
        payable(address(factory)).transfer(funds);
      } else {
        uint256 factoryFund = (funds * factory.WITHDRAW_PERCENT()) / 10000;
        payable(address(factory)).transfer(factoryFund);
        funds = funds - factoryFund;
        payable(owner).transfer(funds);
      }
    }
  }

  function addLock(uint256 amount) internal {
    locked += amount;
  }

  function removeLock(uint256 amount) internal {
    locked -= amount;
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

pragma solidity ^0.8.0;

interface IUtilitybia {
  function WITHDRAW_PERCENT() external view returns (uint8);

  function owner() external view returns (address);

  function registerAuction() external;

  function deregisterAuction() external;
}

// contracts/utilities/UTBPiggyBank.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../features/StatefulURI.sol";
import "../features/VaultMeme.sol";
import "../features/UtilityBase.sol";

contract UTBPiggyBank is StatefulURI, VaultMeme, UtilityBase {
  uint8 public constant STATE_NORMAL = 0;
  uint8 public constant STATE_BROKEN = 1;

  uint16 public constant RENEW_PERCENT = 5000;

  constructor(
    address factory,
    string memory baseURI,
    string memory promo
  ) StatefulURI("Utilitybia - Piggy Bank", "UTBPiggyBank", baseURI, 2) VaultMeme() UtilityBase(factory, promo) {}

  function buyItem(uint256 assetId, uint256 amount) public payable returns (uint256) {
    require(msg.value >= price(assetId) * amount, "Fee insufficient");
    (uint256 end, uint256 newLock) = _mintItem(assetId, msg.sender, amount);
    addLock(newLock);
    return end;
  }

  function depositERC20(
    uint256 tokenId,
    address[] memory token,
    uint256[] memory amount
  ) public payable virtual override onlyState(tokenId, STATE_NORMAL) {
    if (msg.value > 0) {
      addLock(msg.value);
    }
    VaultMeme.depositERC20(tokenId, token, amount);
  }

  function viewETH(uint256 tokenId) public view virtual override returns (uint256 amount) {
    if (tokenState(tokenId) == STATE_BROKEN) {
      amount = VaultMeme.viewETH(tokenId);
    } else {
      amount = 0;
    }
  }

  function viewERC20s(uint256 tokenId) public view virtual override returns (address[] memory tokens) {
    if (tokenState(tokenId) == STATE_BROKEN) {
      tokens = VaultMeme.viewERC20s(tokenId);
    }
  }

  function viewERC20Amount(uint256 tokenId, address token) public view virtual override returns (uint256 amount) {
    if (tokenState(tokenId) == STATE_BROKEN) {
      amount = VaultMeme.viewERC20Amount(tokenId, token);
    }
  }

  function breakOut(uint256 tokenId) external onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_NORMAL) {
    setTokenState(tokenId, STATE_BROKEN);
  }

  function claimDeposits(uint256 tokenId) external onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_BROKEN) {
    uint256 newUnlock = _claimDeposits(tokenId);
    removeLock(newUnlock);
  }

  function renew(uint256 tokenId) external payable onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_BROKEN) {
    require(msg.value >= (price(tokenAssets[tokenId]) * RENEW_PERCENT) / 10000, "Fee insufficient");
    renewState(tokenId);
  }

  function claimRewards(uint256[] calldata assetIds) public {
    uint256 total = _claimRewards(assetIds);
    removeLock(total);
  }
}

// contracts/utilities/StatefulURI.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetStore.sol";
import "./ERC721Batch.sol";

contract StatefulURI is ERC721Batch, AssetStore {
  event StateUpdated(uint256 tokenId, uint8 state);

  string public baseURI;

  mapping(uint256 => uint256) public tokenAssets;
  mapping(uint256 => uint8) private tokenStates;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI_,
    uint8 states_
  ) ERC721(name, symbol) AssetStore(states_) {
    baseURI = baseURI_;
  }

  function tokenAsset(uint256 tokenId) internal view returns (Asset memory asset) {
    asset = assets[tokenAssets[tokenId]];
  }

  function _mintItem(
    uint256 index,
    address to,
    uint256 amount
  ) internal returns (uint256, uint256) {
    uint256 newLock = AssetStore.useAsset(index, amount);
    (uint256 start, uint256 end) = increments(amount);
    for (; start <= end; start++) {
      _mint(to, start);
      tokenAssets[start] = index;
    }
    return (end, newLock);
  }

  function tokenState(uint256 tokenId) public view returns (uint8) {
    return tokenStates[tokenId];
  }

  modifier onlyState(uint256 tokenId, uint8 state) {
    require(tokenState(tokenId) == state, "State invalid");
    _;
  }

  function setTokenState(uint256 tokenId, uint8 state) internal {
    require(state < states, "Invalid state");
    tokenStates[tokenId] = state;
    emit StateUpdated(tokenId, state);
  }

  function renewState(uint256 tokenId) internal {
    setTokenState(tokenId, 0);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    return string(abi.encodePacked(baseURI, tokenAsset(tokenId).asset[tokenStates[tokenId]]));
  }

  modifier onlyNFTOwner(uint256 tokenId, address owner) {
    require(ownerOf(tokenId) == owner, "Permission denied");
    _;
  }
}

// contracts/utilities/VaultMeme.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IUtilityBase.sol";

contract VaultMeme {
  mapping(uint256 => uint256) private deposits;
  mapping(uint256 => address[]) private tokenERC20s;
  mapping(uint256 => mapping(address => uint256)) private depositERC20s;

  constructor() {}

  function depositERC20(
    uint256 tokenId,
    address[] memory tokens,
    uint256[] memory amounts
  ) public payable virtual {
    if (msg.value > 0) {
      deposits[tokenId] += msg.value;
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 amount = amounts[i];
      IERC20(token).transferFrom(msg.sender, address(this), amount);
      if (depositERC20s[tokenId][token] == 0) {
        tokenERC20s[tokenId].push(token);
      }
      depositERC20s[tokenId][token] += amount;
    }
  }

  function viewETH(uint256 tokenId) public view virtual returns (uint256 amount) {
    amount = deposits[tokenId];
  }

  function viewERC20s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC20s[tokenId];
  }

  function viewERC20Amount(uint256 tokenId, address token) public view virtual returns (uint256 amount) {
    amount = depositERC20s[tokenId][token];
  }

  function _claimDeposits(uint256 tokenId) internal returns (uint256 newUnlock) {
    if (deposits[tokenId] > 0) {
      payable(msg.sender).transfer(deposits[tokenId]);
      newUnlock = deposits[tokenId];
      delete deposits[tokenId];
    }

    if (tokenERC20s[tokenId].length > 0) {
      mapping(address => uint256) storage tokenDeposits = depositERC20s[tokenId];
      for (uint256 i = 0; i < tokenERC20s[tokenId].length; i++) {
        IERC20(tokenERC20s[tokenId][i]).transfer(msg.sender, tokenDeposits[tokenERC20s[tokenId][i]]);
        delete depositERC20s[tokenId][tokenERC20s[tokenId][i]];
      }
      delete tokenERC20s[tokenId];
    }
  }
}

// contracts/utilities/ERC721Batch.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Counters.sol";

abstract contract ERC721Batch is ERC721 {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  function batchTransfer(address to, uint256[] calldata tokenIds) external {
    for (uint8 i = 0; i < tokenIds.length; i++) {
      transferFrom(msg.sender, to, tokenIds[i]);
    }
  }

  function batchTransfers(address[] calldata to, uint256[] calldata tokenIds) external {
    require(to.length == tokenIds.length);
    for (uint8 i = 0; i < tokenIds.length; i++) {
      transferFrom(msg.sender, to[i], tokenIds[i]);
    }
  }

  function increments(uint256 amount) internal returns (uint256, uint256) {
    return _tokenIds.increments(amount);
  }

  function totalSupply() external view returns (uint256) {
    return _tokenIds.current();
  }
}

// contracts/utilities/Utilitybia.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IUtilityBase.sol";
import "./interfaces/ITreasuryDAO.sol";

contract Utilitybia is Ownable {
  string public constant name = "Utilitybia";
  uint16 public constant WITHDRAW_PERCENT = 500;
  uint16 public constant AUCTION_PERCENT = 500;

  struct Auction {
    uint256 index;
    address owner;
    uint256 price;
    address bidder;
  }

  event UtilityAdded(uint256 index, address indexed utility);
  event AuctionCreated(uint256 index, Auction auction);
  event AuctionUpdated(uint256 index, Auction auction);

  IUtilityBase[] public utilities;

  Auction[] public auctions;

  address public treasuryDAO;

  constructor() {}

  function transferUtilityOwnership(address utility, address newOwner) internal {
    IUtilityBase(utility).transferOwnership(newOwner);
  }

  function registerUtility(address utility, address owner) external onlyOwner {
    require(owner != address(0), "Owner invalid");
    IUtilityBase newUtility = IUtilityBase(utility);

    transferUtilityOwnership(utility, owner);

    utilities.push(newUtility);
    emit UtilityAdded(utilities.length - 1, utility);
  }

  function totalUtilities() external view returns (uint256 total) {
    total = utilities.length;
  }

  function registerAuction(uint256 index, uint256 price) external returns (uint256 auctionIndex) {
    require(utilities[index].owner() == msg.sender, "Owner invalid");

    auctionIndex = auctions.length;
    Auction memory newAuction = Auction(index, msg.sender, price, address(0));
    transferUtilityOwnership(address(utilities[index]), address(this));

    auctions.push(newAuction);
    emit AuctionCreated(auctionIndex, newAuction);
  }

  function totalAuctions() external view returns (uint256 total) {
    total = auctions.length;
  }

  function updateAuction(uint256 index, uint256 price) external {
    require(auctions[index].owner == msg.sender, "Permission denied");
    require(auctions[index].bidder == address(0), "Auction passed");

    auctions[index].price = price;
    emit AuctionUpdated(index, auctions[index]);
  }

  function bidAuction(uint256 index) external payable {
    require(auctions[index].bidder == address(0), "Auction passed");
    require(msg.value >= auctions[index].price, "Price invalid");

    auctions[index].bidder = msg.sender;
    payable(auctions[index].owner).transfer((msg.value * (10000 - AUCTION_PERCENT)) / 10000);
    transferUtilityOwnership(address(utilities[auctions[index].index]), msg.sender);
    emit AuctionUpdated(index, auctions[index]);
  }

  function cancelAuction(uint256 index) external {
    require(auctions[index].owner == msg.sender, "Permission denied");
    require(auctions[index].bidder == address(0), "Auction passed");

    auctions[index].bidder = msg.sender;
    transferUtilityOwnership(address(utilities[auctions[index].index]), msg.sender);
    emit AuctionUpdated(index, auctions[index]);
  }

  function setTreasuryDAO(address treasuryDAO_) external onlyOwner {
    require(treasuryDAO_ != address(0), "Treasury DAO invalid");
    treasuryDAO = treasuryDAO_;
  }

  function withdraw() external onlyOwner {
    uint256 funds = address(this).balance;
    if (treasuryDAO == address(0)) {
      payable(owner()).transfer(funds);
    } else {
      ITreasuryDAO(treasuryDAO).raise{ value: funds }();
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// contracts/utilities/ITreasuryDAO.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITreasuryDAO {
	function raise() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
contract ERC20 is Context, IERC20, IERC20Metadata {
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
    constructor(string memory name_, string memory symbol_) {
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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

// contracts/utilities/Vault.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import "../interfaces/IUtilityBase.sol";

contract Vault {
  struct TkERC1155 {
    uint256 tokenId;
    uint256 amount;
  }

  mapping(uint256 => uint256) private deposits;
  mapping(uint256 => address[]) private tokenERC20s;
  mapping(uint256 => mapping(address => uint256)) private depositERC20s;
  mapping(uint256 => address[]) private tokenERC721s;
  mapping(uint256 => mapping(address => uint256[])) private depositERC721s;
  mapping(uint256 => address[]) private tokenERC1155s;
  mapping(uint256 => mapping(address => TkERC1155[])) private depositERC1155s;

  constructor() {}

  function depositERC20(
    uint256 tokenId,
    address[] memory tokens,
    uint256[] memory amounts
  ) public payable virtual {
    if (msg.value > 0) {
      deposits[tokenId] += msg.value;
    }
    for (uint256 i = 0; i < tokens.length; i++) {
      address token = tokens[i];
      uint256 amount = amounts[i];
      IERC20(token).transferFrom(msg.sender, address(this), amount);
      if (depositERC20s[tokenId][token] == 0) {
        tokenERC20s[tokenId].push(token);
      }
      depositERC20s[tokenId][token] += amount;
    }
  }

  function depositERC721(
    uint256 tokenId,
    address[] memory erc721Tokens,
    uint256[] memory erc721TokenIds
  ) public virtual {
    for (uint256 i = 0; i < erc721Tokens.length; i++) {
      address erc721Token = erc721Tokens[i];
      uint256 erc721TokenId = erc721TokenIds[i];
      IERC721(erc721Token).transferFrom(msg.sender, address(this), erc721TokenId);
      if (depositERC721s[tokenId][erc721Token].length == 0) {
        tokenERC721s[tokenId].push(erc721Token);
      }
      depositERC721s[tokenId][erc721Token].push(erc721TokenId);
    }
  }

  function depositERC1155(
    uint256 tokenId,
    address[] memory erc1155Tokens,
    uint256[] memory erc1155TokenIds,
    uint256[] memory erc1155TokenAmounts
  ) public virtual {
    for (uint256 i = 0; i < erc1155Tokens.length; i++) {
      address erc1155Token = erc1155Tokens[i];
      uint256 erc1155TokenId = erc1155TokenIds[i];
      uint256 erc1155TokenAmount = erc1155TokenAmounts[i];
      IERC1155(erc1155Token).safeTransferFrom(msg.sender, address(this), erc1155TokenId, erc1155TokenAmount, "0x00");
      if (depositERC1155s[tokenId][erc1155Token].length == 0) {
        tokenERC1155s[tokenId].push(erc1155Token);
      }
      depositERC1155s[tokenId][erc1155Token].push(TkERC1155(erc1155TokenId, erc1155TokenAmount));
    }
  }

  function viewETH(uint256 tokenId) public view virtual returns (uint256 amount) {
    amount = deposits[tokenId];
  }

  function viewERC20s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC20s[tokenId];
  }

  function viewERC20Amount(uint256 tokenId, address token) public view virtual returns (uint256 amount) {
    amount = depositERC20s[tokenId][token];
  }

  function viewERC721s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC721s[tokenId];
  }

  function viewERC721Ids(uint256 tokenId, address token) public view virtual returns (uint256[] memory amount) {
    amount = depositERC721s[tokenId][token];
  }

  function viewERC1155s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC1155s[tokenId];
  }

  function viewERC1155Ids(uint256 tokenId, address token) public view virtual returns (TkERC1155[] memory amount) {
    amount = depositERC1155s[tokenId][token];
  }

  function _claimDeposits(uint256 tokenId) internal returns (uint256 newUnlock) {
    if (deposits[tokenId] > 0) {
      payable(msg.sender).transfer(deposits[tokenId]);
      newUnlock = deposits[tokenId];
      delete deposits[tokenId];
    }

    if (tokenERC20s[tokenId].length > 0) {
      mapping(address => uint256) storage tokenDeposits = depositERC20s[tokenId];
      for (uint256 i = 0; i < tokenERC20s[tokenId].length; i++) {
        IERC20(tokenERC20s[tokenId][i]).transfer(msg.sender, tokenDeposits[tokenERC20s[tokenId][i]]);
        delete depositERC20s[tokenId][tokenERC20s[tokenId][i]];
      }
      delete tokenERC20s[tokenId];
    }

    if (tokenERC721s[tokenId].length > 0) {
      mapping(address => uint256[]) storage tokenDeposits = depositERC721s[tokenId];
      for (uint256 i = 0; i < tokenERC721s[tokenId].length; i++) {
        for (uint256 j = 0; j < tokenDeposits[tokenERC721s[tokenId][i]].length; j++) {
          IERC721(tokenERC721s[tokenId][i]).transferFrom(
            address(this),
            msg.sender,
            tokenDeposits[tokenERC721s[tokenId][i]][j]
          );
        }
        delete depositERC721s[tokenId][tokenERC721s[tokenId][i]];
      }
      delete tokenERC721s[tokenId];
    }

    if (tokenERC1155s[tokenId].length > 0) {
      for (uint256 i = 0; i < tokenERC1155s[tokenId].length; i++) {
        for (uint256 j = 0; j < depositERC1155s[tokenId][tokenERC1155s[tokenId][i]].length; j++) {
          IERC1155(tokenERC1155s[tokenId][i]).safeTransferFrom(
            address(this),
            msg.sender,
            depositERC1155s[tokenId][tokenERC1155s[tokenId][i]][j].tokenId,
            depositERC1155s[tokenId][tokenERC1155s[tokenId][i]][j].amount,
            "0x01"
          );
        }
        delete depositERC1155s[tokenId][tokenERC1155s[tokenId][i]];
      }
      delete tokenERC1155s[tokenId];
    }
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return 0xf23a6e61;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0xf23a6e61;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// contracts/utilities/UTBGiftBox.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../features/StatefulURI.sol";
import "../features/Vault.sol";
import "../features/UtilityBase.sol";

contract UTBGiftBox is StatefulURI, Vault, UtilityBase {
  uint8 public constant STATE_NORMAL = 0;
  uint8 public constant STATE_READY = 1;
  uint8 public constant STATE_SURPRISE = 2;

  constructor(
    address factory,
    string memory baseURI,
    string memory promo
  ) StatefulURI("Utilitybia - Gift Box", "UTBGiftBox", baseURI, 3) Vault() UtilityBase(factory, promo) {}

  function buyItem(uint256 assetId, uint256 amount) public payable returns (uint256) {
    require(msg.value >= price(assetId) * amount, "Fee insufficient");
    (uint256 end, uint256 newLock) = _mintItem(assetId, msg.sender, amount);
    addLock(newLock);
    return end;
  }

  function wrap(uint256 tokenId) public onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_NORMAL) {
    setTokenState(tokenId, STATE_READY);
  }

  function depositERC20(
    uint256 tokenId,
    address[] memory token,
    uint256[] memory amount
  ) public payable virtual override onlyState(tokenId, STATE_NORMAL) {
    if (msg.value > 0) {
      addLock(msg.value);
    }
    Vault.depositERC20(tokenId, token, amount);
  }

  function depositERC20AndWrap(
    uint256 tokenId,
    address[] memory token,
    uint256[] memory amount
  ) public payable {
    depositERC20(tokenId, token, amount);
    wrap(tokenId);
  }

  function depositERC721(
    uint256 tokenId,
    address[] memory erc721Token,
    uint256[] memory erc721TokenId
  ) public virtual override onlyState(tokenId, STATE_NORMAL) {
    Vault.depositERC721(tokenId, erc721Token, erc721TokenId);
  }

  function depositERC721AndWrap(
    uint256 tokenId,
    address[] memory erc721Token,
    uint256[] memory erc721TokenId
  ) public {
    depositERC721(tokenId, erc721Token, erc721TokenId);
    wrap(tokenId);
  }

  function depositERC1155(
    uint256 tokenId,
    address[] memory erc1155Token,
    uint256[] memory erc1155TokenId,
    uint256[] memory erc1155TokenAmount
  ) public virtual override onlyState(tokenId, STATE_NORMAL) {
    Vault.depositERC1155(tokenId, erc1155Token, erc1155TokenId, erc1155TokenAmount);
  }

  function depositERC1155AndWrap(
    uint256 tokenId,
    address[] memory erc1155Token,
    uint256[] memory erc1155TokenId,
    uint256[] memory erc1155TokenAmount
  ) public {
    depositERC1155(tokenId, erc1155Token, erc1155TokenId, erc1155TokenAmount);
    wrap(tokenId);
  }

  function viewETH(uint256 tokenId) public view virtual override returns (uint256 amount) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      amount = Vault.viewETH(tokenId);
    } else {
      amount = 0;
    }
  }

  function viewERC20s(uint256 tokenId) public view virtual override returns (address[] memory tokens) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      tokens = Vault.viewERC20s(tokenId);
    }
  }

  function viewERC20Amount(uint256 tokenId, address token) public view virtual override returns (uint256 amount) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      amount = Vault.viewERC20Amount(tokenId, token);
    }
  }

  function viewERC721s(uint256 tokenId) public view virtual override returns (address[] memory tokens) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      tokens = Vault.viewERC721s(tokenId);
    }
  }

  function viewERC721Ids(uint256 tokenId, address token)
    public
    view
    virtual
    override
    returns (uint256[] memory amount)
  {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      amount = Vault.viewERC721Ids(tokenId, token);
    }
  }

  function viewERC1155s(uint256 tokenId) public view virtual override returns (address[] memory tokens) {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      tokens = Vault.viewERC1155s(tokenId);
    }
  }

  function viewERC1155Ids(uint256 tokenId, address token)
    public
    view
    virtual
    override
    returns (TkERC1155[] memory amount)
  {
    if (tokenState(tokenId) == uint8(STATE_SURPRISE)) {
      amount = Vault.viewERC1155Ids(tokenId, token);
    }
  }

  function open(uint256 tokenId) external onlyNFTOwner(tokenId, msg.sender) onlyState(tokenId, STATE_READY) {
    setTokenState(tokenId, uint8(STATE_SURPRISE));
  }

  function claimDeposits(uint256 tokenId)
    external
    onlyNFTOwner(tokenId, msg.sender)
    onlyState(tokenId, STATE_SURPRISE)
  {
    uint256 newUnlock = _claimDeposits(tokenId);
    removeLock(newUnlock);
    renewState(tokenId);
  }

  function claimRewards(uint256[] calldata assetIds) external {
    uint256 total = _claimRewards(assetIds);
    removeLock(total);
  }
}

// contracts/utilities/PortableURI.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AssetStore.sol";
import "./ERC721Batch.sol";

contract PortableURI is ERC721Batch, AssetStore {
  event Ported(uint256 tokenId, string porting);

  string public baseURI;

  mapping(uint256 => uint256) public tokenAssets;
  mapping(uint256 => string) private tokenPortings;

  constructor(
    string memory name,
    string memory symbol,
    string memory baseURI_
  ) ERC721(name, symbol) AssetStore(1) {
    baseURI = baseURI_;
  }

  function tokenAsset(uint256 tokenId) internal view returns (Asset memory asset) {
    asset = assets[tokenAssets[tokenId]];
  }

  function _mintItem(
    uint256 index,
    address to,
    uint256 amount
  ) internal returns (uint256, uint256) {
    uint256 newLock = AssetStore.useAsset(index, amount);
    (uint256 start, uint256 end) = increments(amount);
    for (; start <= end; start++) {
      _mint(to, start);
      tokenAssets[start] = index;
    }
    return (end, newLock);
  }

  function setPorting(uint256 tokenId, string calldata porting) internal {
    tokenPortings[tokenId] = porting;
    emit Ported(tokenId, porting);
  }

  function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    if (bytes(tokenPortings[tokenId]).length > 0) {
      return string(abi.encodePacked(baseURI, tokenPortings[tokenId]));
    } else {
      return string(abi.encodePacked(baseURI, tokenAsset(tokenId).asset[0]));
    }
  }

  modifier onlyNFTOwner(uint256 tokenId, address owner) {
    require(ownerOf(tokenId) == owner, "Permission denied");
    _;
  }
}

// contracts/utilities/UTBPhotoFrame.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../features/PortableURI.sol";
import "../features/UtilityBase.sol";

contract UTBPhotoFrame is PortableURI, UtilityBase {
  uint16 public constant PORTING_PERCENT = 1000;

  constructor(
    address factory,
    string memory baseURI,
    string memory promo
  ) PortableURI("Utilitybia - Photo Frame", "UTBPhotoFrame", baseURI) UtilityBase(factory, promo) {}

  function buyItem(uint256 assetId, uint256 amount) public payable returns (uint256) {
    require(msg.value >= price(assetId) * amount, "Fee insufficient");
    (uint256 end, uint256 newLock) = _mintItem(assetId, msg.sender, amount);
    addLock(newLock);
    return end;
  }

  function port(uint256 tokenId, string calldata porting) external payable onlyNFTOwner(tokenId, msg.sender) {
    require(msg.value >= (price(tokenAssets[tokenId]) * PORTING_PERCENT) / 10000, "Fee insufficient");
    setPorting(tokenId, porting);
  }

  function claimRewards(uint256[] calldata assetIds) external {
    uint256 total = _claimRewards(assetIds);
    removeLock(total);
  }
}

// contracts/utilities/VaultNFT.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract VaultNFT {
  struct TkERC1155 {
    uint256 tokenId;
    uint256 amount;
  }

  mapping(uint256 => address[]) private tokenERC721s;
  mapping(uint256 => mapping(address => uint256[])) private depositERC721s;
  mapping(uint256 => address[]) private tokenERC1155s;
  mapping(uint256 => mapping(address => TkERC1155[])) private depositERC1155s;

  constructor(address _factory) {}

  function depositERC721(
    uint256 tokenId,
    address[] memory erc721Tokens,
    uint256[] memory erc721TokenIds
  ) public virtual {
    for (uint256 i = 0; i < erc721Tokens.length; i++) {
      address erc721Token = erc721Tokens[i];
      uint256 erc721TokenId = erc721TokenIds[i];
      IERC721(erc721Token).transferFrom(msg.sender, address(this), erc721TokenId);
      if (depositERC721s[tokenId][erc721Token].length == 0) {
        tokenERC721s[tokenId].push(erc721Token);
      }
      depositERC721s[tokenId][erc721Token].push(erc721TokenId);
    }
  }

  function depositERC1155(
    uint256 tokenId,
    address[] memory erc1155Tokens,
    uint256[] memory erc1155TokenIds,
    uint256[] memory erc1155TokenAmounts
  ) public virtual {
    for (uint256 i = 0; i < erc1155Tokens.length; i++) {
      address erc1155Token = erc1155Tokens[i];
      uint256 erc1155TokenId = erc1155TokenIds[i];
      uint256 erc1155TokenAmount = erc1155TokenAmounts[i];
      IERC1155(erc1155Token).safeTransferFrom(msg.sender, address(this), erc1155TokenId, erc1155TokenAmount, "0x00");
      if (depositERC1155s[tokenId][erc1155Token].length == 0) {
        tokenERC1155s[tokenId].push(erc1155Token);
      }
      depositERC1155s[tokenId][erc1155Token].push(TkERC1155(erc1155TokenId, erc1155TokenAmount));
    }
  }

  function viewERC721s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC721s[tokenId];
  }

  function viewERC721Ids(uint256 tokenId, address token) public view virtual returns (uint256[] memory amount) {
    amount = depositERC721s[tokenId][token];
  }

  function viewERC1155s(uint256 tokenId) public view virtual returns (address[] memory tokens) {
    tokens = tokenERC1155s[tokenId];
  }

  function viewERC1155Ids(uint256 tokenId, address token) public view virtual returns (TkERC1155[] memory amount) {
    amount = depositERC1155s[tokenId][token];
  }

  function claimDeposits(uint256 tokenId) public virtual {
    if (tokenERC721s[tokenId].length > 0) {
      mapping(address => uint256[]) storage tokenDeposits = depositERC721s[tokenId];
      for (uint256 i = 0; i < tokenERC721s[tokenId].length; i++) {
        for (uint256 j = 0; j < tokenERC721s[tokenId].length; j++) {
          IERC721(tokenERC721s[tokenId][i]).transferFrom(
            address(this),
            msg.sender,
            tokenDeposits[tokenERC721s[tokenId][i]][j]
          );
        }
        delete depositERC721s[tokenId][tokenERC721s[tokenId][i]];
      }
      delete tokenERC721s[tokenId];
    }

    if (tokenERC1155s[tokenId].length > 0) {
      for (uint256 i = 0; i < tokenERC1155s[tokenId].length; i++) {
        for (uint256 j = 0; j < depositERC1155s[tokenId][tokenERC1155s[tokenId][i]].length; j++) {
          IERC1155(tokenERC1155s[tokenId][i]).safeTransferFrom(
            address(this),
            msg.sender,
            depositERC1155s[tokenId][tokenERC1155s[tokenId][i]][j].tokenId,
            depositERC1155s[tokenId][tokenERC1155s[tokenId][i]][j].amount,
            "0x01"
          );
        }
        delete depositERC1155s[tokenId][tokenERC1155s[tokenId][i]];
      }
      delete tokenERC1155s[tokenId];
    }
  }

  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return 0xf23a6e61;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0xf23a6e61;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// contracts/utilities/Utility.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../features/UtilityBase.sol";

abstract contract Utility is ERC721, UtilityBase {
  struct Asset {
    string name;
    string promo;
    string[] asset;
    address author;
    uint256 price;
    uint256 limit;
  }

  constructor(
    address factory,
    string memory baseURI,
    string memory promo
  ) ERC721("Utility Template", "TEMP") UtilityBase(factory, promo) {}

  // AssetStore
  event AssetAdded(uint256 assetId, Asset asset);
  event AssetDiscounted(uint256 assetId, uint256 discount);
  event RewardsClaimed(address artist, uint256 rewards);
  // PortableURI
  event Ported(uint256 tokenId, string porting);
  // StatefulURI
  event StateUpdated(uint256 tokenId, uint8 state);

  function tokenAssets(uint256 tokenId) external view virtual returns (uint256);
}

// contracts/MockERC721.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract MockERC721 is ERC721 {
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIds;

	constructor() ERC721("MockERC721", "MCK721") {}

	function mint() public returns (uint256) {
		_tokenIds.increment();

		uint256 newItemId = _tokenIds.current();
		_mint(msg.sender, newItemId);

		return newItemId;
	}

	function mintTo(address to) public returns (uint256) {
		_tokenIds.increment();

		uint256 newItemId = _tokenIds.current();
		_mint(to, newItemId);

		return newItemId;
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Counters.sol)

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

// contracts/MockERC1155.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract MockERC1155 is ERC1155 {
	constructor() ERC1155("https://mock-erc-1155/") {}

	function mint(uint256 tokenId, uint256 amount) public {
		_mint(msg.sender, tokenId, amount, "");
	}

	function mintTo(
		uint256 tokenId,
		uint256 amount,
		address to
	) public {
		_mint(to, tokenId, amount, "");
	}
}

// contracts/MockERC20.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
	constructor() ERC20("MockERC20", "MCK20") {
		_mint(msg.sender, 1000000 * 10**18);
	}
}