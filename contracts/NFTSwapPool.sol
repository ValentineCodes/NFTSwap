// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
// import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "./interfaces/INFTSwapPool.sol";
import "./interfaces/INFTSwapFactory.sol";

// import "./libraries/PriceConverter.sol";

error NFTSwapPool__ZeroAddress();

error NFTSwapPool__TokenPairNotFound();

error NFTSwapPool__ExchangeExists();

error NFTSwapPool__NonexistentExchange();

error NFTSwapPool__NotOwner();

error NFTSwapPool__AlreadyOwnedToken();

error NFTSwapPool__TransferFromFailed();

error NFTSwapPool__InvalidTrader();

error NFTSwapPool__InvalidTo();

error NFTSwapPool__PriceOutOfRange();

error NFTSwapPool__InvalidTokenReceiver();

error NFTSwapPool__InsufficientFee();

error NFTSwapFactory__FeeTransferFailed();

contract NFTSwapPool is INFTSwapPool {
    // using PriceConverter for uint256;

    uint256 private constant MINIMUM_FEE = 1 * 10**18; // in USD

    address private immutable i_nft0;
    address private immutable i_nft1;

    INFTSwapFactory private immutable s_factory;
    // AggregatorV3Interface private immutable s_priceFeed;

    TokenIdPair[] private s_allPairs;

    mapping(uint256 => mapping(uint256 => Exchange)) private s_exchange;

    constructor(
        address factory,
        address nft0,
        address nft1
    ) {
        s_factory = INFTSwapFactory(factory);
        i_nft0 = nft0;
        i_nft1 = nft1;
        // s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function getNFTPair() external view override returns (address, address) {
        return (i_nft0, i_nft1);
    }

    function getAllPairs()
        external
        view
        override
        returns (TokenIdPair[] memory)
    {
        return s_allPairs;
    }

    function getExchange(uint256 tokenId0, uint256 tokenId1)
        external
        view
        override
        returns (Exchange memory)
    {
        return s_exchange[tokenId0][tokenId1];
    }

    function _getOwnerOf(address nft, uint256 tokenId)
        private
        view
        returns (address)
    {
        return IERC721(nft).ownerOf(tokenId);
    }

    function _createExchange(
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    ) private {
        Exchange memory exchange = s_exchange[tokenId0][tokenId1];
        (address nft0, address nft1) = (i_nft0, i_nft1);

        if (exchange.owner != address(0)) revert NFTSwapPool__ExchangeExists();
        if (trader == msg.sender || trader == nft0 || trader == nft1)
            revert NFTSwapPool__InvalidTrader();

        if (_getOwnerOf(nft1, tokenId1) == msg.sender)
            revert NFTSwapPool__AlreadyOwnedToken();

        IERC721(nft0).safeTransferFrom(msg.sender, address(this), tokenId0, "");

        s_allPairs.push(TokenIdPair(tokenId0, tokenId1));
        s_exchange[tokenId0][tokenId1] = Exchange(
            msg.sender,
            trader,
            tokenId0,
            tokenId1
        );

        // (bool success, ) = payable(s_factory.getFeeReceiver()).call{
        //     value: msg.value
        // }("");

        // if (!success) revert NFTSwapFactory__FeeTransferFailed();

        emit ExchangeCreated(
            nft0,
            nft1,
            msg.sender,
            trader,
            tokenId0,
            tokenId1
        );
    }

    // TO-DO: Handle price range
    function createExchange(uint256 tokenId0, uint256 tokenId1)
        external
        override
    {
        // if (msg.value.toUSD(s_priceFeed) < 1)
        //     revert NFTSwapPool__InsufficientFee();

        _createExchange(address(0), tokenId0, tokenId1);
    }

    function createExchangeFor(
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (trader == address(0)) revert NFTSwapPool__ZeroAddress();

        // if (msg.value.toUSD(s_priceFeed) < 1)
        //     revert NFTSwapPool__InsufficientFee();

        _createExchange(trader, tokenId0, tokenId1);
    }

    function trade(uint256 tokenId0, uint256 tokenId1) external override {
        Exchange memory exchange = s_exchange[tokenId0][tokenId1];
        (address nft0, address nft1) = (i_nft0, i_nft1);

        // if (msg.value.toUSD(s_priceFeed) < 1)
        //     revert NFTSwapPool__InsufficientFee();

        if (exchange.owner == address(0))
            revert NFTSwapPool__NonexistentExchange();

        if (msg.sender == exchange.owner) revert NFTSwapPool__InvalidTrader();

        if (exchange.trader != address(0) && msg.sender != exchange.trader)
            revert NFTSwapPool__InvalidTokenReceiver();

        IERC721(nft0).safeTransferFrom(address(this), msg.sender, tokenId0, "");
        IERC721(nft1).safeTransferFrom(
            msg.sender,
            exchange.owner,
            tokenId1,
            ""
        );

        if (
            _getOwnerOf(nft0, tokenId0) != msg.sender &&
            _getOwnerOf(nft1, tokenId1) != exchange.owner
        ) revert NFTSwapPool__TransferFromFailed();

        // (bool success, ) = payable(s_factory.getFeeReceiver()).call{
        //     value: msg.value
        // }("");

        // if (!success) revert NFTSwapFactory__FeeTransferFailed();

        delete s_exchange[tokenId0][tokenId1];

        emit Trade(nft0, nft1, exchange.owner, msg.sender, tokenId0, tokenId1);
    }

    function updateExchangeOwner(
        address newOwner,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (newOwner == address(0)) revert NFTSwapPool__ZeroAddress();

        Exchange memory exchange = s_exchange[tokenId0][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwapPool__NotOwner();

        s_exchange[tokenId0][tokenId1] = Exchange(
            newOwner,
            exchange.trader,
            exchange.tokenId0,
            exchange.tokenId1
        );

        emit ExchangeUpdated(
            i_nft0,
            i_nft1,
            newOwner,
            exchange.trader,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function updateExchangeTrader(
        address newTrader,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        Exchange memory exchange = s_exchange[tokenId0][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwapPool__NotOwner();
        if (newTrader == exchange.owner) revert NFTSwapPool__InvalidTrader();

        s_exchange[tokenId0][tokenId1] = Exchange(
            exchange.owner,
            newTrader,
            exchange.tokenId0,
            exchange.tokenId1
        );

        emit ExchangeUpdated(
            i_nft0,
            i_nft1,
            exchange.owner,
            newTrader,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function cancelExchange(
        uint256 tokenId0,
        uint256 tokenId1,
        address to
    ) external override {
        Exchange memory exchange = s_exchange[tokenId0][tokenId1];
        (address nft0, address nft1) = (i_nft0, i_nft1);

        if (msg.sender != exchange.owner) revert NFTSwapPool__NotOwner();
        if (to == address(0) || to == nft0 || to == nft1)
            revert NFTSwapPool__InvalidTo();

        IERC721(nft0).safeTransferFrom(address(this), to, tokenId0, "");

        delete s_exchange[tokenId0][tokenId1];

        emit ExchangeCancelled(
            nft0,
            nft1,
            exchange.owner,
            exchange.trader,
            to,
            tokenId0,
            tokenId1
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
