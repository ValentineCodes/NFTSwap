// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFTMock is ERC721 {
    constructor(address[3] memory owners) ERC721("NFTMock", "NFT") {
        for (uint256 index = 0; index < owners.length; index++) {
            _safeMint(owners[index], index);
        }

        _safeMint(owners[0], 4);
    }
}
