// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import './interfaces/IERC20Mintable.sol';
import './interfaces/IUniswapOracle.sol';


contract Exchange is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20Mintable;

    uint256 public fee;
    uint256 public constant HUNDRED_PERCENT = 10000;

    address public feeReceiver;

    // Pair tokens for Uniswap oracle
    address public immutable dai;
    address public immutable weth;

    IUniswapOracle public immutable oracle;
    IERC20Mintable public immutable pusd;
    IERC20Mintable public immutable privi;

    event FeeChanged(uint256 oldFee, uint256 newFee);
    event FeeReceiverChanged(address oldReceiver, address newReceiver);
    event Exchanged(address tokenIn, address tokenOut, address receiver, uint256 amountIn, uint256 amountOut, uint256 fee);


    // ------------------------
    // CONSTRUCTOR
    // ------------------------


    /// @param pusd_ address of PUSD token
    /// @param privi_ address of PRIVI token
    /// @param dai_ address of DAI token
    /// @param weth_ address of WETH token
    /// @param feeReceiver_ address who should receive fees from exchanges
    /// @param fee_ fee percent amount multiplied by 100 (eg 10% should be 1000, 35% should be 3500)
    /// @param oracle_ address of uniswap oracle contract
    constructor (
        address pusd_,
        address privi_,
        address dai_,
        address weth_,
        address feeReceiver_,
        uint256 fee_,
        address oracle_
    ) {
        require(pusd_ != address(0), 'Stablecoin: Zero PUSD address!');
        require(privi_ != address(0), 'Stablecoin: Zero PRIVI address!');
        require(dai_ != address(0), 'Stablecoin: Zero DAI address!');
        require(weth_ != address(0), 'Stablecoin: Zero WETH address!');
        require(oracle_ != address(0), 'Stablecoin: Zero Oracle address!');
        require(feeReceiver_ != address(0), 'Stablecoin: Zero fee receiver address!');
        require(fee_ < HUNDRED_PERCENT, 'Stablecoin: Fee should be less then hundred percent!');

        fee = fee_;
        dai = dai_;
        weth = weth_;
        feeReceiver = feeReceiver_;

        pusd = IERC20Mintable(pusd_);
        privi = IERC20Mintable(privi_);
        oracle = IUniswapOracle(oracle_);
    }


    // ------------------------
    // SETTERS
    // ------------------------


    /// @notice Convert PRIVI to PUSD
    /// @dev Before calling it users need to approve PRIVI tokens to this contract
    /// Contract will burn PRIVI tokens, mint PUSD to the caller address
    function priviToPusd(uint256 amount) external returns (uint256) {
        return _exchange(
            msg.sender,
            msg.sender,
            privi,
            pusd,
            amount
        );
    }

    /// @notice Convert PUSD to PRIVI
    /// @dev Before calling it users need to approve PUSD tokens to this contract
    /// Contract will burn PUSD tokens, mint PRIVI to the caller address
    function pusdToPrivi(uint256 amount) external returns (uint256) {
        return _exchange(
            msg.sender,
            msg.sender,
            pusd,
            privi,
            amount
        );
    }

    /// @notice Change fee percent
    /// @dev The new fee can not be more than the current fee, it can be only decreased. Only owner can call this method
    /// @param fee_ percent should be multiplied by 100 (eg 10% should be 1000, 35% should be 3500)
    function changeFee(uint256 fee_) external onlyOwner {
        require(fee_ < fee, 'changeFee: New fee should be less!');

        emit FeeChanged(fee, fee_);
        fee = fee_;
    }

    /// @notice Change fee receiver address
    /// @dev Only owner can call this method
    /// @param feeReceiver_ new fefe receiver address
    function changeFeeReceiver(address feeReceiver_) external onlyOwner {
        emit FeeReceiverChanged(feeReceiver, feeReceiver_);
        feeReceiver = feeReceiver_;
    }


    // ------------------------
    // INTERNAL
    // ------------------------


    /// @notice Implement core exchange logic
    /// @dev It calculates and transfers fee, burn and mint tokens. All data can be detected by `Exchanged` event and indexer
    /// @param initiator address who initiated exchange
    /// @param receiver address who should receive minted token
    /// @param tokenIn token which should be burned
    /// @param tokenOut token which should be minted
    /// @param amountIn tokens which initiator wants to exchange
    /// @return tokenOut tokens which receiver claimed
    function _exchange(
        address initiator,
        address receiver,
        IERC20Mintable tokenIn,
        IERC20Mintable tokenOut,
        uint256 amountIn
    ) private returns (uint256) {
        //  Receive tokens from sender address
        tokenIn.safeTransferFrom(initiator, address(this), amountIn);

        //  Calculate exchange fee and send to platform address
        uint256 totalFee = amountIn.mul(fee).div(HUNDRED_PERCENT);
        tokenIn.safeTransfer(feeReceiver, totalFee);

        //  Decrease `amount` by fee
        amountIn = amountIn.sub(totalFee);

        //  Update oracle price before fetching the price
        oracle.update();

        //  Get mintable amount from oracle contract
        uint256 amountOut = _getOracleAmountOut(address(tokenIn), amountIn);

        //  Burn `amount` and mint out tokens
        tokenIn.burn(amountIn);
        tokenOut.mint(receiver, amountOut);

        emit Exchanged(address(tokenIn), address(tokenOut), receiver, amountIn, amountOut, totalFee);

        return amountOut;
    }

    /// @notice Get amount from oracle contract
    /// @dev Method returns amount, which user will receive after swapping `amountIn` tokens
    /// @param token address which user want to swap
    /// @param amountIn which user want to swap
    function _getOracleAmountOut(address token, uint256 amountIn) private view returns (uint256) {
        // PUSD = DAI, PRIVI = WETH
        address pairAddress = token == address(pusd) ? dai : weth;
        return oracle.consult(pairAddress, amountIn);
    }
}