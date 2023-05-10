// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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
pragma solidity 0.8.19;

/**
@title ISubscriptionManager
@dev The interface for the SubscriptionManager contract.
*/

interface ISubscriptionManager {
    error SubscriptionManager__InsufficientAmount();
    /**
    @dev Error emitted when an invalid argument is provided.
    */
    error SubscriptionManager__InvalidArgument();
    /**
    @dev Error emitted when the caller is not authorized to perform the action.
    @param caller The address of the unauthorized caller.
    */
    error SubscriptionManager__Unauthorized(address caller);

    struct FeeInfo {
        address recipient;
        uint96 amount;
    }

    struct Bonus {
        address recipient;
        uint256 bonus;
    }

    struct Claim {
        address from;
        uint256 discountPercentage;
    }

    event Distributed(
        address indexed operator,
        uint256[] success,
        bytes[] results
    );

    event NewPayment(
        address indexed operator,
        address indexed from,
        address indexed to
    );

    event Claimed(address indexed operator, uint256[] success, bytes[] results);

    event NewFeeInfo(
        address indexed operator,
        FeeInfo indexed oldFeeInfo,
        FeeInfo indexed newFeeInfo
    );

    function setPayment(address payment_) external;

    function setFeeInfo(address recipient_, uint96 amount_) external;

    function distributeBonuses(
        Bonus[] calldata bonuses_
    ) external returns (uint256[] memory success, bytes[] memory results);

    function claimFees(
        address[] calldata accounts_
    ) external returns (uint256[] memory success, bytes[] memory results);

    function claimFees(
        Claim[] calldata claims_
    ) external returns (uint256[] memory success, bytes[] memory results);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    ContextUpgradeable
} from "oz-custom/contracts/oz-upgradeable/utils/ContextUpgradeable.sol";

import {
    IFundRecoverableUpgradeable
} from "./interfaces/IFundRecoverableUpgradeable.sol";

import {ErrorHandler} from "oz-custom/contracts/libraries/ErrorHandler.sol";

