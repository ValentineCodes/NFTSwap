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

error NFTSwap__NotExchangeTrader();

error NFTSwap__RecipientCannotBeTrader();

error NFTSwap__Locked();

contract NFTSwap is INFTSwap {
    uint256 private unlocked = 1;

    Exchange[] private s_allExchanges;

    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => Exchange))))
        private s_exchange;

    mapping(address => Exchange[]) private s_ownerToExchanges;

    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256[]))))
        private s_exchangeIndexes;

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

    function getOwnerExchanges(address owner)
        external
        view
        override
        returns (Exchange[] memory)
    {
        return s_ownerToExchanges[owner];
    }

    function createExchange(
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        _createExchange(address(0), recipient, nft0, nft1, tokenId0, tokenId1);
    }

    function createExchangeFor(
        address trader,
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (trader == address(0)) revert NFTSwap__ZeroAddress();
        if (trader == msg.sender || trader == nft0 || trader == nft1)
            revert NFTSwap__InvalidTrader();

        _createExchange(trader, recipient, nft0, nft1, tokenId0, tokenId1);
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
            revert NFTSwap__NotExchangeTrader();

        IERC721(nft0).safeTransferFrom(address(this), msg.sender, tokenId0, "");
        IERC721(nft1).safeTransferFrom(
            msg.sender,
            exchange.recipient,
            tokenId1,
            ""
        );

        if (
            _getOwnerOf(nft0, tokenId0) != msg.sender &&
            _getOwnerOf(nft1, tokenId1) != exchange.recipient
        ) revert NFTSwap__TransferFromFailed();

        _deleteExchange(nft0, nft1, tokenId0, tokenId1);

        emit Trade(
            nft0,
            nft1,
            exchange.owner,
            msg.sender,
            exchange.recipient,
            tokenId0,
            tokenId1
        );
    }

    function updateExchangeRecipient(
        address newRecipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        if (newRecipient == address(0)) revert NFTSwap__ZeroAddress();

        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();

        s_exchange[nft0][tokenId0][nft1][tokenId1].recipient = newRecipient;

        emit ExchangeOwnerUpdated(
            nft0,
            nft1,
            exchange.owner,
            exchange.trader,
            newRecipient,
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

        s_exchange[nft0][tokenId0][nft1][tokenId1].trader = newTrader;

        emit ExchangeTraderUpdated(
            nft0,
            nft1,
            exchange.owner,
            newTrader,
            exchange.recipient,
            exchange.tokenId0,
            exchange.tokenId1
        );
    }

    function cancelExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) external override {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];

        if (msg.sender != exchange.owner) revert NFTSwap__NotOwner();

        IERC721(nft0).safeTransferFrom(
            address(this),
            exchange.recipient,
            tokenId0,
            ""
        );

        _deleteExchange(nft0, nft1, tokenId0, tokenId1);

        emit ExchangeCancelled(
            nft0,
            nft1,
            exchange.owner,
            exchange.trader,
            exchange.recipient,
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

    function _getOwnerOf(address nft, uint256 tokenId)
        private
        view
        returns (address)
    {
        return IERC721(nft).ownerOf(tokenId);
    }

    function _createExchange(
        address trader,
        address recipient,
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) private {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];
        (nft0, nft1) = nft0 < nft1 ? (nft0, nft1) : (nft1, nft0);

        if (nft0 == address(0) || recipient == address(0))
            revert NFTSwap__ZeroAddress();

        if (exchange.owner != address(0)) revert NFTSwap__ExchangeExists();

        if (_getOwnerOf(nft1, tokenId1) == msg.sender)
            revert NFTSwap__AlreadyOwnedToken();

        if (recipient == trader) revert NFTSwap__RecipientCannotBeTrader();

        IERC721(nft0).safeTransferFrom(msg.sender, address(this), tokenId0, "");

        uint256 allExchangesIndex = s_allExchanges.length;
        uint256 ownerExchangesIndex = s_ownerToExchanges[msg.sender].length;

        s_exchangeIndexes[nft0][tokenId0][nft1][tokenId1] = [
            allExchangesIndex,
            ownerExchangesIndex
        ];
        s_allExchanges.push(
            Exchange(
                msg.sender,
                trader,
                recipient,
                nft0,
                nft1,
                tokenId0,
                tokenId1
            )
        );
        s_exchange[nft0][tokenId0][nft1][tokenId1] = Exchange(
            msg.sender,
            trader,
            recipient,
            nft0,
            nft1,
            tokenId0,
            tokenId1
        );
        s_ownerToExchanges[msg.sender].push(
            Exchange(
                msg.sender,
                trader,
                recipient,
                nft0,
                nft1,
                tokenId0,
                tokenId1
            )
        );

        emit ExchangeCreated(
            nft0,
            nft1,
            msg.sender,
            trader,
            recipient,
            tokenId0,
            tokenId1
        );
    }

    function _deleteExchange(
        address nft0,
        address nft1,
        uint256 tokenId0,
        uint256 tokenId1
    ) private {
        Exchange memory exchange = s_exchange[nft0][tokenId0][nft1][tokenId1];
        uint256[] memory indexes = s_exchangeIndexes[nft0][tokenId0][nft1][
            tokenId1
        ];
        Exchange[] memory allExchanges = s_allExchanges;
        Exchange[] memory ownerExchanges = s_ownerToExchanges[exchange.owner];

        delete s_exchangeIndexes[nft0][tokenId0][nft1][tokenId1];

        uint256 lastIndexOfAllExchanges = allExchanges.length - 1;
        uint256 lastIndexOfOwnerExchanges = ownerExchanges.length - 1;
        Exchange memory lastExchange;

        // Swap the index of the last exchange in the list with the index of the exchange to remove
        if (indexes[0] < lastIndexOfAllExchanges) {
            lastExchange = allExchanges[lastIndexOfAllExchanges];
            s_allExchanges[indexes[0]] = lastExchange;
            s_exchangeIndexes[lastExchange.nft0][lastExchange.tokenId0][
                lastExchange.nft1
            ][lastExchange.tokenId1][0] = indexes[0];
        }
        if (indexes[1] < lastIndexOfOwnerExchanges) {
            lastExchange = allExchanges[lastIndexOfOwnerExchanges];
            s_allExchanges[indexes[1]] = lastExchange;
            s_exchangeIndexes[lastExchange.nft0][lastExchange.tokenId0][
                lastExchange.nft1
            ][lastExchange.tokenId1][1] = indexes[1];
        }

        s_allExchanges.pop();
        s_ownerToExchanges[exchange.owner].pop();
        delete s_exchange[nft0][tokenId0][nft1][tokenId1];
    }
}
