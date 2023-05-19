// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * \
 * Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
 * EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
 *
 * Implementation of a diamond.
 * /*****************************************************************************
 */

import {LibFactoryDiamond} from "./libraries/LibFactoryDiamond.sol";
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";

import "./libraries/LibAppStorage.sol";

contract VaultFactoryDiamond {
    constructor(address _contractOwner, address _diamondCutFacet) payable {
        LibFactoryDiamond.setContractOwner(_contractOwner);

        // Add the diamondCut external function from the diamondCutFacet
        IDiamondCut.FacetCut[] memory cut = new IDiamondCut.FacetCut[](1);
        bytes4[] memory functionSelectors = new bytes4[](1);
        functionSelectors[0] = IDiamondCut.diamondCut.selector;
        cut[0] = IDiamondCut.FacetCut({
            facetAddress: _diamondCutFacet,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: functionSelectors
        });
        LibFactoryDiamond.diamondCut(cut, address(0), "");
    }

    function setAddresses(address[] calldata _addresses) external {
        LibFactoryDiamond.enforceIsContractOwner();
        FactoryAppStorage storage s = LibAppStorage.factoryAppStorage();
        s.diamondCutFacet = _addresses[0];
        s.erc20Facet = _addresses[1];
        s.erc721Facet = _addresses[2];
        s.erc1155Facet = _addresses[3];
        s.diamondLoupeFacet = _addresses[4];
        s.vaultFacet = _addresses[5];
    }

    function setSelectors(bytes4[][] calldata _selectors) external {
        LibFactoryDiamond.enforceIsContractOwner();
        FactoryAppStorage storage fs = LibAppStorage.factoryAppStorage();
        assert(_selectors.length == 5);
        fs.ERC20SELECTORS = _selectors[0];
        fs.ERC721SELECTORS = _selectors[1];
        fs.ERC1155SELECTORS = _selectors[2];
        fs.DIAMONDLOUPEFACETSELECTORS = _selectors[3];
        fs.VAULTFACETSELECTORS = _selectors[4];
    }

    function owner() public view returns (address owner_) {
        LibFactoryDiamond.DiamondStorage storage ds = LibFactoryDiamond
            .diamondStorage();
        owner_ = ds.contractOwner;
    }

    // Find facet for function that is called and execute the
    // function if a facet is found and return any value.
    fallback() external payable {
        LibFactoryDiamond.DiamondStorage storage ds;
        bytes32 position = LibFactoryDiamond.DIAMOND_STORAGE_POSITION;
        // get diamond storage
        assembly {
            ds.slot := position
        }
        // get facet from function selector
        address facet = ds.selectorToFacetAndPosition[msg.sig].facetAddress;
        require(facet != address(0), "Diamond: Function does not exist");
        // Execute external function from facet using delegatecall and return any value.
        assembly {
            // copy function selector and any arguments
            calldatacopy(0, 0, calldatasize())
            // execute function call using the facet
            let result := delegatecall(gas(), facet, 0, calldatasize(), 0, 0)
            // get any return value
            returndatacopy(0, 0, returndatasize())
            // return any return value or error back to the caller
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../../interfaces/IDiamondCut.sol";

library LibFactoryDiamond {
    error InValidFacetCutAction();
    error NotDiamondOwner();
    error NoSelectorsInFacet();
    error NoZeroAddress();
    error SelectorExists(bytes4 selector);
    error SameSelectorReplacement(bytes4 selector);
    error MustBeZeroAddress();
    error NoCode();
    error NonExistentSelector(bytes4 selector);
    error ImmutableFunction(bytes4 selector);
    error NonEmptyCalldata();
    error EmptyCalldata();
    error InitCallFailed();

    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.standard.factory.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage()
        internal
        pure
        returns (DiamondStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if (msg.sender != diamondStorage().contractOwner)
            revert NotDiamondOwner();
    }

    event DiamondCut(
        IDiamondCut.FacetCut[] _diamondCut,
        address _init,
        bytes _calldata
    );

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (
            uint256 facetIndex;
            facetIndex < _diamondCut.length;
            facetIndex++
        ) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(
                    _diamondCut[facetIndex].facetAddress,
                    _diamondCut[facetIndex].functionSelectors
                );
            } else {
                revert InValidFacetCutAction();
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress != address(0)) revert SelectorExists(selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        if (_facetAddress == address(0)) revert NoZeroAddress();
        uint96 selectorPosition = uint96(
            ds.facetFunctionSelectors[_facetAddress].functionSelectors.length
        );
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            if (oldFacetAddress == _facetAddress)
                revert SameSelectorReplacement(selector);
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(
        address _facetAddress,
        bytes4[] memory _functionSelectors
    ) internal {
        if (_functionSelectors.length <= 0) revert NoSelectorsInFacet();
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        if (_facetAddress != address(0)) revert MustBeZeroAddress();
        for (
            uint256 selectorIndex;
            selectorIndex < _functionSelectors.length;
            selectorIndex++
        ) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds
                .selectorToFacetAndPosition[selector]
                .facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(
        DiamondStorage storage ds,
        address _facetAddress
    ) internal {
        enforceHasContractCode(_facetAddress);
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds
            .facetAddresses
            .length;
        ds.facetAddresses.push(_facetAddress);
    }

    function addFunction(
        DiamondStorage storage ds,
        bytes4 _selector,
        uint96 _selectorPosition,
        address _facetAddress
    ) internal {
        ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(
            _selector
        );
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(
        DiamondStorage storage ds,
        address _facetAddress,
        bytes4 _selector
    ) internal {
        if (_facetAddress == address(0)) revert NonExistentSelector(_selector);
        // an immutable function is a function defined directly in a diamond
        if (_facetAddress == address(this)) revert ImmutableFunction(_selector);
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds
            .selectorToFacetAndPosition[_selector]
            .functionSelectorPosition;
        uint256 lastSelectorPosition = ds
            .facetFunctionSelectors[_facetAddress]
            .functionSelectors
            .length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds
                .facetFunctionSelectors[_facetAddress]
                .functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[
                selectorPosition
            ] = lastSelector;
            ds
                .selectorToFacetAndPosition[lastSelector]
                .functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[
                    lastFacetAddressPosition
                ];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds
                    .facetFunctionSelectors[lastFacetAddress]
                    .facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds
                .facetFunctionSelectors[_facetAddress]
                .facetAddressPosition;
        }
    }

    function initializeDiamondCut(
        address _init,
        bytes memory _calldata
    ) internal {
        if (_init == address(0)) {
            if (_calldata.length > 0) revert NonEmptyCalldata();
        } else {
            if (_calldata.length == 0) revert EmptyCalldata();
            if (_init != address(this)) {
                enforceHasContractCode(_init);
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert InitCallFailed();
                }
            }
        }
    }

    function enforceHasContractCode(address _contract) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if (contractSize <= 0) revert NoCode();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {
        Add,
        Replace,
        Remove
    }
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

pragma solidity 0.8.18;

import "../../Vault/libraries/LibKeepHelpers.sol";

struct FactoryAppStorage {
    //master vaultID
    uint256 VAULTID;
    //mapping(address=>uint[]) userVaults;

    //set during Master Diamond Deployment
    //used to upgrade individual vaults
    address diamondCutFacet;
    address erc20Facet;
    address erc721Facet;
    address erc1155Facet;
    address diamondLoupeFacet;
    address vaultFacet;
    //facet selector data for spawned vaults
    bytes4[] ERC20SELECTORS;
    bytes4[] ERC721SELECTORS;
    bytes4[] ERC1155SELECTORS;
    bytes4[] DIAMONDLOUPEFACETSELECTORS;
    bytes4[] VAULTFACETSELECTORS;
}

library LibAppStorage {
    function factoryAppStorage()
        internal
        pure
        returns (FactoryAppStorage storage fs)
    {
        assembly {
            fs.slot := 0
        }
    }
}

abstract contract StorageLayout {
    FactoryAppStorage internal fs;

    //  function removeArray(uint256 _val,address _inheritor) public {
    //     LibKeepHelpers.removeUint(fs.userVaults[_inheritor],_val);
    //  }

    // function addArray(uint256 _val,address _inheritor) public {
    //     LibKeepHelpers.removeUint(fs.userVaults[_inheritor],_val);
    //  }
}

pragma solidity 0.8.18;

library LibKeepHelpers {
    function findAddIndex(
        address _item,
        address[] memory addressArray
    ) internal pure returns (uint256 i) {
        for (i; i < addressArray.length; i++) {
            //using the conventional method since we cannot have duplicate addresses
            if (addressArray[i] == _item) {
                return i;
            }
        }
    }

    function findUintIndex(
        uint _item,
        uint[] memory noArray
    ) internal pure returns (uint256 i) {
        for (i; i < noArray.length; i++) {
            if (noArray[i] == _item) {
                return i;
            }
        }
    }

    function removeUint(uint[] storage _noArray, uint to) internal {
        require(_noArray.length > 0, "Non-elemented number array");
        uint256 index = findUintIndex(to, _noArray);
        if (_noArray.length == 1) {
            _noArray.pop();
        }
        if (_noArray.length > 1) {
            for (uint256 i = index; i < _noArray.length - 1; i++) {
                _noArray[i] = _noArray[i + 1];
            }
            _noArray.pop();
        }
    }

    function removeAddress(address[] storage _array, address _add) internal {
        require(_array.length > 0, "Non-elemented address array");
        uint256 index = findAddIndex(_add, _array);
        if (_array.length == 1) {
            _array.pop();
        }

        if (_array.length > 1) {
            for (uint256 i = index; i < _array.length - 1; i++) {
                _array[i] = _array[i + 1];
            }
            _array.pop();
        }
    }

    function _inUintArray(
        uint256[] memory _array,
        uint256 _targ
    ) internal pure returns (bool exists_) {
        if (_array.length > 0) {
            for (uint256 i; i < _array.length; i++) {
                if (_targ == _array[i]) {
                    exists_ = true;
                }
            }
        }
    }

    function _inAddressArray(
        address[] memory _array,
        address _targ
    ) internal pure returns (bool exists_) {
        if (_array.length > 0) {
            for (uint256 i; i < _array.length; i++) {
                if (_targ == _array[i]) {
                    exists_ = true;
                }
            }
        }
    }
}