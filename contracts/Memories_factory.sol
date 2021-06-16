// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";
    import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract VOYRMemories is ERC721, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => string) private _tokenURIs;

    string public contract_URI_shop;

    constructor() ERC721("VOYRMemories", "VMEMO") {
        _setBaseURI("");
        //see this example of contract_URI, some platform support returning a fee to originator
        contract_URI_shop = "https://ipfs.io/ipfs/Qmbqp5hr2i3ug14V7EyR9PYjCSzKnQ272NyT4pTcqkTrGs";
        }

    function mintNFT(address receiver, string memory new_URI) external {
        _tokenIds.increment();
        _mint(receiver, _tokenIds.current());
        _setTokenURI(_tokenIds.current(), new_URI);
        }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function tokenURI(uint256 token_id) external view override returns (string memory) {
        require(_exists(token_id), "ERC721Metadata: nonexistent token");
        return abi.encodePacked(_baseURI, _tokenURIs[tokenId]);
    }

    function setContractUriShop(string memory new_contract_uri) public onlyOwner {
        contract_URI_shop = new_contract_uri;
    }

    function setBaseURI(string memory new_base) external onlyOwner {
        _setBaseURI(new_base);
    }

    function contractURI() public view returns (string memory) {
        return contract_URI_shop;
    }

    function withdraw() onlyOwner public {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
}
