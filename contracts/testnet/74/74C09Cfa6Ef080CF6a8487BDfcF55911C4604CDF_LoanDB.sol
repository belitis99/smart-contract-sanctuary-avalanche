// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/** 
    @title Owned
    @dev allows for ownership transfer and a contract that inherits from it.
    @author abhaydeshpande
*/

contract Owned {
    address payable public owner;

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function");
        _;
    }

    function transferOwnership(address payable newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero");
        owner = newOwner;
    }
}

contract MyContract is Owned {
    fallback() external payable {
        revert("Invalid transaction");
    }

    receive() external payable {
        owner.transfer(msg.value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./ContractManager.sol";
import "./ContractNames.sol";


/**
    @title BaseContainer
    @dev Contains all getters of contract addresses in the system
    @author abhaydeshpande
 */
contract BaseContainer is ContractManager, ContractNames {
    function getAddressOfLoanManager() public view returns (address) {
        return getContract(CONTRACT_LOAN_MANAGER);
    }

    function getAddressOfWallet() public view returns (address) {
        return getContract(CONTRACT_WALLET);
    }

    function getAddressOfLoanDB() public view returns (address) {
        return getContract(CONTRACT_LOAN_DB);
    }

    function getAddressOfHeartToken() public view returns (address) {
        return getContract(CONTRACT_HEART_TOKEN);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../auth/Owned.sol";
import "./ContractNames.sol";
import "./BaseContainer.sol";


/**
    @title Contained
    @dev Wraps the contracts and functions from unauthorized access outside the system
    @author abhaydeshpande
 */
contract Contained is Owned, ContractNames {
    BaseContainer public container;

    function setContainerEntry(BaseContainer _container) public onlyOwner {
        container = _container;
    }

    modifier onlyContained() {
        require(address(container) != address(0), "No Container");
        require(msg.sender == address(container), "Only through Container");
        _;
    }

    modifier onlyContract(string memory name) {
        require(address(container) != address(0), "No Container");
        address allowedContract = container.getContract(name);
        require(allowedContract != address(0), "Invalid contract name");
        require(
            msg.sender == allowedContract,
            "Only specific contract can access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../auth/Owned.sol";


/**
    @title ContractManager
    @dev Manages all the contract in the system
    @author abhaydeshpande
 */
contract ContractManager is Owned {
    mapping(string => address) private contracts;

    function addContract(string memory name, address contractAddress)
        public
        onlyOwner
    {
        require(contracts[name] == address(0), "Contract already exists");
        contracts[name] = contractAddress;
    }

    function getContract(string memory name) public view returns (address) {
        require(contracts[name] != address(0), "Contract hasn't set yet");
        return contracts[name];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

/**
    @title ContractNames
    @dev defines constant strings representing the names of other contracts in the system.
    @author abhaydeshpande
 */
contract ContractNames {
    string constant CONTRACT_LOAN_MANAGER = "LoanManager";
    string constant CONTRACT_WALLET = "Wallet";
    string constant CONTRACT_LOAN_DB = "LoanDB";
    string constant CONTRACT_HEART_TOKEN = "HeartToken";
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "../lib/SafeMath.sol";
import "../container/Contained.sol";

/**
    @title LoanDB
    @dev Stores all the loan details.
    @author abhaydeshpande
 */
contract LoanDB is Contained {
    using SafeMath for uint256;
    enum LoanState {
    REQUESTED,
    FUNDED,
    PAID
}

struct Debt {
    address lender;
    address borrower;
    uint256 amountOfDebt;
    uint256 interest;
    uint8 loanState;
}

mapping(bytes32 => Debt) private debtInfo;
mapping(address => bytes32[]) private debtHistory;
mapping(address => bytes32[]) private lendHistory;
mapping(address => bool) private haveDebt;

function addDebt(
    bytes32 debtNo,
    address borrower,
    uint256 amountOfDebt,
    uint256 interest
) external onlyContract(CONTRACT_LOAN_MANAGER) {
    require(amountOfDebt > 0, "Invalid debt amount");
    require(interest > 0, "Invalid interest rate");

    Debt storage newDebt = debtInfo[debtNo];
    require(newDebt.amountOfDebt == 0, "Debt already exists");

    newDebt.borrower = borrower;
    newDebt.amountOfDebt = amountOfDebt;
    newDebt.interest = interest;
    newDebt.loanState = uint8(LoanState.REQUESTED);

    debtHistory[borrower].push(debtNo);
}

function updateLender(bytes32 debtNo, address lender)
    external
    onlyContract(CONTRACT_LOAN_MANAGER)
{
    require(lender != address(0), "Invalid lender address");

    Debt storage updatedDebt = debtInfo[debtNo];
    require(updatedDebt.amountOfDebt > 0, "Debt does not exist");
    require(
        updatedDebt.lender == address(0),
        "Lender is already assigned"
    );

    updatedDebt.lender = lender;
    updatedDebt.loanState = uint8(LoanState.FUNDED);

    lendHistory[lender].push(debtNo);
}

function completeDebt(bytes32 debtNo)
    external
    onlyContract(CONTRACT_LOAN_MANAGER)
{
    Debt storage completedDebt = debtInfo[debtNo];
    require(completedDebt.amountOfDebt > 0, "Debt does not exist");

    completedDebt.loanState = uint8(LoanState.PAID);
}

function setHaveDebt(address sender, bool state)
    external
    onlyContract(CONTRACT_LOAN_MANAGER)
{
    haveDebt[sender] = state;
}

function checkHaveDebt(address sender) external view returns (bool) {
    return haveDebt[sender];
}

function getLenderofDebt(bytes32 debtNo) external view returns (address) {
    return debtInfo[debtNo].lender;
}

function getBorrowerofDebt(bytes32 debtNo) external view returns (address) {
    return debtInfo[debtNo].borrower;
}

function getAmountofDebt(bytes32 debtNo) external view returns (uint256) {
    return debtInfo[debtNo].amountOfDebt;
}

function getInterestofDebt(bytes32 debtNo) external view returns (uint256) {
    return debtInfo[debtNo].interest;
}

function getStateofDebt(bytes32 debtNo) external view returns (uint8) {
    return debtInfo[debtNo].loanState;
}

function getDebtHistory(address _address)
    external
    view
    returns (bytes32[] memory)
{
    require(msg.sender == _address || msg.sender == owner, "Unauthorized access");

    return debtHistory[_address];
}

function getLendHistory(address _address)
    external
    view
    returns (bytes32[] memory)
{
    require(msg.sender == _address || msg.sender == owner, "Unauthorized access");

    return lendHistory[_address];
}}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;


/**
 * @dev provides arithmetic functions with overflow/underflow protection.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage)
        internal
        pure
        returns (uint256)
    {
        require(b != 0, errorMessage);
        return a % b;
    }
}