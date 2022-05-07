/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-06
*/

// SPDX-License-Identifier : MIT

pragma solidity ^0.8.10;

contract swapWithoutSandwich {

    //uint numberOfAvax = 10e18;  
    //uint avaxUsdPrice = 65;
    //uint a = 95;
    //uint b = 100;
    //uint slippage = a / b;

    //uint amountOutMin1 = numberOfAvax * (avaxUsdPrice * slippage);
    uint amountOutMin1 = 1e18;
    address[] AvaxUsd = [0xd00ae08403B9bbb9124bB305C09058E32C39A48c, 0x7FB5b0137747Fb8AbE7eC2949D9b3365d2a35398];
    address timelock = 0x538E576A30DBBcecc74d746bACe27203BdEf50De;
    uint deadline1 = block.timestamp + 100; 


    
    function getCallDatas() public view returns (bytes memory callDatas) {

        uint amountOutMin = amountOutMin1;
        address[] memory path = AvaxUsd ;
        address to = timelock;
        uint deadline = deadline1; 
            
        callDatas = abi.encodeWithSignature("swapExactAVAXForTokens(uint256,address[],address,uint256)", amountOutMin, path, to, deadline); 
    
    }

    function execute(address payable target, uint amount, bytes memory callDatas) external payable {
        target.call(callDatas);

    }


}