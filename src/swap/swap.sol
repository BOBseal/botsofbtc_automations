// SPDX-License-Identifier: GPL-3.0-or-later
import "./libraries/Commands.sol";
import "./V3Path.sol";
interface IPermit{
    function approve(address token, address spender, uint160 amount, uint48 expiration) external;
}

contract Swapper {
    address public Weth;
    address public Usdc;
    address public Permit2;
    address public universalRouter;
    bytes public commandsInput = 0x0a00;
    function SwapUsdToWeth ()

}