abstract contract FundRecoverableUpgradeable is
    ContextUpgradeable,
    IFundRecoverableUpgradeable
{
    using ErrorHandler for bool;

    function recover(
        RecoverCallData[] calldata calldata_,
        bytes calldata data_
    ) external virtual {
        _beforeRecover(data_);
        _recover(calldata_);
    }

    function _beforeRecover(bytes memory) internal virtual;

    function _recover(RecoverCallData[] calldata calldata_) internal virtual {
        uint256 length = calldata_.length;
        bytes[] memory results = new bytes[](length);

        bool success;
        bytes memory returnOrRevertData;
        for (uint256 i; i < length; ) {
            (success, returnOrRevertData) = calldata_[i].target.call{
                value: calldata_[i].value
            }(calldata_[i].callData);

            success.handleRevertIfNotSuccess(returnOrRevertData);

            results[i] = returnOrRevertData;

            unchecked {
                ++i;
            }
        }

        emit Executed(_msgSender(), results);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IFundRecoverableUpgradeable {
    struct RecoverCallData {
        address target;
        uint256 value;
        bytes callData;
    }

    event Executed(address indexed operator, bytes[] results);

    function recover(
        RecoverCallData[] calldata calldata_,
        bytes calldata data_
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {
    OwnableUpgradeable
} from "oz-custom/contracts/oz-upgradeable/access/OwnableUpgradeable.sol";

import {
    UUPSUpgradeable
} from "oz-custom/contracts/oz-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {
    FundRecoverableUpgradeable
} from "./internal-upgradeable/FundRecoverableUpgradeable.sol";

import {IERC20} from "./utils/permit2/interfaces/IPermit2.sol";
import {ISubscriptionManager} from "./interfaces/ISubscriptionManager.sol";

//* 0xa9059cbb
//* 00000000000000000000000047b0fb7281206373f8672fcafed0c6afc6516b32
//* 0000000000000000000000000000000000000000000000000000000001c9c380

contract SubscriptionManager is
    UUPSUpgradeable,
    OwnableUpgradeable,
    ISubscriptionManager,
    FundRecoverableUpgradeable
{
    FeeInfo public feeInfo;
    address public payment;

    function initialize(
        address payment_,
        uint96 amount_,
        address recipient_
    ) external initializer {
        __Ownable_init_unchained();
        _setPayment(_msgSender(), payment_);
        _setFeeInfo(recipient_, amount_, feeInfo);
    }

    // constructor(
    //     address payment_,
    //     uint96 amount_,
    //     address recipient_
    // ) payable Ownable() {
    //     _setPayment(_msgSender(), payment_);
    //     _setFeeInfo(recipient_, amount_, feeInfo);
    // }

    function setPayment(address payment_) external onlyOwner {
        _setPayment(_msgSender(), payment_);
    }

    function setFeeInfo(address recipient_, uint96 amount_) external {
        FeeInfo memory _feeInfo = feeInfo;
        address sender = _msgSender();
        if (sender != _feeInfo.recipient)
            revert SubscriptionManager__Unauthorized(sender);

        _setFeeInfo(recipient_, amount_, _feeInfo);
    }

    function distributeBonuses(
        Bonus[] calldata bonuses
    )
        public
        onlyOwner
        returns (uint256[] memory success, bytes[] memory results)
    {
        uint256 length = bonuses.length;
        success = new uint256[](length);
        results = new bytes[](length);

        bytes memory callData = abi.encodeCall(
            IERC20.transfer,
            (address(0), 0)
        );
        address _payment = payment;

        bool ok;
        address recipient;
        uint256 bonus;

        for (uint256 i; i < length; ) {
            bonus = bonuses[i].bonus;
            recipient = bonuses[i].recipient;
            assembly {
                mstore(add(callData, 0x24), recipient)
                mstore(add(callData, 0x44), bonus)
            }

            (ok, results[i]) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        // IERC20(_payment).transfer(
        //     feeInfo.recipient,
        //     IERC20(_payment).balanceOf(address(this))
        // );

        emit Distributed(_msgSender(), success, results);
    }

    function claimFees(
        address[] calldata accounts_
    )
        public
        onlyOwner
        returns (uint256[] memory success, bytes[] memory results)
    {
        uint256 length = accounts_.length;
        results = new bytes[](length);
        success = new uint256[](length);

        FeeInfo memory _feeInfo = feeInfo;

        bytes memory callData = abi.encodeCall(
            IERC20.transferFrom,
            (address(0), address(this), _feeInfo.amount)
        );

        address _payment = payment;
        bool ok;
        address account;
        for (uint256 i; i < length; ) {
            account = accounts_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, results[i]) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Claimed(_msgSender(), success, results);
    }

    function claimFees(
        Claim[] calldata claims_
    )
        external
        onlyOwner
        returns (uint256[] memory success, bytes[] memory results)
    {
        uint256 length = claims_.length;
        results = new bytes[](length);
        success = new uint256[](length);

        FeeInfo memory _feeInfo = feeInfo;

        bytes memory callData = abi.encodeCall(
            IERC20.transferFrom,
            (address(0), address(this), 0)
        );

        address _payment = payment;
        bool ok;
        address account;
        uint256 percent;
        uint256 fee;
        for (uint256 i; i < length; ) {
            account = claims_[i].from;
            percent = claims_[i].discountPercentage;
            fee = _feeInfo.amount - ((_feeInfo.amount * percent) / 10_000);
            assembly {
                mstore(add(callData, 0x24), account)
                mstore(add(callData, 0x64), fee)
            }

            (ok, results[i]) = _payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Claimed(_msgSender(), success, results);
    }

    function withdraw(uint256 amount_) public {
        FeeInfo memory _feeInfo = feeInfo;
        address sender = _msgSender();
        address _payment = payment;

        if (sender != _feeInfo.recipient)
            revert SubscriptionManager__Unauthorized(sender);

        if (amount_ > IERC20(_payment).balanceOf(address(this)))
            revert SubscriptionManager__InsufficientAmount();

        IERC20(_payment).transfer(_feeInfo.recipient, amount_);
    }

    function _setPayment(address sender_, address payment_) internal {
        emit NewPayment(sender_, payment, payment_);
        payment = payment_;
    }

    function _setFeeInfo(
        address recipient_,
        uint96 amount_,
        FeeInfo memory currentFeeInfo_
    ) internal {
        if (recipient_ == address(0))
            revert SubscriptionManager__InvalidArgument();

        FeeInfo memory _feeInfo = FeeInfo(recipient_, amount_);
        emit NewFeeInfo(_msgSender(), currentFeeInfo_, _feeInfo);

        feeInfo = _feeInfo;
    }

    function _beforeRecover(bytes memory) internal view override {
        _checkOwner(_msgSender());
    }

    function _authorizeUpgrade(
        address newImplementation
    ) internal virtual override {}
    
    uint256[48] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IPermit2 {
    /// @notice The permit data for a token
    struct PermitDetails {
        // ERC20 token address
        address token;
        // the maximum amount allowed to spend
        uint160 amount;
        // timestamp at which a spender's token allowances become invalid
        uint48 expiration;
        // an incrementing value indexed per owner,token,and spender for each signature
        uint48 nonce;
    }

    /// @notice The permit message signed for a single token allownce
    struct PermitSingle {
        // the permit data for a single token alownce
        PermitDetails details;
        // address permissioned on the allowed tokens
        address spender;
        // deadline on the permit signature
        uint256 sigDeadline;
    }
    // Token and amount in a permit message.
    struct TokenPermissions {
        // Token to transfer.
        IERC20 token;
        // Amount to transfer.
        uint256 amount;
    }

    // The permit2 message.
    struct PermitTransferFrom {
        // Permitted token and amount.
        TokenPermissions permitted;
        // Unique identifier for this permit.
        uint256 nonce;
        // Expiration for this permit.
        uint256 deadline;
    }

    // Transfer details for permitTransferFrom().
    struct SignatureTransferDetails {
        // Recipient of tokens.
        address to;
        // Amount to transfer.
        uint256 requestedAmount;
    }

    // Consume a permit2 message and transfer tokens.
    function permitTransferFrom(
        PermitTransferFrom calldata permit,
        SignatureTransferDetails calldata transferDetails,
        address owner,
        bytes calldata signature
    ) external;

    /// @notice A mapping from owner address to token address to spender address to PackedAllowance struct, which contains details and conditions of the approval.
    /// @notice The mapping is indexed in the above order see: allowance[ownerAddress][tokenAddress][spenderAddress]
    /// @dev The packed slot holds the allowed amount, expiration at which the allowed amount is no longer valid, and current nonce thats updated on any signature based approvals.
    function allowance(
        address,
        address,
        address
    ) external view returns (uint160, uint48, uint48);

    // @notice Transfer approved tokens from one address to another
    /// @param from The address to transfer from
    /// @param to The address of the recipient
    /// @param amount The amount of the token to transfer
    /// @param token The token address to transfer
    /// @dev Requires the from address to have approved at least the desired amount
    /// of tokens to msg.sender.
    function transferFrom(
        address from,
        address to,
        uint160 amount,
        address token
    ) external;

    // @notice Permit a spender to a given amount of the owners token via the owner's EIP-712 signature
    /// @dev May fail if the owner's nonce was invalidated in-flight by invalidateNonce
    /// @param owner The owner of the tokens being approved
    /// @param permitSingle Data signed over by the owner specifying the terms of approval
    /// @param signature The owner's signature over the permit data
    function permit(
        address owner,
        PermitSingle memory permitSingle,
        bytes calldata signature
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library Bytes32Address {
    function fromFirst20Bytes(
        bytes32 bytesValue
    ) internal pure returns (address addr) {
        assembly {
            addr := bytesValue
        }
    }

    function fillLast12Bytes(
        address addressValue
    ) internal pure returns (bytes32 value) {
        assembly {
            value := addressValue
        }
    }

    function fromFirst160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := uintValue
        }
    }

    function fillLast96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := addressValue
        }
    }

    function fromLast160Bits(
        uint256 uintValue
    ) internal pure returns (address addr) {
        assembly {
            addr := shr(0x60, uintValue)
        }
    }

    function fillFirst96Bits(
        address addressValue
    ) internal pure returns (uint256 value) {
        assembly {
            value := shl(0x60, addressValue)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

error ErrorHandler__ExecutionFailed();

library ErrorHandler {
    function handleRevertIfNotSuccess(
        bool ok_,
        bytes memory revertData_
    ) internal pure {
        assembly {
            if iszero(ok_) {
                let revertLength := mload(revertData_)
                if iszero(iszero(revertLength)) {
                    // Start of revert data bytes. The 0x20 offset is always the same.
                    revert(add(revertData_, 0x20), revertLength)
                }

                //  revert ErrorHandler__ExecutionFailed()
                mstore(0x00, 0xa94eec76)
                revert(0x1c, 0x04)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import {ContextUpgradeable} from "../utils/ContextUpgradeable.sol";

import {Bytes32Address} from "../../libraries/Bytes32Address.sol";

interface IOwnableUpgradeable {
    error Ownable__Unauthorized();
    error Ownable__NonZeroAddress();

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function renounceOwnership() external;

    function transferOwnership(address newOwner) external;

    function owner() external view returns (address _owner);
}

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
abstract contract OwnableUpgradeable is
    IOwnableUpgradeable,
    ContextUpgradeable
{
    using Bytes32Address for *;

    bytes32 private __owner;

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
        _checkOwner(_msgSender());
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return __owner.fromFirst20Bytes();
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner(address sender_) internal view virtual {
        if (__owner != sender_.fillLast12Bytes())
            revert Ownable__Unauthorized();
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
        if (newOwner == address(0)) revert Ownable__Unauthorized();
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        emit OwnershipTransferred(__owner.fromFirst20Bytes(), newOwner);
        __owner = newOwner.fillLast12Bytes();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import {Initializable} from "../utils/Initializable.sol";

import {IBeaconUpgradeable} from "../beacon/IBeaconUpgradeable.sol";
import {
    IERC1822ProxiableUpgradeable
} from "../../interfaces/draft-IERC1822Upgradeable.sol";

import {StorageSlotUpgradeable} from "../../utils/StorageSlotUpgradeable.sol";

error ERC1967UpgradeUpgradeable__NonZeroAddress();
error ERC1967UpgradeUpgradeable__ExecutionFailed();
error ERC1967UpgradeUpgradeable__TargetIsNotContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
error ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
error ERC1967UpgradeUpgradeable__DelegateCallToNonContract();
error ERC1967UpgradeUpgradeable__ImplementationIsNotContract();

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant __ROLLBACK_SLOT =
        0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT =
        0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return
            StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        if (!_isContract(newImplementation))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable
            .getAddressSlot(_IMPLEMENTATION_SLOT)
            .value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (forceCall || data.length > 0) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(__ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try
                IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID()
            returns (bytes32 slot) {
                if (slot != _IMPLEMENTATION_SLOT)
                    revert ERC1967UpgradeUpgradeable__UnsupportedProxiableUUID();
            } catch {
                revert ERC1967UpgradeUpgradeable__ImplementationIsNotUUPS();
            }

            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT =
        0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        if (newAdmin == address(0))
            revert ERC1967UpgradeUpgradeable__NonZeroAddress();
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT =
        0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        if (!_isContract(newBeacon))
            revert ERC1967UpgradeUpgradeable__TargetIsNotContract();
        if (!_isContract(IBeaconUpgradeable(newBeacon).implementation()))
            revert ERC1967UpgradeUpgradeable__ImplementationIsNotContract();
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes calldata data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (forceCall || data.length > 0) {
            _functionDelegateCall(
                IBeaconUpgradeable(newBeacon).implementation(),
                data
            );
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(
        address target,
        bytes memory data
    ) private returns (bytes memory) {
        if (!_isContract(target))
            revert ERC1967UpgradeUpgradeable__DelegateCallToNonContract();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata);
    }

    function _isContract(address addr_) internal view returns (bool) {
        return addr_.code.length != 0;
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata
    ) internal pure returns (bytes memory) {
        if (success) return returndata;
        else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    revert(add(32, returndata), mload(returndata))
                }
            } else revert ERC1967UpgradeUpgradeable__ExecutionFailed();
        }
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

error Initializable__Initializing();
error Initializable__NotInitializing();
error Initializable__AlreadyInitialized();

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
    uint256 private __initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    uint256 private __initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint256 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = __beforeInitialized();
        _;
        __afterInitialized(isTopLevelCall);
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
        __beforeReinitialized(version);
        _;
        __afterReinitialized();
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        __checkInitializing();
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        if (__initializing != 1) revert Initializable__Initializing();
        if (__initialized < 0xff) {
            __initialized = 0xff;
            emit Initialized(0xff);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8 version) {
        assembly {
            version := sload(__initialized.slot)
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return __initializing == 2;
    }

    function __checkInitializing() private view {
        if (__initializing != 2) revert Initializable__NotInitializing();
    }

    function __beforeInitialized() private returns (bool isTopLevelCall) {
        isTopLevelCall = __initializing != 2;
        uint256 initialized = __initialized;

        if (
            !((isTopLevelCall && initialized == 0) ||
                (initialized == 1 && address(this).code.length == 0))
        ) revert Initializable__AlreadyInitialized();

        __initialized = 1;
        if (isTopLevelCall) __initializing = 2;
    }

    function __afterInitialized(bool isTopLevelCall_) private {
        if (isTopLevelCall_) {
            __initializing = 1;
            emit Initialized(1);
        }
    }

    function __beforeReinitialized(uint8 version) private {
        if (__initializing != 1 || __initialized >= version)
            revert Initializable__AlreadyInitialized();
        __initialized = version;
        __initializing = 2;
    }

    function __afterReinitialized() private {
        __initializing = 1;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";
import {
    ERC1967UpgradeUpgradeable
} from "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import {
    IERC1822ProxiableUpgradeable
} from "../../interfaces/draft-IERC1822Upgradeable.sol";

error UUPSUpgradeable__OnlyCall();
error UUPSUpgradeable__OnlyActiveProxy();
error UUPSUpgradeable__OnlyDelegateCall();

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is
    Initializable,
    ERC1967UpgradeUpgradeable,
    IERC1822ProxiableUpgradeable
{
    function __UUPSUpgradeable_init() internal onlyInitializing {}

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {}

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        __checkProxy();
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        __checkDelegated();
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID()
        external
        view
        virtual
        override
        notDelegated
        returns (bytes32)
    {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, "", false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(
        address newImplementation,
        bytes memory data
    ) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    function __checkProxy() private view {
        address self = __self;
        if (address(this) == self) revert UUPSUpgradeable__OnlyDelegateCall();
        if (_getImplementation() != self)
            revert UUPSUpgradeable__OnlyActiveProxy();
    }

    function __checkDelegated() private view {
        if (address(this) != __self) revert UUPSUpgradeable__OnlyCall();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import {Initializable} from "../proxy/utils/Initializable.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(
        bytes32 slot
    ) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(
        bytes32 slot
    ) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(
        bytes32 slot
    ) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(
        bytes32 slot
    ) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}