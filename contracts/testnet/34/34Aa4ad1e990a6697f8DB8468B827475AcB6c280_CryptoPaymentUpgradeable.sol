// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized != type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ContextUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import { ClaimFeeUpgradeable } from "./internal-upgradeable/ClaimFeeUpgradeable.sol";
import { FeeCollectorUpgradeable } from "./internal-upgradeable/FeeCollectorUpgradeable.sol";
import { PaymentUpgradeable } from "./internal-upgradeable/PaymentUpgradeable.sol";

import { IAccessControlUpgradeable } from "./interfaces/IAccessControlUpgradeable.sol";
import { IERC20Upgradeable } from "./interfaces/IERC20Upgradeable.sol";
import { ICryptoPaymentUpgradeable } from "./interfaces/ICryptoPaymentUpgradeable.sol";
import { ICryptoPaymentFactoryUpgradeable } from "./interfaces/ICryptoPaymentFactoryUpgradeable.sol";

import { Types } from "./libraries/Types.sol";
import { HUNDER_PERCENT, OPERATOR_ROLE, SERVER_ROLE } from "./libraries/Constants.sol";

contract CryptoPaymentUpgradeable is
    ICryptoPaymentUpgradeable,
    Initializable,
    ContextUpgradeable,
    ClaimFeeUpgradeable,
    FeeCollectorUpgradeable,
    PaymentUpgradeable
{
    bytes32 private constant TRANSFER_SELECTOR = 0xa9059cbb00000000000000000000000000000000000000000000000000000000;
    bytes32 private constant BALANCEOF_SELECTOR = 0x70a0823100000000000000000000000000000000000000000000000000000000;

    address public factory;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    modifier onlyFactoryRole(bytes32 role) {
        if (!_checkFactoryRole(role)) revert NotAuthorized();
        _;
    }

    function initialize(
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata adminInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_
    ) external initializer {
        factory = _msgSender();
        __Payment_init(paymentInfo_);
        __FeeCollector_init(adminInfo_, clientInfo_, agentInfo_);
    }

    function distribute() external override onlyFactoryRole(OPERATOR_ROLE) {
        (address[] memory recipients, uint256[] memory fees) = viewFees();
        uint256 length = recipients.length;
        address payment = paymentInfo.token;

        assembly {
            let contractAddress := address()
            let callResult
            let mptr := mload(0x40)
            mstore(mptr, BALANCEOF_SELECTOR)
            mstore(add(mptr, 0x04), contractAddress)

            callResult := staticcall(gas(), calldataload(payment), mptr, 0x24, 0x00, 0x20)

            if iszero(callResult) {
                revert(0, 0)
            }

            let total := mload(0x00)

            for {
                let recipientSlot := add(recipients, 0x20)
                let feeSlot := add(fees, 0x20)
                let end := add(recipientSlot, shl(5, length))
            } lt(recipientSlot, end) {
                recipientSlot := add(recipientSlot, 0x20)
                feeSlot := add(feeSlot, 0x20)
            } {
                if gt(total, 0) {
                    mptr := mload(0x40)
                    mstore(mptr, TRANSFER_SELECTOR)
                    mstore(add(mptr, 0x04), mload(recipientSlot))
                    mstore(add(mptr, 0x24), div(mul(total, mload(feeSlot)), HUNDER_PERCENT))

                    callResult := and(
                        or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                        call(gas(), calldataload(payment), 0, mptr, 0x44, 0, 0x20)
                    )

                    if iszero(callResult) {
                        revert(0, 0)
                    }
                }
            }
        }

        emit Distribute();
    }

    function claimFees(
        uint256 uid_,
        address[] calldata accounts_
    ) external override onlyFactoryRole(SERVER_ROLE) returns (uint256[] memory success) {
        Types.PaymentInfo memory paymentInfo_ = paymentInfo;
        return _claimFees(uid_, paymentInfo_, address(this), accounts_);
    }

    function config(
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_
    ) external onlyFactoryRole(OPERATOR_ROLE) {
        Types.FeeInfo memory adminInfo = Types.FeeInfo(
            ICryptoPaymentFactoryUpgradeable(factory).admin(),
            HUNDER_PERCENT - clientInfo_.percentage - agentInfo_.percentage
        );

        _setPayment(paymentInfo_);
        _configFees(adminInfo, clientInfo_, agentInfo_);
    }

    function _checkFactoryRole(bytes32 role) internal view returns (bool) {
        address sender = _msgSender();
        // direct call
        if (IAccessControlUpgradeable(factory).hasRole(role, sender)) return true;

        // forward call
        if (sender == factory && IAccessControlUpgradeable(factory).hasRole(role, tx.origin)) return true;
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity 0.8.19;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;
import { Types } from "../libraries/Types.sol";
import { ICryptoPaymentUpgradeable } from "./ICryptoPaymentUpgradeable.sol";

interface ICryptoPaymentFactoryUpgradeable {
    error Factory__ExecutionFailed();
    error Factory__NotAuthorized();
    error Factory__AlreadyCharged();

    function admin() external view returns (address);

    function changeAdmin(address newAdmin_) external;

    function createContract(
        bytes32 salt_,
        Types.PaymentInfo calldata paymentInfo_,
        Types.FeeInfo calldata agentInfo,
        Types.FeeInfo calldata clientInfo
    ) external;

    function claimFees(uint256 uid_, address[] calldata accounts_) external returns (uint256[] memory success);

    function distribute(ICryptoPaymentUpgradeable[] calldata instances_) external;

    function setPayment(Types.PaymentInfo calldata payment_) external;

    function setImplement(address implement_) external;

    event NewInstance(address indexed clone);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface ICryptoPaymentUpgradeable {
    error NotAuthorized();

    event Distribute();

    function distribute() external;

    function claimFees(uint256 uid_, address[] calldata accounts_) external returns (uint256[] memory success);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

interface IERC20Upgradeable {
    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
import { Types } from "../libraries/Types.sol";

pragma solidity 0.8.19;

interface IFeeCollector {
    error LengthMisMatch();
    error InvalidRecipient();

    event FeeUpdated();

    function viewFees() external view returns (address[] memory recipients, uint256[] memory percentages);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { IERC20Upgradeable } from "../interfaces/IERC20Upgradeable.sol";
import { UniqueCheckingUpgradeable } from "./UniqueCheckingUpgradeable.sol";
import { Types } from "../libraries/Types.sol";

abstract contract ClaimFeeUpgradeable is UniqueCheckingUpgradeable {
    event Claimed(address indexed sender, uint256[] success);

    function _claimFees(
        uint256 uid_,
        Types.PaymentInfo memory paymentInfo_,
        address recipient_,
        address[] calldata accounts_
    ) internal returns (uint256[] memory success) {
        _setUsed(uid_);

        uint256 length = accounts_.length;
        success = new uint256[](length);

        bytes memory callData = abi.encodeCall(
            IERC20Upgradeable.transferFrom,
            (address(0), recipient_, paymentInfo_.amount)
        );

        address payment = paymentInfo_.token;
        bool ok;
        address account;
        for (uint256 i; i < length; ) {
            account = accounts_[i];

            assembly {
                mstore(add(callData, 0x24), account)
            }

            (ok, ) = payment.call(callData);

            success[i] = ok ? 2 : 1;

            unchecked {
                ++i;
            }
        }

        emit Claimed(msg.sender, success);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Types } from "../libraries/Types.sol";
import { IFeeCollector } from "../interfaces/IFeeCollector.sol";

// Fixed position => do not use Enumrable
contract FeeCollectorUpgradeable is IFeeCollector, Initializable {
    Types.FeeInfo[] private _feeInfos;

    function __FeeCollector_init(
        Types.FeeInfo calldata adminInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_
    ) internal onlyInitializing {
        __FeeCollector_init_unchained(adminInfo_, clientInfo_, agentInfo_);
    }

    function __FeeCollector_init_unchained(
        Types.FeeInfo calldata adminInfo_,
        Types.FeeInfo calldata clientInfo_,
        Types.FeeInfo calldata agentInfo_
    ) internal onlyInitializing {
        _addFee(adminInfo_);
        _addFee(clientInfo_);
        _addFee(agentInfo_);
    }

    function _addFee(Types.FeeInfo calldata feeInfo_) internal {
        if (feeInfo_.recipient != address(0)) _feeInfos.push(feeInfo_);
    }

    function _updateFee(uint256 index_, Types.FeeInfo memory feeInfo_) internal {
        if (feeInfo_.recipient == address(0)) revert InvalidRecipient();
        _feeInfos[index_] = feeInfo_;
    }

    function _configFees(
        Types.FeeInfo memory adminInfo_,
        Types.FeeInfo memory clientInfo_,
        Types.FeeInfo memory agentInfo_
    ) internal {
        _updateFee(0, adminInfo_);
        _updateFee(1, clientInfo_);
        _updateFee(2, agentInfo_);
        emit FeeUpdated();
    }

    function viewFees() public view returns (address[] memory recipients, uint256[] memory percentages) {
        uint256 length = _feeInfos.length;

        recipients = new address[](length);
        percentages = new uint256[](length);

        for (uint256 i = 0; i < length; ) {
            recipients[i] = _feeInfos[i].recipient;
            percentages[i] = (_feeInfos[i].percentage);
            unchecked {
                ++i;
            }
        }
        return (recipients, percentages);
    }

    uint256[9] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Types } from "../libraries/Types.sol";

abstract contract PaymentUpgradeable is Initializable {
    Types.PaymentInfo public paymentInfo;

    function __Payment_init(Types.PaymentInfo calldata payment_) internal onlyInitializing {
        __Payment_init_unchained(payment_);
    }

    function __Payment_init_unchained(Types.PaymentInfo calldata payment_) internal onlyInitializing {
        _setPayment(payment_);
    }

    function _setPayment(Types.PaymentInfo calldata payment_) internal {
        paymentInfo = payment_;
    }

    uint256[19] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import { BitMaps } from "../libraries/BitMaps.sol";

error AlreadyUsed();

abstract contract UniqueCheckingUpgradeable {
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _isUsed;

    function _setUsed(uint256 uid_) internal {
        if (_isUsed.get(uid_)) revert AlreadyUsed();
        _isUsed.set(uid_);
    }

    function isUsed(uint256 uid_) external view returns (bool) {
        return _isUsed.get(uid_);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) map;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool isSet) {
        uint256 value = bitmap.map[index >> 8] & (1 << (index & 0xff));

        assembly {
            isSet := value // Assign isSet to whether the value is non zero.
        }
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(BitMap storage bitmap, uint256 index, bool shouldSet) internal {
        uint256 value = bitmap.map[index >> 8];

        assembly {
            // The following sets the bit at `shift` without branching.
            let shift := and(index, 0xff)
            // Isolate the bit at `shift`.
            let x := and(shr(shift, value), 1)
            // Xor it with `shouldSet`. Results in 1 if both are different, else 0.
            x := xor(x, shouldSet)
            // Shifts the bit back. Then, xor with value.
            // Only the bit at `shift` will be flipped if they differ.
            // Every other bit will stay the same, as they are xor'ed with zeroes.
            value := xor(value, shl(shift, x))
        }
        bitmap.map[index >> 8] = value;
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] |= (1 << (index & 0xff));
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        bitmap.map[index >> 8] &= ~(1 << (index & 0xff));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

uint96 constant HUNDER_PERCENT = 10_000;
bytes32 constant SERVER_ROLE = 0xa8a7bc421f721cb936ea99efdad79237e6ee0b871a2a08cf648691f9584cdc77;
bytes32 constant OPERATOR_ROLE = 0x97667070c54ef182b0f5858b034beac1b6f3089aa2d3188bb1e8929f4fa9b929;
bytes32 constant UPGRADER_ROLE = 0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3;

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Types {
    struct CloneInfo {
        address instance;
        address creator;
    }

    struct FeeInfo {
        address recipient;
        uint96 percentage;
    }

    struct PaymentInfo {
        address token;
        uint96 amount;
    }
}