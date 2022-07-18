// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface INFTSwapPool {
    event ExchangeCreated(
        address nft0,
        address nft1,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1,
        uint256 minPrice,
        uint256 maxPrice
    );

    event ExchangeCancelled(
        address nft0,
        address nft1,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1,
        uint256 minPrice,
        uint256 maxPrice
    );

    event Trade(
        address nft0,
        address nft1,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1,
        uint256 minPrice,
        uint256 maxPrice
    );

    struct TokenIdPair {
        uint256 tokenId0;
        uint256 tokenId1;
        uint256 minPrice;
        uint256 maxPrice;
    }

    struct Exchange {
        address owner;
        address trader;
        uint256 tokenId0;
        uint256 tokenId1;
        uint256 minPrice;
        uint256 maxPrice;
    }

    function getNFTPair() external view returns (address, address);

    function getAllPairs() external view returns (TokenIdPair[] memory);

    function getExchange(uint256 tokenId0, uint256 tokenId1)
        external
        view
        returns (Exchange memory);

    function createExchange(
        uint256 token0Id,
        uint256 token1Id,
        uint256[] calldata priceRange,
        address trader
    ) external;

    function createExchangeFor(
        address trader,
        uint256 tokenId0,
        uint256 tokenId1,
        uint256[2] calldata priceRange
    ) external;

    function trade(uint256 tokenId0, uint256 tokenId1) external;

    function claimTrade(uint256 tokenId0, uint256 tokenId1) external;
}
