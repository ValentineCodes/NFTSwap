// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The NFT swap pool interface
/// @notice Creates and updates exchanges for trades
interface INFTSwapPool {
    /// @notice Emitted when an exchanged is created
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner. Owner initialized as the exchange creator
    /// @param trader The address of the exchange trader. Trader is the zero address if emitted from createExchange()
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeCreated(
        address nft0,
        address nft1,
        address owner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when an exchanged owner is updated
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param newOwner The address of the new exchange owner
    /// @param trader The address of the exchange trader
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeOwnerUpdated(
        address nft0,
        address nft1,
        address newOwner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when an exchanged trader is updated
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner
    /// @param newTrader The address of the new exchange trader
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeTraderUpdated(
        address nft0,
        address nft1,
        address owner,
        address newTrader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when an exchange is cancelled
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner
    /// @param trader The address of the exchange trader
    /// @param receiver The NFT receiver
    /// @param tokenId0 The token id of {nft0} to be exchanged by the owner
    /// @param tokenId1 The token id of {nft1} to be received from trades
    event ExchangeCancelled(
        address nft0,
        address nft1,
        address owner,
        address trader,
        address receiver,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Emitted when a trade occurs
    /// @param nft0 The address of the first NFT
    /// @param nft1 The address of the second NFT
    /// @param owner The address of the exchange owner
    /// @param trader The address of the trader
    /// @param tokenId0 The token id of {nft0} received
    /// @param tokenId1 The token id of {nft1} traded
    event Trade(
        address nft0,
        address nft1,
        address owner,
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    );

    /// @notice Data model for token id pairs
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param tokenId0 The token id of {nft0} to be traded by exchange owner
    /// @param tokenId1 The token id of {nft1} to be received by exchange owner
    struct TokenIdPair {
        uint256 tokenId0;
        uint256 tokenId1;
    }

    /// @notice Data model for exchanges
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param owner Address of exchange owner
    /// @param trader Address of trader. Can be set to zero address to allow all traders
    /// @param tokenId0 The token id of {nft0} to be traded by exchange owner
    /// @param tokenId1 The token id of {nft1} to be received by exchange owner
    struct Exchange {
        address owner;
        address trader;
        uint256 tokenId0;
        uint256 tokenId1;
    }

    /// @notice Retreives the NFT pair
    /// @return Array of NFT addresses
    function getNFTPair() external view returns (address, address);

    /// @notice Retrieves all token id pairs
    /// @return Array of token id pairs
    function getAllPairs() external view returns (TokenIdPair[] memory);

    /// @notice Retreives exchange data of token id pairs
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param tokenId0 Token id of {nft0} to be traded by exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    /// @return Exchange data (see Exchange struct for data model)
    function getExchange(uint256 tokenId0, uint256 tokenId1)
        external
        view
        returns (Exchange memory);

    /// @notice Creates an exchange with tokenId0 for tokenId1 that can be traded by anyone
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function createExchange(uint256 tokenId0, uint256 tokenId1) external;

    /// @notice Creates an exchange with tokenId0 for tokenId1 that can be traded by a specific trader
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param trader Address of trader of the token requested
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function createExchangeFor(
        address trader,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Trades tokenId1 for tokenId0
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param tokenId0 Token id of {nft0} to be received by trader
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function trade(uint256 tokenId0, uint256 tokenId1) external;

    /// @notice Updates exchange owner
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param newOwner Address of the new owner
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function updateExchangeOwner(
        address newOwner,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Updates exchange trader
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param newTrader Address of the new trader. Can be set to the zero address to allow all traders to trade
    /// @param tokenId0 Token id of {nft0} to be traded by the exchange owner
    /// @param tokenId1 Token id of {nft1} requested by the exchange owner
    function updateExchangeTrader(
        address newTrader,
        uint256 tokenId0,
        uint256 tokenId1
    ) external;

    /// @notice Cancels exchange and sends tokenId0 to {to}
    /// @dev tokenId0 and tokenId1 must be in order
    /// @param tokenId0 Token id of {nft0}
    /// @param tokenId1 Token id of {nft1}
    /// @param to Address of the receiver of tokenId0
    function cancelExchange(
        uint256 tokenId0,
        uint256 tokenId1,
        address to
    ) external;
}
