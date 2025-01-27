/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-09
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BatchSender {
    address private admin;
    uint256 private defaultValue = 0.02 * 10 ** 18;
    address private token = address(0x0);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function setDefaultValue(uint256 newValue) external onlyAdmin {
        defaultValue = newValue;
    }

    function setToken(address newToken) external onlyAdmin {
        token = newToken;
    }

    function withdrawnFund(address payable destination) external onlyAdmin {
        require(address(this).balance > 0);

        destination.transfer(address(this).balance);
    }

    function batchEth(address payable[] memory accounts) external onlyAdmin {
        uint256 value = defaultValue;
        uint256 total = value * accounts.length;

        require(address(this).balance >= total);

        for (uint256 i = 0; i<accounts.length; i++) {
            require(accounts[i].send(value));
        }
    }

    function batchToken(address payable[] memory accounts) external onlyAdmin {
        uint256 value = 1 * 10 ** 18;

        uint256 balance = IERC20(token).balanceOf(msg.sender);
        uint256 total = accounts.length * value;

        require(balance >= total);
        require(token != address(0x0));

        for (uint256 i = 0; i<accounts.length; i++) {
            IERC20(token).transferFrom(msg.sender, accounts[i], value);
        }
    }
}