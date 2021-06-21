// SPDX-License-Identifier: GPL
pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VOYRMemories is ERC721Enumerable, Ownable {

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping (uint256 => string) private _tokenURIs;
    mapping (uint256 => address) private _creator;
    mapping (uint256 => uint256) private _creatorFee; //three mapping since lot of empty values

    string public contract_URI_shop;
    string public _base_uri;

    constructor() ERC721("VOYRMemories", "VMEMO") {
        //see this example of contract_URI, some platform support returning a fee to originator
        contract_URI_shop = ""; //example : https://ipfs.io/ipfs/Qmbqp5hr2i3ug14V7EyR9PYjCSzKnQ272NyT4pTcqkTrGs
        _base_uri = "";
        }

    function mintNFT(address receiver, string memory new_URI, uint256 creator_fee) external returns (uint256){
        _tokenIds.increment();
        uint256 curr_id =  _tokenIds.current();
        _mint(receiver, curr_id);
        _setTokenURI(curr_id, new_URI);
        _creator[curr_id] = msg.sender;
        if(creator_fee != 0) {
            _creatorFee[curr_id] = creator_fee;
        }
        return curr_id;
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

    function setBaseURI(string memory new_base) external onlyOwner {
        _base_uri = new_base;
    }

    function setContractUriShop(string memory new_contract_uri) public onlyOwner {
        contract_URI_shop = new_contract_uri;
    }

    function contractURI() public view returns (string memory) {
        return contract_URI_shop;
    }

    function setCreatorFee(uint256 tokenId, uint256 new_fee) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _creatorFee[tokenId] = new_fee;
    }

    function creatorFee(uint256 token_id) public view returns (uint256) {
        require(_exists(token_id), "ERC721Metadata: nonexistent token");
        return _creatorFee[token_id];
    }


    function withdraw() onlyOwner public {
      uint256 balance = address(this).balance;
      payable(msg.sender).transfer(balance);
    }
}
