// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/INFTSwapFactory.sol";
import "./interfaces/INFTSwapPool.sol";
import "./NFTSwapPool.sol";
import "./NoDelegateCall.sol";

error NFTSwapFactory__NotFeeSetter();

error NFTSwapFactory__ZeroAddress();

error NFTSwapFactory__PoolAlreadyExists();

contract NFTSwapFactory is INFTSwapFactory, NoDelegateCall {
    address private s_feeReceiver;

    address private s_feeReceiverSetter;

    address[] private s_allPools;

    mapping(address => mapping(address => address)) private s_pool;

    constructor() {
        s_feeReceiver = msg.sender;
        s_feeReceiverSetter = msg.sender;
    }

    modifier onlyFeeReceiverSetter() {
        if (msg.sender != s_feeReceiverSetter)
            revert NFTSwapFactory__NotFeeSetter();
        _;
    }

    function getFeeReceiver() external view override returns (address) {
        return s_feeReceiver;
    }

    function getFeeReceiverSetter() external view override returns (address) {
        return s_feeReceiverSetter;
    }

    function getAllPools() external view override returns (address[] memory) {
        return s_allPools;
    }

    function getPool(address nft0, address nft1)
        external
        view
        override
        returns (address)
    {
        return s_pool[nft0][nft1];
    }

    function _sortNFTs(address nftA, address nftB)
        internal
        pure
        returns (address nft0, address nft1)
    {
        (nft0, nft1) = nftA < nftB ? (nftA, nftB) : (nftB, nftA);
    }

    function createPool(address nftA, address nftB)
        external
        override
        noDelegateCall
        returns (address pool)
    {
        (address nft0, address nft1) = _sortNFTs(nftA, nftB);

        if (nft0 == address(0)) revert NFTSwapFactory__ZeroAddress();
        if (s_pool[nft0][nft1] != address(0))
            revert NFTSwapFactory__PoolAlreadyExists();

        // deploy pool contract
        pool = address(
            new NFTSwapPool{
                salt: keccak256(abi.encode(address(this), nft0, nft1))
            }(address(this), nft0, nft1)
        );

        s_allPools.push(pool);
        s_pool[nft0][nft1] = pool;

        if (nft0 != nft1) {
            s_pool[nft1][nft0] = pool;
        }

        emit PoolCreated(nft0, nft1, pool);

        return pool;
    }

    function setFeeReceiver(address feeReceiver)
        external
        override
        onlyFeeReceiverSetter
    {
        s_feeReceiver = feeReceiver;
    }

    function setFeeReceiverSetter(address feeReceiverSetter)
        external
        override
        onlyFeeReceiverSetter
    {
        s_feeReceiverSetter = feeReceiverSetter;
    }
}
