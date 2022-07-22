// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INFTSwapFactory {
    event PoolCreated(address token0, address token1, address pool);

    function getFeeReceiver() external view returns (address);

    function getFeeReceiverSetter() external view returns (address);

    function getAllPools() external view returns (address[] memory);

    function getPool(address token0, address token1)
        external
        view
        returns (address);

    function createPool(address tokenA, address tokenB)
        external
        returns (address pool);

    function setFeeReceiver(address _feeReceiver) external;

    function setFeeReceiverSetter(address _feeReceiverSetter) external;
}
