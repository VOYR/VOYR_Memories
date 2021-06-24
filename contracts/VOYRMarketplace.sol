// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol"; //implem by default in ERC721 - yeh, weird
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./VOYRMemories.sol";




contract VOYRMarketplace is Ownable, IERC721Receiver {

      using SafeMath for uint256;
      VOYRMemories VOYR_Memories;

      event New_listing(address sender, uint256 token_id);
      event New_bid(address sender, uint256 amount);
      event Auction_closed(address seller, address buyer, uint256 token_id, uint256 final_price);
      event Transfer(address to, uint256 value);

      uint8 creator_fee;

      struct auction {
        address seller;
        uint256 min_price;
        uint256 highest_bid;
        uint256 deadline;
        address highest_bidder;
      }

      mapping(uint256 => auction) private current_auctions; //token_id -> Auction
      mapping(address => uint256[]) private auction_by_seller;
      uint256[] private listed_tokens;

      //@dev will only support VOYR_Memories NFTs -> this can be upgraded in future
      //release if needed
      constructor(address VOYR_Memories_address) {
          VOYR_Memories = VOYRMemories(VOYR_Memories_address);
          creator_fee = 1; //in %
      }

      //@dev front-end will have to check isApprovedForAll(sender, marketplace address)
      //and setApprovalForAll(marketplace_addres, true)
      function newAuction(uint256 _token_id, uint256 _min_price, uint256 _deadline) external {
        require(current_auctions[_token_id].deadline == 0, "Ongoing auction");
        auction memory current_new;
        current_new.seller = msg.sender;
        current_new.min_price = _min_price;
        current_new.deadline = _deadline;

        current_auctions[_token_id] = current_new;
        listed_tokens.push(_token_id);
        auction_by_seller[msg.sender].push(_token_id);

        VOYR_Memories.safeTransferFrom(msg.sender, address(this), _token_id);
        emit New_listing(msg.sender, _token_id);
      }


      function newBid(uint256 _token_id) external payable {
        auction memory _current = current_auctions[_token_id];
        require(_current.deadline != 0, "No corresponding auction");
        require(_current.min_price < msg.value && _current.highest_bid < msg.value, "place a higher bid");
        require(_current.deadline >= block.timestamp, "auction expired");

        address prev_bidder = _current.highest_bidder;
        uint256 prev_bid = _current.highest_bid;

        current_auctions[_token_id].highest_bid = msg.value;
        current_auctions[_token_id].highest_bidder = msg.sender;

        safeTransfer(prev_bidder, prev_bid);
        emit New_bid(msg.sender, msg.value);
      }


      function closeSale(uint256 _token_id) external {
        auction memory _current = current_auctions[_token_id];
        require(_current.deadline != 0, "no corresponding auction");
        require(_current.deadline >= block.timestamp, "auction still running");

        address _creator = VOYR_Memories.creator(_token_id);
        uint256 _creator_fee = _current.highest_bid.mul(creator_fee).div(100);

        delete current_auctions[_token_id];

        uint256[] memory _listed_tokens = listed_tokens;
        for (uint i=0; i<_listed_tokens.length; i++) { //O(n) :(
            if (_listed_tokens[i] == _token_id) {
                _listed_tokens[i] = _listed_tokens[_listed_tokens.length-1];
                break;
            }
        }
        listed_tokens = _listed_tokens;
        listed_tokens.pop();

        uint256[] memory current_seller_auctions = auction_by_seller[msg.sender];
        for (uint i=0; i < current_seller_auctions.length; i++) {
          if(current_seller_auctions[i] == _token_id) {
            auction_by_seller[msg.sender][i] = current_seller_auctions[current_seller_auctions.length-1];
            auction_by_seller[msg.sender].pop();
            break;
          }
        }

        uint256 _fee = VOYR_Memories.creatorFee(_token_id);
        if(_fee == 0) {
            _fee = _creator_fee;
        }

        uint256 fee = _fee.mul(_current.highest_bid).div(100);

        VOYR_Memories.safeTransferFrom(address(this), _current.highest_bidder, _token_id);
        safeTransfer(_current.seller, _current.highest_bid.sub(fee));
        safeTransfer(_creator, fee);

        emit Auction_closed(_current.seller, _current.highest_bidder, _token_id, _current.highest_bid);
      }


      function auctionsBySellers(address seller) external view returns(uint256[] memory){
        return auction_by_seller[seller];
      }


      function allAuctions() external view returns(uint256[] memory) {
        return listed_tokens;
      }

      function auctionDetails(uint256 _token_id) external view returns(auction memory) {
        require(current_auctions[_token_id].deadline != 0, "No current auction");
        return current_auctions[_token_id];
      }

      function setCreatorFeePercent(uint8 _new_rate) external onlyOwner {
        creator_fee = _new_rate;
      }

      fallback () external payable {  //fallback. Why are you so generous anyway?
         revert ();
      }

      function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data) public override returns(bytes4) {
        return 0x150b7a02;
      }

       //@dev taken from uniswapV2 TransferHelper lib
       function safeTransfer(address to, uint value) internal {
           (bool success,) = to.call{value:value}(new bytes(0));
           require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
           emit Transfer(to, value);
       }

}
