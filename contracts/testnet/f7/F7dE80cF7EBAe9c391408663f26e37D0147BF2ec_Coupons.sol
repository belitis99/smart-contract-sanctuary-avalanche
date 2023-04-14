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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableMap.sol)

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * The following map types are supported:
 *
 * - `uint256 -> address` (`UintToAddressMap`) since v3.0.0
 * - `address -> uint256` (`AddressToUintMap`) since v4.6.0
 * - `bytes32 -> bytes32` (`Bytes32ToBytes32`) since v4.6.0
 * - `uint256 -> uint256` (`UintToUintMap`) since v4.7.0
 * - `bytes32 -> uint256` (`Bytes32ToUintMap`) since v4.7.0
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableMap, you can either remove all elements one by one or create a fresh instance using an array of EnumerableMap.
 * ====
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Bytes32ToBytes32Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        bytes32 value
    ) internal returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToBytes32Map storage map, bytes32 key) internal returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function length(Bytes32ToBytes32Map storage map) internal view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToBytes32Map storage map, uint256 index) internal view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToBytes32Map storage map, bytes32 key) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function get(
        Bytes32ToBytes32Map storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || contains(map, key), errorMessage);
        return value;
    }

    // UintToUintMap

    struct UintToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToUintMap storage map,
        uint256 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToUintMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToUintMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToUintMap storage map, uint256 index) internal view returns (uint256, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(UintToUintMap storage map, uint256 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToUintMap storage map, uint256 key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key)));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToUintMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(key), errorMessage));
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        UintToAddressMap storage map,
        uint256 key,
        address value
    ) internal returns (bool) {
        return set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        UintToAddressMap storage map,
        uint256 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(get(map._inner, bytes32(key), errorMessage))));
    }

    // AddressToUintMap

    struct AddressToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        AddressToUintMap storage map,
        address key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, bytes32(uint256(uint160(key))), bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(AddressToUintMap storage map, address key) internal returns (bool) {
        return remove(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(AddressToUintMap storage map, address key) internal view returns (bool) {
        return contains(map._inner, bytes32(uint256(uint160(key))));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(AddressToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressToUintMap storage map, uint256 index) internal view returns (address, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (address(uint160(uint256(key))), uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(AddressToUintMap storage map, address key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, bytes32(uint256(uint160(key))));
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(AddressToUintMap storage map, address key) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        AddressToUintMap storage map,
        address key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, bytes32(uint256(uint160(key))), errorMessage));
    }

    // Bytes32ToUintMap

    struct Bytes32ToUintMap {
        Bytes32ToBytes32Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToUintMap storage map,
        bytes32 key,
        uint256 value
    ) internal returns (bool) {
        return set(map._inner, key, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToUintMap storage map, bytes32 key) internal returns (bool) {
        return remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool) {
        return contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToUintMap storage map) internal view returns (uint256) {
        return length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToUintMap storage map, uint256 index) internal view returns (bytes32, uint256) {
        (bytes32 key, bytes32 value) = at(map._inner, index);
        return (key, uint256(value));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function tryGet(Bytes32ToUintMap storage map, bytes32 key) internal view returns (bool, uint256) {
        (bool success, bytes32 value) = tryGet(map._inner, key);
        return (success, uint256(value));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToUintMap storage map, bytes32 key) internal view returns (uint256) {
        return uint256(get(map._inner, key));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToUintMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (uint256) {
        return uint256(get(map._inner, key, errorMessage));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/ICoupons.sol";
//import "hardhat/console.sol";


/* Errors */
error Coupons__CouponNotFound();
error Coupons__PlayerAddressMismatch();
error Coupons__CouponAlreadyUsed();
error Coupons__RuleNotFound();
error Coupons__NotEnoughFunds();
error Coupons__TransferToSafeFailed();
error Coupons__NotForPaidCoupons();
error Coupons__EmptyPriceList();
error Coupons__BadOrderOfRndMinMax();
error Coupons__OutOfMaxRndPctLimit();
error Coupons__StepOutOfRange();
error Coupons__PriceListNotSet();
error Coupons__NotERC20Address();
error Coupons__PriceListTokenNotFound();
error Coupons__MsgValueMustBeZero();
error Coupons__AmountMustBeZero();
error Coupons__ERC20TransferFailed();
error Coupons__ExternalMultiplierNotAllowed();

contract Coupons is ICoupons {
    string private constant VERSION = "0.6.1";

    using EnumerableMap for EnumerableMap.AddressToUintMap;

    address private s_owner;
    address payable private s_safeAddress;
    uint s_nonce;

    // Public coupons table: contractAddress -> coupon
    mapping(address => ICoupons.Coupon[]) private s_coupons;
    // Rules
    // Coupons rule:  contractAddress => couponRule
    mapping(address => ICoupons.CouponRule) private s_couponRule;
    // Coupons price list: contractAddress => enumerable mapping (tokenAddress => price)
    // address(0) token means the network currency
    mapping(address => EnumerableMap.AddressToUintMap) private s_priceList;
    // Paid Coupons store
    // Number of paid coupons: contractAddress -> raffleId -> playerAddress -> number of coupon tickets
    mapping(address => mapping(uint32 => mapping(address => uint16))) private s_nCouponTickets;
    // Paid coupon ticket: contractAddress => raffleId => couponHash => coupon ticket data
    mapping(address => mapping(uint32 => mapping(bytes32 => ICoupons.CouponTicket))) private s_couponTickets;

    event CouponsUpdate(address contractAddress, bytes32 keyHash);
    event CouponPurchase(address tokenAddress, string couponKey, ICoupons.CouponTicket couponTicket, uint nonce);
    event CouponUsed(bytes32 couponHash, address playerAddress, address contractAddress, uint32 raffleId);
    event ContractWithdraw(address contractAddress, uint funds);
    event CouponRuleUpdated(address contractAddress);

    constructor(address payable safe) {
        s_owner = msg.sender;
        s_safeAddress = safe;
        s_nonce = 1;
    }

    /** Public Coupons CRUD **/
    function getCoupon(
        bytes32 couponHash,
        address playerAddress,
        address contractAddress,
        uint32 raffleId
    ) public view override returns (ICoupons.Coupon memory) {
        return _getCoupon(couponHash, playerAddress, contractAddress, raffleId);
    }

    function _getCoupon(
        bytes32 couponHash,
        address playerAddress,
        address contractAddress,
        uint32 raffleId
    ) internal view returns (ICoupons.Coupon memory) {
        ICoupons.CouponTicket memory couponTicket = s_couponTickets[contractAddress][raffleId][couponHash];
        if (couponTicket.playerAddress == address(0)) {
            for (uint i=0; i < s_coupons[contractAddress].length; i++) {
                if (s_coupons[contractAddress][i].couponHash == couponHash) {
                    return (s_coupons[contractAddress][i]);
                }
            }
        } else {
            // validate paid coupon (compare coupon hash and player address)
            if (playerAddress != couponTicket.playerAddress) {
                revert Coupons__PlayerAddressMismatch();
            }
            if (couponTicket.used) {
                revert Coupons__CouponAlreadyUsed();
            } else {
                return ICoupons.Coupon(couponHash, 0, 100, couponTicket.multiplierPct, true);
            }
        }
        revert Coupons__CouponNotFound();
    }

    function setPublicCoupon(address contractAddress, ICoupons.Coupon memory coupon) public onlyOwner {
        if (coupon.isPaid) {
            revert Coupons__NotForPaidCoupons();
        }
        bool found = false;
        uint id = 0;
        if (s_coupons[contractAddress].length > 0) {
            for (uint i=0; i < s_coupons[contractAddress].length; i++) {
                if (s_coupons[contractAddress][i].couponHash == coupon.couponHash) {
                    found = true;
                    id = i;
                    break;
                }
            }
        }
        if (found) {
            s_coupons[contractAddress][id] = coupon;
        } else {
            s_coupons[contractAddress].push(coupon);
        }
        emit CouponsUpdate(contractAddress, coupon.couponHash);
    }

    function deletePublicCoupon(address contractAddress, bytes32 keyHash) public onlyOwner {
        if (s_coupons[contractAddress].length > 0) {
            bool found = false;
            uint id;
            for (uint i = 0; i < s_coupons[contractAddress].length; i++) {
                if (s_coupons[contractAddress][i].couponHash == keyHash) {
                    id = i;
                    found = true;
                    block;
                }
            }
            if (found) {
                for (uint i = id; i < s_coupons[contractAddress].length - 1; i++){
                    s_coupons[contractAddress][i] = s_coupons[contractAddress][i + 1];
                }
                s_coupons[contractAddress].pop();
            }
        }
        emit CouponsUpdate(contractAddress, keyHash);
    }

    function deleteAllPublicCoupons(address contractAddress) public onlyOwner {
        delete s_coupons[contractAddress];
        emit CouponsUpdate(contractAddress, keccak256(abi.encodePacked('')));
    }

    function getPublicCoupons(address contractAddress) public view returns (Coupon[] memory) {
        return s_coupons[contractAddress];
    }
    /** End Public Coupons CRUD **/


    /** Rules & Prices CRUD **/
    function setCouponRule(address contractAddress, ICoupons.CouponRule memory couponRule) external onlyOwner {
        // MinRndPct < MaxRndPct <= 500
        if (couponRule.maxRndPct > 500) {
            revert Coupons__OutOfMaxRndPctLimit();
        }
        if (couponRule.minRndPct >= couponRule.maxRndPct) {
            revert Coupons__BadOrderOfRndMinMax();
        }
        // 0 < step <= max-min
        if (couponRule.step == 0 || couponRule.step > (couponRule.maxRndPct - couponRule.minRndPct)) {
            revert Coupons__StepOutOfRange();
        }
        s_couponRule[contractAddress] = couponRule;
        emit CouponRuleUpdated(contractAddress);
    }

    function deleteCouponRule(address contractAddress) external onlyOwner {
        delete s_couponRule[contractAddress];
    }

    function getTokenPrice(address contractAddress, address tokenAddress) external view returns (uint) {
        if (s_priceList[contractAddress].contains(tokenAddress)) {
            return s_priceList[contractAddress].get(tokenAddress);
        } else {
            revert Coupons__PriceListTokenNotFound();
        }
    }

    function getPriceList(address contractAddress) external view returns(ICoupons.CouponPrice[] memory) {
        ICoupons.CouponPrice[] memory result = new ICoupons.CouponPrice[](s_priceList[contractAddress].length());
        for (uint i; i < s_priceList[contractAddress].length(); i++) {
            (result[i].tokenAddress, result[i].couponFee) = s_priceList[contractAddress].at(i);
        }
        return result;
    }

    function setPriceList(address contractAddress, ICoupons.CouponPrice[] calldata priceList) external onlyOwner {
        for (uint i; i < priceList.length; i++) {
            checkToken(priceList[i].tokenAddress);
            s_priceList[contractAddress].set(priceList[i].tokenAddress, priceList[i].couponFee);
        }
    }

    function deletePriceList(address contractAddress) external onlyOwner {
        delete s_priceList[contractAddress];
    }
    /** End Rules & Prices CRUD **/

    function buyCoupon(
        address contractAddress,
        uint32 raffleId,
        address tokenAddress,
        uint amount,
        uint16 multiplierPct
    ) public payable override {
        // Find contract rule
        ICoupons.CouponRule memory couponRule = s_couponRule[contractAddress];
        if (couponRule.step == 0 && couponRule.maxRndPct == 0) {
            revert Coupons__RuleNotFound();
        }
        // Check price list
        if (s_priceList[contractAddress].length() == 0) {
            revert Coupons__PriceListNotSet();
        }
        if (tokenAddress != address(0) && !s_priceList[contractAddress].contains(tokenAddress)) {
            revert Coupons__PriceListTokenNotFound();
        }
        // Check multiplier percentage
        if (multiplierPct > 0 && !couponRule.allowExtMultiplier) {
            revert Coupons__ExternalMultiplierNotAllowed();
        }
        if (multiplierPct > 0 && (multiplierPct < couponRule.minRndPct || couponRule.maxRndPct < multiplierPct)) {
            revert Coupons__OutOfMaxRndPctLimit();
        }
        // Set coupon Fee
        uint couponFee = s_priceList[contractAddress].get(tokenAddress);
        // Check incoming value
        if (tokenAddress == address(0)) {
            if (amount > 0) { revert Coupons__AmountMustBeZero(); }
            if (msg.value < couponFee) { revert Coupons__NotEnoughFunds(); }
        } else {
            if (msg.value > 0) { revert Coupons__MsgValueMustBeZero(); }
            if (amount < couponFee) { revert Coupons__NotEnoughFunds(); }
        }

        // Try to get ERC20 funds
        if (tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            bool success = token.transferFrom(msg.sender, address(this), amount);
            if (!success) {
                revert Coupons__ERC20TransferFailed();
            }
        }

        s_nCouponTickets[contractAddress][raffleId][msg.sender] += 1;
        uint16 ticketId = s_nCouponTickets[contractAddress][raffleId][msg.sender];
        string memory couponKey = _getPaidCouponKey(msg.sender, contractAddress, raffleId, ticketId);
        bytes32 couponHash = keccak256(abi.encodePacked(couponKey));
        uint16 _multiplierPct;
        if (multiplierPct == 0) {
            _multiplierPct = _getRoundedRandomPct(
                couponRule.minRndPct, couponRule.maxRndPct, couponRule.step, msg.sender, s_nonce
            );
        } else {
            _multiplierPct = multiplierPct;
        }

        ICoupons.CouponTicket memory couponTicket = ICoupons.CouponTicket(
            msg.sender, _multiplierPct, false
        );
        s_couponTickets[contractAddress][raffleId][couponHash] = couponTicket;
        emit CouponPurchase(tokenAddress, couponKey, couponTicket, s_nonce);
        s_nonce += 1;
    }

    function useCoupon(
        bytes32 couponHash,
        address playerAddress,
        uint32 raffleId
    ) public override returns (ICoupons.Coupon memory) {
        address contractAddress = msg.sender;
        ICoupons.Coupon memory coupon = _getCoupon(couponHash, playerAddress, contractAddress, raffleId);
        if (coupon.isPaid) {
            s_couponTickets[contractAddress][raffleId][couponHash].used = true;
        }
        emit CouponUsed(couponHash, playerAddress, contractAddress, raffleId);
        return coupon;
    }

    function withdraw() public onlyOwner {
        withdrawToken(address(0));
    }

    function withdrawToken(address tokenAddress) public onlyOwner {
        checkToken(tokenAddress);
        if (tokenAddress == address(0)) {
            (bool safeTxSuccess, ) = s_safeAddress.call{value: address(this).balance}("");
            if (!safeTxSuccess) {
                revert Coupons__TransferToSafeFailed();
            }
        } else {
            IERC20 token = IERC20(tokenAddress);
            uint balance = token.balanceOf(address(this));
            if (balance > 0) {
                bool success = token.transfer(s_safeAddress, balance);
                if (!success) {
                    revert Coupons__ERC20TransferFailed();
                }
            }
        }
    }

    /** Getters **/
    function getVersion() public pure returns (string memory) {
        return VERSION;
    }

    function getCouponRule(address contractAddress) public view returns (ICoupons.CouponRule memory) {
        return s_couponRule[contractAddress];
    }

    function getCouponTicket(
        address contractAddress,
        uint32 raffleId,
        bytes32 couponHash
    ) external view override returns (ICoupons.CouponTicket memory) {
        return s_couponTickets[contractAddress][raffleId][couponHash];
    }

    function getNumberOfCouponTickets(
        address contractAddress,
        uint32 raffleId,
        address playerAddress
    ) external view returns (uint16) {
        return s_nCouponTickets[contractAddress][raffleId][playerAddress];
    }

    function getSafeAddress() public view returns (address payable) {
        return s_safeAddress;
    }

    /** Setters **/
    function setSafeAddress(address payable safeAddress) external onlyOwner {
        s_safeAddress = safeAddress;
    }

    function changeOwner(address owner) external onlyOwner {
        s_owner = owner;
    }

    /** Modifiers **/
    modifier onlyOwner() {
        require(msg.sender == s_owner, 'Only owner allowed');
        _;
    }

    /** Utils **/
    function _round(uint x, uint y) public pure returns (uint) {
        // Rounding X to nearest multiple of Y
        return ((x + y / 2) / y) * y;
    }

    function _getPseudoRandomPct(uint16 minRndPct, uint16 maxRndPct, address playerAddress, uint nonce) public view
    returns (uint16 randomPct) {
        uint16 rangeLength = maxRndPct - minRndPct + 1;
        uint randomNumber = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty, playerAddress, nonce)));
        randomPct = uint16(randomNumber % rangeLength) + minRndPct;
    }

    function _getRoundedRandomPct(
        uint16 minRndPct,
        uint16 maxRndPct,
        uint16 step,
        address playerAddress,
        uint nonce
    ) public view returns (uint16 roundedRandomPct) {
        uint16 randomPct = _getPseudoRandomPct(minRndPct, maxRndPct, playerAddress, nonce);
        roundedRandomPct = uint16(_round(randomPct, step));
        // console.log('_getRoundedRandomPct: nonce=%s, timestamp=%s, difficulty=%s', nonce, block.timestamp, block.difficulty);
        // console.log('                      randomPct=%s, roundedPct=%s,  playerAddress=%s', randomPct, roundedRandomPct, playerAddress);
    }

    function _toString(bytes memory data, bool with0x) public pure returns (string memory) {
        bytes memory alphabet = "0123456789ABCDEF";
        bytes memory str = new bytes(data.length * 2);
        for (uint i = 0; i < data.length; i++) {
            str[i * 2] = alphabet[uint(uint8(data[i] >> 4))];
            str[1 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        if (with0x) {
            return string(abi.encodePacked('0x', str));
        } else {
            return string(str);
        }
    }

    function _getPaidCouponKey(address playerAddress, address contractAddress, uint32 raffleId, uint32 ticketId)
    public pure returns (string memory){
        return string(abi.encodePacked(
                _toString(abi.encodePacked(playerAddress), false), '-',
                _toString(abi.encodePacked(contractAddress), false), '-',
                Strings.toString(raffleId), '-',
                Strings.toString(ticketId)
            ));
    }

    function getKeyHash(string memory key) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(key));
    }

    function checkToken(address tokenAddress) internal view {
        // Check for non-erc20
        if (tokenAddress != address(0)) {
            IERC20 token = IERC20(tokenAddress);
            try token.balanceOf(address(0)) {
            } catch {
                revert Coupons__NotERC20Address();
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICoupons{

    struct Coupon {
        bytes32 couponHash;
        uint8 minPct;
        uint8 maxPct;
        uint16 multiplierPct;
        bool isPaid;
    }

    struct CouponRule {
        uint16 minRndPct;
        uint16 maxRndPct;
        uint16 step;
        bool allowExtMultiplier;    // Allow external multiplier
    }

    struct CouponPrice {
        address tokenAddress;       // if address 0x0 - this is base currency
        uint couponFee;
    }

    struct CouponTicket {
        address playerAddress;
        uint16 multiplierPct;
        bool used;
    }

    function getCoupon(
        bytes32 couponHash,
        address playerAddress,
        address contractAddress,
        uint32 raffleId
    ) external view returns (Coupon memory);

    /*
     * @notice Buy a coupon for tokens with predefined multiplier percentage.
     * @dev If the sale is for erc20 tokens, then the payment amount in the transaction
     * 'msg.value' must be set to zero.
     *
     * @param contractAddress The address of the drop game contract.
     * @param raffleId The draw Id.
     * @param tokenAddress The address of the payment token. Use address(0) for native token payments.
     * @param amount `amount` of tokens to pay. For the native token must be 0
     * @param multiplierPct Multiplier percentage.
     *        If set to 0, the value will be generated by the contract based on the rule.
     * @return void
     */
    function buyCoupon(
        address contractAddress,
        uint32 raffleId,
        address tokenAddress,
        uint256 amount,
        uint16 multiplierPct
    ) external payable;

    function useCoupon(
        bytes32 couponHash,
        address playerAddress,
        uint32 raffleId
    ) external returns (Coupon memory);

    function getCouponTicket(
        address contractAddress,
        uint32 raffleId,
        bytes32 couponHash
    ) external returns (CouponTicket memory);
}