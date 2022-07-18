// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import "./interfaces/INFTSwapPool.sol";

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

error NFTSwapPool__InvalidTradeClaimer();

abstract contract NFTSwapPool is INFTSwapPool, IERC721Receiver {
    address private immutable i_factory;

    address private immutable i_nft0;

    address private immutable i_nft1;

    TokenIdPair[] private s_allPairs;

    mapping(uint256 => mapping(uint256 => Exchange)) private s_exchange;

    constructor(
        address factory,
        address nft0,
        address nft1
    ) {
        i_factory = factory;
        i_nft0 = nft0;
        i_nft1 = nft1;
    }

    function getNFTPair() public view override returns (address, address) {
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
        public
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

    function _safeTransferFrom(
        address nft,
        address from,
        address to,
        uint256 tokenId
    ) private view {
        bytes4 selector = bytes4(
            keccak256(
                abi.encode(
                    "safeTransferFrom(address from,address to,uint256 tokenId)"
                )
            )
        );
        (bool success, bytes memory data) = nft.staticcall(
            abi.encodeWithSelector(selector, from, to, tokenId)
        );
        if (!success && (data.length != 0 || abi.decode(data, (bool))))
            revert NFTSwapPool__TransferFromFailed();
    }

    function _createExchange(
        address owner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1,
        uint256 minPrice,
        uint256 maxPrice
    ) private {
        Exchange memory exchange = getExchange(tokenId0, tokenId1);
        (address nft0, address nft1) = getNFTPair();

        if (exchange.owner != address(0)) revert NFTSwapPool__ExchangeExists();
        if (trader == owner || trader == nft0 || trader == nft1)
            revert NFTSwapPool__InvalidTrader();

        if (_getOwnerOf(nft0, tokenId0) != owner)
            revert NFTSwapPool__NotOwner();
        if (_getOwnerOf(nft1, tokenId1) == owner)
            revert NFTSwapPool__AlreadyOwnedToken();

        // TO-DO: Approve pool contract to spend token

        _safeTransferFrom(nft0, owner, address(this), tokenId0);

        s_allPairs.push(TokenIdPair(tokenId0, tokenId1, minPrice, maxPrice));
        s_exchange[tokenId0][tokenId1] = Exchange(
            msg.sender,
            trader,
            tokenId0,
            tokenId1,
            minPrice,
            maxPrice
        );

        emit ExchangeCreated(
            nft0,
            nft1,
            trader,
            tokenId0,
            tokenId1,
            minPrice,
            maxPrice
        );
    }

    // TO-DO: Handle price range
    function createExchange(
        uint256 tokenId0,
        uint256 tokenId1,
        uint256 minPrice,
        uint256 maxPrice
    ) external {
        _createExchange(
            msg.sender,
            address(0),
            tokenId0,
            tokenId1,
            minPrice,
            maxPrice
        );
    }

    function createExchangeFor(
        address trader,
        uint256 tokenId0,
        uint256 tokenId1,
        uint256 minPrice,
        uint256 maxPrice
    ) external {
        _createExchange(
            msg.sender,
            trader,
            tokenId0,
            tokenId1,
            minPrice,
            maxPrice
        );
    }

    function trade(uint256 tokenId0, uint256 tokenId1) external override {
        Exchange memory exchange = getExchange(tokenId0, tokenId1);
        (address nft0, address nft1) = getNFTPair();

        if (exchange.owner == address(0))
            revert NFTSwapPool__NonexistentExchange();
        if (msg.sender == exchange.owner) revert NFTSwapPool__InvalidTrader();

        if (_getOwnerOf(nft1, tokenId1) != msg.sender)
            revert NFTSwapPool__NotOwner();

        // TO-DO: Approve pool contract to spend token

        if (exchange.trader != address(0) && msg.sender != exchange.trader)
            revert NFTSwapPool__InvalidTradeClaimer();

        _safeTransferFrom(nft0, address(this), msg.sender, tokenId0);

        _safeTransferFrom(nft1, msg.sender, exchange.owner, tokenId1);

        if (
            _getOwnerOf(nft0, tokenId0) != msg.sender &&
            _getOwnerOf(nft1, tokenId1) != exchange.owner
        ) revert NFTSwapPool__TransferFromFailed();

        delete s_exchange[tokenId0][tokenId1];

        emit Trade(
            nft0,
            nft1,
            msg.sender,
            tokenId0,
            tokenId1,
            exchange.minPrice,
            exchange.maxPrice
        );
    }

    function cancelExchange(
        uint256 tokenId0,
        uint256 tokenId1,
        address to
    ) external {
        Exchange memory exchange = getExchange(tokenId0, tokenId1);
        (address nft0, address nft1) = getNFTPair();

        if (msg.sender != exchange.owner) revert NFTSwapPool__NotOwner();
        if (to == nft0 || to == nft1) revert NFTSwapPool__InvalidTo();

        _safeTransferFrom(nft0, address(this), msg.sender, tokenId0);

        delete s_exchange[tokenId0][tokenId1];

        emit ExchangeCancelled(
            nft0,
            nft1,
            exchange.trader,
            tokenId0,
            tokenId1,
            exchange.minPrice,
            exchange.maxPrice
        );
    }

    // function cancelExchange() external {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
