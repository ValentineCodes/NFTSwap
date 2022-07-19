// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INFTSwapPool {
    event ExchangeCreated(
        address nft0,
        address nft1,
        address owner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    event ExchangeUpdated(
        address nft0,
        address nft1,
        address owner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    event ExchangeCancelled(
        address nft0,
        address nft1,
        address owner,
        address trader,
        address receiver,
        uint256 tokenId0,
        uint256 tokenId1
    );

    event Trade(
        address nft0,
        address nft1,
        address owner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    struct TokenIdPair {
        uint256 tokenId0;
        uint256 tokenId1;
    }

    struct Exchange {
        address owner;
        address trader;
        uint256 tokenId0;
        uint256 tokenId1;
    }

    function getNFTPair() external view returns (address, address);

    function getAllPairs() external view returns (TokenIdPair[] memory);

    function getExchange(uint256 tokenId0, uint256 tokenId1)
        external
        view
        returns (Exchange memory);

    function createExchange(uint256 token0Id, uint256 token1Id)
        external
        payable;

    function createExchangeFor(
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    ) external payable;

    function trade(uint256 tokenId0, uint256 tokenId1) external payable;

    function updateExchangeOwner(
        address newOwner,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    function updateExchangeTrader(
        address newTrader,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    function cancelExchange(
        uint256 tokenId0,
        uint256 tokenId1,
        address to
    ) external;
}
