// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "dnd/swap/libraries/UniswapV2Library.sol";
import "dnd/swap/interfaces/IUniswapV2Factory.sol";
import "dnd/swap/libraries/TransferHelper.sol";
import "dnd/swap/interfaces/IWETH.sol";
import "dnd/swap/interfaces/IERC20.sol";
import "dnd/swap/interfaces/IUniswapV2Router02.sol";
contract Swap  {

  address public immutable factory0;
  address public immutable WETH0;
  address public immutable factory;
  address public immutable WETH;
  constructor (address tfactory0, address tWETH0, address tfactory, address tWETH)
  {
    factory0 = tfactory0;
    WETH0 = tWETH0;
    factory = tfactory;
    WETH = tWETH;
  }
  function _addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin) internal virtual returns (uint256 amountA,uint256 amountB)
  {
    if(IUniswapV2Factory(factory0).getPair(tokenA, tokenB) == address(0)) {
      IUniswapV2Factory(factory0).createPair(tokenA, tokenB);
    }
    (uint256 reserveA, uint256 reserveB) = UniswapV2Library.getReserves(factory0, tokenA, tokenB);
    if(reserveA == 0 && reserveB == 0) {
      (amountA, amountB) = (amountADesired, amountBDesired);
    } else {
      uint256 amountBOptimal = UniswapV2Library.quote(amountADesired, reserveA, reserveB);
      if(amountBOptimal <= amountBDesired) {
        require ((amountBOptimal >= amountBMin),"UniswapV2Router: INSUFFICIENT_B_AMOUNT");
        (amountA, amountB) = (amountADesired, amountBOptimal);
      } else {
        uint256 amountAOptimal = UniswapV2Library.quote(amountBDesired, reserveB, reserveA);
        assert ((amountAOptimal <= amountADesired));
        require ((amountAOptimal >= amountAMin),"UniswapV2Router: INSUFFICIENT_A_AMOUNT");
        (amountA, amountB) = (amountAOptimal, amountBDesired);
      }
    }
  }
  

  modifier ensure0 (uint256  deadline)   {
    require ((deadline >= block.timestamp),"UniswapV2Router: EXPIRED");
    _;
  }
  

  function addLiquidity(address tokenA, address tokenB, uint256 amountADesired, uint256 amountBDesired, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) external virtual ensure0(deadline) returns (uint256 amountA,uint256 amountB,uint256 liquidity)
  {
    (amountA, amountB) = _addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin);
    address pair = UniswapV2Library.pairFor(factory0, tokenA, tokenB);
    TransferHelper.safeTransferFrom(tokenA, msg.sender, pair, amountA);
    TransferHelper.safeTransferFrom(tokenB, msg.sender, pair, amountB);
    liquidity = IUniswapV2Pair(pair).mint(to);
  }
  

  function addLiquidityETH(address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) external virtual payable ensure0(deadline) returns (uint256 amountToken,uint256 amountETH,uint256 liquidity)
  {
    (amountToken, amountETH) = _addLiquidity(token, WETH0, amountTokenDesired, msg.value, amountTokenMin, amountETHMin);
    address pair = UniswapV2Library.pairFor(factory0, token, WETH0);
    TransferHelper.safeTransferFrom(token, msg.sender, pair, amountToken);
    IWETH(WETH0).deposit{value: amountETH}();
    assert ((IWETH(WETH0).transfer(pair, amountETH)));
    liquidity = IUniswapV2Pair(pair).mint(to);
    if(msg.value > amountETH) {
    }
    TransferHelper.safeTransferETH(msg.sender, msg.value - amountETH);
  }
  

  function removeLiquidity(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline) public virtual ensure0(deadline) returns (uint256 amountA,uint256 amountB)
  {
    address pair = UniswapV2Library.pairFor(factory0, tokenA, tokenB);
    IUniswapV2Pair(pair).transferFrom(msg.sender, pair, liquidity);
    (uint256 amount0, uint256 amount1) = IUniswapV2Pair(pair).burn(to);
    (address token0, ) = UniswapV2Library.sortTokens(tokenA, tokenB);
    (amountA, amountB) = tokenA == token0 ? (amount0, amount1) : (amount1, amount0);
    require ((amountA >= amountAMin),"UniswapV2Router: INSUFFICIENT_A_AMOUNT");
    require ((amountB >= amountBMin),"UniswapV2Router: INSUFFICIENT_B_AMOUNT");
  }
  

  function removeLiquidityETH(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) public virtual ensure0(deadline) returns (uint256 amountToken,uint256 amountETH)
  {
    (amountToken, amountETH) = removeLiquidity(token, WETH0, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
    TransferHelper.safeTransfer(token, to, amountToken);
    IWETH(WETH0).withdraw(amountETH);
    TransferHelper.safeTransferETH(to, amountETH);
  }
  

  function removeLiquidityWithPermit(address tokenA, address tokenB, uint256 liquidity, uint256 amountAMin, uint256 amountBMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external virtual returns (uint256 amountA,uint256 amountB)
  {
    address pair = UniswapV2Library.pairFor(factory0, tokenA, tokenB);
    uint256 value = approveMax ? type(uint256).max : liquidity;
    IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountA, amountB) = removeLiquidity(tokenA, tokenB, liquidity, amountAMin, amountBMin, to, deadline);
  }
  

  function removeLiquidityETHWithPermit(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external virtual returns (uint256 amountToken,uint256 amountETH)
  {
    address pair = UniswapV2Library.pairFor(factory0, token, WETH0);
    uint256 value = approveMax ? type(uint256).max : liquidity;
    IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    (amountToken, amountETH) = removeLiquidityETH(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }
  

  function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline) public virtual ensure0(deadline) returns (uint256 amountETH)
  {
    (, amountETH) = removeLiquidity(token, WETH0, liquidity, amountTokenMin, amountETHMin, address(this), deadline);
    TransferHelper.safeTransfer(token, to, IERC20Uniswap(token).balanceOf(address(this)));
    IWETH(WETH0).withdraw(amountETH);
    TransferHelper.safeTransferETH(to, amountETH);
  }
  

  function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint256 liquidity, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external virtual returns (uint256 amountETH)
  {
    address pair = UniswapV2Library.pairFor(factory0, token, WETH0);
    uint256 value = approveMax ? type(uint256).max : liquidity;
    IUniswapV2Pair(pair).permit(msg.sender, address(this), value, deadline, v, r, s);
    amountETH = removeLiquidityETHSupportingFeeOnTransferTokens(token, liquidity, amountTokenMin, amountETHMin, to, deadline);
  }
  

  function _swap(uint256[] memory amounts, address[] memory path, address _to) internal virtual
  {
    for (uint256 i; i < path.length - 1; i++)
    {
      (address input, address output) = (path[i], path[(i + 1)]);
      (address token0, ) = UniswapV2Library.sortTokens(input, output);
      uint256 amountOut = amounts[(i + 1)];
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOut) : (amountOut, uint256(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory0, output, path[(i + 2)]) : _to;
      IUniswapV2Pair(UniswapV2Library.pairFor(factory0, input, output)).swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }
  

  function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external virtual ensure0(deadline) returns (uint256[] memory amounts)
  {
    amounts = UniswapV2Library.getAmountsOut(factory0, amountIn, path);
    require ((amounts[(amounts.length - 1)] >= amountOutMin),"UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
    TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory0, path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }
  

  function swapTokensForExactTokens(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external virtual ensure0(deadline) returns (uint256[] memory amounts)
  {
    amounts = UniswapV2Library.getAmountsIn(factory0, amountOut, path);
    require ((amounts[0] <= amountInMax),"UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
    TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory0, path[0], path[1]), amounts[0]);
    _swap(amounts, path, to);
  }
  

  function swapExactETHForTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external virtual payable ensure0(deadline) returns (uint256[] memory amounts)
  {
    require ((path[0] == WETH0),"UniswapV2Router: INVALID_PATH");
    amounts = UniswapV2Library.getAmountsOut(factory0, msg.value, path);
    require ((amounts[(amounts.length - 1)] >= amountOutMin),"UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
    IWETH(WETH0).deposit{value: amounts[0]}();
    assert ((IWETH(WETH0).transfer(UniswapV2Library.pairFor(factory0, path[0], path[1]), amounts[0])));
    _swap(amounts, path, to);
  }
  

  function swapTokensForExactETH(uint256 amountOut, uint256 amountInMax, address[] calldata path, address to, uint256 deadline) external virtual ensure0(deadline) returns (uint256[] memory amounts)
  {
    require ((path[(path.length - 1)] == WETH0),"UniswapV2Router: INVALID_PATH");
    amounts = UniswapV2Library.getAmountsIn(factory0, amountOut, path);
    require ((amounts[0] <= amountInMax),"UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
    TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory0, path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));
    IWETH(WETH0).withdraw(amounts[(amounts.length - 1)]);
    TransferHelper.safeTransferETH(to, amounts[(amounts.length - 1)]);
  }
  

  function swapExactTokensForETH(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external virtual ensure0(deadline) returns (uint256[] memory amounts)
  {
    require ((path[(path.length - 1)] == WETH0),"UniswapV2Router: INVALID_PATH");
    amounts = UniswapV2Library.getAmountsOut(factory0, amountIn, path);
    require ((amounts[(amounts.length - 1)] >= amountOutMin),"UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
    TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory0, path[0], path[1]), amounts[0]);
    _swap(amounts, path, address(this));
    IWETH(WETH0).withdraw(amounts[(amounts.length - 1)]);
    TransferHelper.safeTransferETH(to, amounts[(amounts.length - 1)]);
  }
  

  function swapETHForExactTokens(uint256 amountOut, address[] calldata path, address to, uint256 deadline) external virtual payable ensure0(deadline) returns (uint256[] memory amounts)
  {
    require ((path[0] == WETH0),"UniswapV2Router: INVALID_PATH");
    amounts = UniswapV2Library.getAmountsIn(factory0, amountOut, path);
    require ((amounts[0] <= msg.value),"UniswapV2Router: EXCESSIVE_INPUT_AMOUNT");
    IWETH(WETH0).deposit{value: amounts[0]}();
    assert ((IWETH(WETH0).transfer(UniswapV2Library.pairFor(factory0, path[0], path[1]), amounts[0])));
    _swap(amounts, path, to);
    if(msg.value > amounts[0]) {
    }
    TransferHelper.safeTransferETH(msg.sender, msg.value - amounts[0]);
  }
  

  function _swapSupportingFeeOnTransferTokens(address[] memory path, address _to) internal virtual
  {
    for (uint256 i; i < path.length - 1; i++)
    {
      (address input, address output) = (path[i], path[(i + 1)]);
      (address token0, ) = UniswapV2Library.sortTokens(input, output);
      IUniswapV2Pair pair = IUniswapV2Pair(UniswapV2Library.pairFor(factory0, input, output));
      uint256 amountInput;
      uint256 amountOutput;
      {
        (uint256 reserve0, uint256 reserve1, ) = pair.getReserves();
        (uint256 reserveInput, uint256 reserveOutput) = input == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
        amountInput = IERC20Uniswap(input).balanceOf(address(pair)) - reserveInput;
        amountOutput = UniswapV2Library.getAmountOut(amountInput, reserveInput, reserveOutput);
      }
      (uint256 amount0Out, uint256 amount1Out) = input == token0 ? (uint256(0), amountOutput) : (amountOutput, uint256(0));
      address to = i < path.length - 2 ? UniswapV2Library.pairFor(factory0, output, path[(i + 2)]) : _to;
      pair.swap(amount0Out, amount1Out, to, new bytes(0));
    }
  }
  

  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external virtual ensure0(deadline)
  {
    TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory0, path[0], path[1]), amountIn);
    uint256 balanceBefore = IERC20Uniswap(path[(path.length - 1)]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require ((IERC20Uniswap(path[(path.length - 1)]).balanceOf(to) - balanceBefore >= amountOutMin),"UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
  }
  

  function swapExactETHForTokensSupportingFeeOnTransferTokens(uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external virtual payable ensure0(deadline)
  {
    require ((path[0] == WETH0),"UniswapV2Router: INVALID_PATH");
    uint256 amountIn = msg.value;
    IWETH(WETH0).deposit{value: amountIn}();
    assert ((IWETH(WETH0).transfer(UniswapV2Library.pairFor(factory0, path[0], path[1]), amountIn)));
    uint256 balanceBefore = IERC20Uniswap(path[(path.length - 1)]).balanceOf(to);
    _swapSupportingFeeOnTransferTokens(path, to);
    require ((IERC20Uniswap(path[(path.length - 1)]).balanceOf(to) - balanceBefore >= amountOutMin),"UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
  }
  

  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external virtual ensure0(deadline)
  {
    require ((path[(path.length - 1)] == WETH0),"UniswapV2Router: INVALID_PATH");
    TransferHelper.safeTransferFrom(path[0], msg.sender, UniswapV2Library.pairFor(factory0, path[0], path[1]), amountIn);
    _swapSupportingFeeOnTransferTokens(path, address(this));
    uint256 amountOut = IERC20Uniswap(WETH0).balanceOf(address(this));
    require ((amountOut >= amountOutMin),"UniswapV2Router: INSUFFICIENT_OUTPUT_AMOUNT");
    IWETH(WETH0).withdraw(amountOut);
    TransferHelper.safeTransferETH(to, amountOut);
  }
  

  function quote(uint256 amountA, uint256 reserveA, uint256 reserveB) public virtual pure returns (uint256 amountB)
  {
    return UniswapV2Library.quote(amountA, reserveA, reserveB);
  }
  

  function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public virtual pure returns (uint256 amountOut)
  {
    return UniswapV2Library.getAmountOut(amountIn, reserveIn, reserveOut);
  }
  

  function getAmountIn(uint256 amountOut, uint256 reserveIn, uint256 reserveOut) public virtual pure returns (uint256 amountIn)
  {
    return UniswapV2Library.getAmountIn(amountOut, reserveIn, reserveOut);
  }
  

  function getAmountsOut(uint256 amountIn, address[] memory path) public virtual view returns (uint256[] memory amounts)
  {
    return UniswapV2Library.getAmountsOut(factory0, amountIn, path);
  }
  

  function getAmountsIn(uint256 amountOut, address[] memory path) public virtual view returns (uint256[] memory amounts)
  {
    return UniswapV2Library.getAmountsIn(factory0, amountOut, path);
  }
  

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../interfaces/IUniswapV2Pair.sol";

library UniswapV2Library {
    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            bytes20(
                keccak256(
                    abi.encodePacked(
                        hex"ff",
                        factory,
                        keccak256(abi.encodePacked(token0, token1)),
                        hex"e18a34eb0e04b04f7a0ac29a6e80748dca96319b42c54d679cb821dca90c6303" // init code hash
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            pairFor(factory, tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(
            reserveA > 0 && reserveB > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        amountB = (amountA * (reserveB)) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * (1000) + amountInWithFee;
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "UniswapV2Library: INSUFFICIENT_LIQUIDITY"
        );
        uint256 numerator = reserveIn * amountOut * 1000;
        uint256 denominator = (reserveOut - amountOut) * 997;
        amountIn = (numerator / denominator) + 1;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i - 1],
                path[i]
            );
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;


interface IUniswapV2Router01 {
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}