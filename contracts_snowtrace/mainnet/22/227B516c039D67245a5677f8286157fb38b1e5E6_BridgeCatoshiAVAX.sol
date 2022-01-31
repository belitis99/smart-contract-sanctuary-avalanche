/**
 *Submitted for verification at snowtrace.io on 2022-01-05
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

 abstract contract Context {
    function _msgSender() internal view virtual returns (address ) {
        return msg.sender;
    }
}

library SafeMath {
  function add(uint a, uint b) internal pure returns(uint) {
    uint c = a + b;
    require(c >= a, "SafeMath: addition overflow");

    return c;
  }

  function sub(uint a, uint b) internal pure returns(uint) {
    return sub(a, b, "SafeMath: subtraction overflow");
  }

  function sub(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    require(b <= a, errorMessage);
    uint c = a - b;

    return c;
  }

  function mul(uint a, uint b) internal pure returns(uint) {
    if (a == 0) {
        return 0;
    }

    uint c = a * b;
    require(c / a == b, "SafeMath: multiplication overflow");

    return c;
  }

  function div(uint a, uint b) internal pure returns(uint) {
    return div(a, b, "SafeMath: division by zero");
  }

  function div(uint a, uint b, string memory errorMessage) internal pure returns(uint) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, errorMessage);
    uint c = a / b;

    return c;
  }
}

  contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

  
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}



library TransferHelper {
    function safeApprove(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract BridgeCatoshiAVAX is Context, Ownable {
    using SafeMath for uint256;
    
  
    
    mapping(uint256 => uint256) private _nonces;
    mapping(uint256 => mapping(uint256 => bool)) private nonceProcessed;
    mapping(uint256 => uint256) private _processedFees;

    uint256 private _bridgeFee = 3;
    bool public _isBridgingPaused = false;
    


    address public catoshi;
    address public system = address(0xa0266B27BF0D6d4Dd326eA10B6e0fF2cF06651E1);
    address public bridgeFeesAddress = address(0xD378dBeD86689D0dBA19Ca2bab322B6f23765288);

    
    event SwapRequest(
        address indexed to,
        uint256 amount,
        uint256 nonce,
        uint256 toChainID
    );

    modifier onlySystem() {
        require(system == _msgSender(), "Ownable: caller is not the system");
        _;
    }
    
    modifier bridgingPaused() {
        require(!_isBridgingPaused, "the bridging is paused");
        _;
    }

    constructor()  {
        _processedFees[56] = 0.01 ether;
    }
   
   function updateCatoshiContract(address _catoshi) external onlyOwner {
       catoshi = _catoshi;
   }
   
   
    function setBridgeFee(uint256 bridgeFee) external onlyOwner returns(bool){
        require(bridgeFee > 0, "Invalid Percentage");
        _bridgeFee = bridgeFee;
        return true;
  }
  
  function setBridgeFeesAddress(address _bridgeFeesAddress) external onlyOwner {
        bridgeFeesAddress = _bridgeFeesAddress;
    }
    
      function getBridgeFee() external view returns(uint256){
        return _bridgeFee;
      }
      
      function setSystem(address _system) external onlyOwner returns(bool){
          system = _system;
          return true;
      }
      
      
    function setProcessedFess(uint256 chainID, uint256 processedFees)
        external
        onlyOwner
    {
        _processedFees[chainID] = processedFees;
    }
    
    function getProcessedFees(uint256 chainID) external view returns(uint256){
        return _processedFees[chainID];
    }
  

    function getBridgeStatus(uint256 nonce, uint256 fromChainID)
        external
        view
        returns (bool)
    {
        return nonceProcessed[fromChainID][nonce];
    }
    
    
    function updateBridgingStaus(bool paused) external onlyOwner {
        _isBridgingPaused = paused;
    }
    

    
    function swap (uint256 amount, uint256 toChainID) external bridgingPaused payable {
        require(msg.value>= _processedFees[toChainID], "Insufficient processed fees");
         uint256 _nonce = _nonces[toChainID];
        _nonce = _nonce.add(1);
        _nonces[toChainID] = _nonce;
        TransferHelper.safeTransferFrom(
            catoshi,
            _msgSender(),
            address(this),
            amount
        );
        payable(system).transfer(msg.value);
        emit SwapRequest(_msgSender(), amount, _nonce, toChainID);
        
    }
    
    function feeCalculation(uint256 amount) public view returns(uint256) { 
       uint256 _amountAfterFee = (amount-(amount.mul(_bridgeFee)/1000));
        return _amountAfterFee;
    }  
    
    function swapBack(
        address to,
        uint256 amount,
        uint256 nonce,
        uint256 fromChainID
    ) external onlySystem {
        require(
            !nonceProcessed[fromChainID][nonce],
            "Swap is already proceeds"
        );
        nonceProcessed[fromChainID][nonce] = true;

        uint256 temp = feeCalculation(amount);
        uint256 fees = amount.sub(temp);

        TransferHelper.safeTransfer(catoshi, bridgeFeesAddress, fees);

        TransferHelper.safeTransfer(catoshi, to, temp);
    }
}