// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VOYRMemories is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => string) private _tokenURIs;
    mapping (uint256 => address) private _creator;

    string public contract_URI_shop;
    string public _base_uri;

    constructor() ERC721("VOYRMemories", "VMEMO") {
        //see this example of contract_URI, some platform support returning a fee to originator
        contract_URI_shop = ""; //example : https://ipfs.io/ipfs/Qmbqp5hr2i3ug14V7EyR9PYjCSzKnQ272NyT4pTcqkTrGs
        _base_uri = "";
        }

    function mintNFT(address receiver, string memory new_URI) external {
        _tokenIds.increment();
        _mint(receiver, _tokenIds.current());
        _setTokenURI(_tokenIds.current(), new_URI);
        _creator[_tokenIds.current()] = msg.sender;
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 token_id) public view override returns (string memory) {
        require(_exists(token_id), "ERC721Metadata: nonexistent token");
        return string(abi.encodePacked(_base_uri, _tokenURIs[token_id]));
    }

    function creator(uint256 token_id) external view returns (address) {
        require(_exists(token_id), "ERC721Metadata: nonexistent token");
        return _creator[token_id];
    }

    function setContractUriShop(string memory new_contract_uri) public onlyOwner {
        contract_URI_shop = new_contract_uri;
    }

    function setBaseURI(string memory new_base) external onlyOwner {
        _base_uri = new_base;
    }

    function contractURI() public view returns (string memory) {
        return contract_URI_shop;
    }

    function withdraw() onlyOwner public {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
}
