// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The NFT swap pool factory interface
/// @notice Creates swap pools and manages fees
interface INFTSwapFactory {
    /// @notice Emitted when a pool is created
    /// @param token0 The first NFT of the pool by address sort order
    /// @param token1 The second NFT of the pool by address sort order
    /// @param pool The address of the pool created
    event PoolCreated(address token0, address token1, address pool);

    /// @notice Returns the current fee receiver
    /// @dev Can be changed by the current fee setter via setFeeReceiver()
    /// @return The current fee receiver
    function getFeeReceiver() external view returns (address);

    /// @notice Returns the current fee receiver setter
    /// @dev Can be changed by the current fee setter via setFeeReceiverSetter()
    /// @return The current fee receiver setter
    function getFeeReceiverSetter() external view returns (address);

    /// @notice Returns all pool addresses
    /// @return Array of pool address
    function getAllPools() external view returns (address[] memory);

    /// @notice Returns pool address
    /// @dev token0 and token1 can be passed in any order
    /// @param token0 The first NFT of the pool
    /// @param token1 The seconf NFT of the pool
    /// @return The pool address of the NFT pair
    function getPool(address token0, address token1)
        external
        view
        returns (address);

    /// @notice Creates the nft swap pool
    /// @dev tokenA and tokenB can be passed in any order
    /// @param tokenA The first NFT of the pool
    /// @param tokenB The second NFT of the pool
    /// @return pool The address of the pool created
    function createPool(address tokenA, address tokenB)
        external
        returns (address pool);

    /// @notice Updates fee receiver
    /// @dev Can only be called by the current fee receiver setter
    /// @param feeReceiver The address of the new fee receiver
    function setFeeReceiver(address feeReceiver) external;

    /// @notice Updates fee receiver setter
    /// @dev Can only be called by the current fee receiver setter
    /// @param feeReceiverSetter The address of the new fee receiver setter
    function setFeeReceiverSetter(address feeReceiverSetter) external;
}
