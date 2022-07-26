// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./interfaces/INFTSwap.sol";

error NFTSwap__ZeroAddress();

error NFTSwap__ExchangeExists();

error NFTSwap__NonexistentExchange();

error NFTSwap__NotOwner();

error NFTSwap__AlreadyOwnedToken();

error NFTSwap__TransferFromFailed();

error NFTSwap__InvalidTrader();

error NFTSwap__InvalidRecipient();

error NFTSwap__InvalidTokenReceiver();

error NFTSwap__Locked();

contract NFTSwap is INFTSwap {
    uint256 private unlocked = 1;

    Exchange[] private s_allExchanges;

    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => Exchange))))
        private s_exchange;

    modifier lock() {
        if (unlocked == 0) revert NFTSwap__Locked();
        unlocked = 0;
        _;
        unlocked = 1;
    }

    function getAllExchanges()
        external
        view
        override
        returns (Exchange[] memory)
    {
        return s_allExchanges;
    }

    function getExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external view override returns (Exchange memory) {
        return s_exchange[nft0][tokenId0][nft1][tokenId1];
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
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) private {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];
        (nft0, nft1) = nft0 < nft1 ? (nft0, nft1) : (nft1, nft0);

        if (nft0 == address(0)) revert NFTSwap__ZeroAddress();
        if (exchange.owner != address(0)) revert NFTSwap__ExchangeExists();
        if (_getOwnerOf(nft1, tokenId1) == msg.sender)
            revert NFTSwap__AlreadyOwnedToken();

        IERC721(nft0).safeTransferFrom(msg.sender, address(this), tokenId0, "");

        s_allExchanges.push(
            Exchange(msg.sender, trader, nft0, nft1, tokenId0, tokenId1)
        );
        s_exchange[nft0][tokenId0][nft1][tokenId1] = Exchange(
            msg.sender,
            trader,
            nft0,
            nft1,
            tokenId0,
            tokenId1
        );

        emit ExchangeCreated(
            nft0,
            nft1,
            msg.sender,
            trader,
            tokenId0,
            tokenId1
        );
    }

    function createExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        _createExchange(address(0), nft0, nft1, tokenId0, tokenId1);
    }

    function createExchangeFor(
        address trader,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (trader == address(0)) revert NFTSwap__ZeroAddress();
        if (trader == msg.sender || trader == nft0 || trader == nft1)
            revert NFTSwap__InvalidTrader();

        _createExchange(trader, nft0, nft1, tokenId0, tokenId1);
    }

    function trade(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override lock {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (exchange.owner == address(0)) revert NFTSwap__NonexistentExchange();
        if (msg.sender == exchange.owner) revert NFTSwap__InvalidTrader();
        if (exchange.trader != address(0) && msg.sender != exchange.trader)
            revert NFTSwap__InvalidTokenReceiver();

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
        ) revert NFTSwap__TransferFromFailed();

        delete s_exchange[nft0][tokenId0][nft1][tokenId1];

        emit Trade(nft0, nft1, exchange.owner, msg.sender, tokenId0, tokenId1);
    }

    function updateExchangeOwner(
        address newOwner,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (newOwner == address(0)) revert NFTSwap__ZeroAddress();

        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();

        s_exchange[nft0][tokenId0][nft1][tokenId1] = Exchange(
            newOwner,
            exchange.trader,
            nft0,
            nft1,
            exchange.tokenId0,
            exchange.tokenId1
        );

        emit ExchangeOwnerUpdated(
            nft0,
            nft1,
            newOwner,
            exchange.trader,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function updateExchangeTrader(
        address newTrader,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();
        if (newTrader == exchange.owner) revert NFTSwap__InvalidTrader();

        s_exchange[nft0][tokenId0][nft1][tokenId1] = Exchange(
            exchange.owner,
            newTrader,
            nft0,
            nft1,
            exchange.tokenId0,
            exchange.tokenId1
        );

        emit ExchangeTraderUpdated(
            nft0,
            nft1,
            exchange.owner,
            newTrader,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function cancelExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1,
        address recipient
    ) external override {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();
        if (recipient == address(0) || recipient == nft0 || recipient == nft1)
            revert NFTSwap__InvalidRecipient();

        IERC721(nft0).safeTransferFrom(address(this), recipient, tokenId0, "");

        delete s_exchange[nft0][tokenId0][nft1][tokenId1];

        emit ExchangeCancelled(
            nft0,
            nft1,
            exchange.owner,
            exchange.trader,
            recipient,
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
