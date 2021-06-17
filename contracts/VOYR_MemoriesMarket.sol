// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@OpenZeppelin/contracts/access/Ownable.sol";
import "@OpenZeppelin/contracts/math/SafeMath.sol";
import "@OpenZeppelin/contracts/token/ERC721/IERC721Enumerable.sol"; //implem by default in ERC721 - yeh, weird
import "@OpenZeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@OpenZeppelin/contracts/introspection/ERC165.sol";



contract VOYR_Marketplace is Ownable, IERC721Receiver, ERC165, ERC721Holder {

      using SafeMath for uint256;
      IERC721Enumerable VOYR_Memories;

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
      uint256 private listed_tokens;

      //@dev will only support VOYR_Memories NFTs -> this can be upgraded in future
      //release if needed
      constructor(address VOYR_Memories_address) {
          _registerInterface(IERC721Receiver.onERC721Received.selector);
          VOYR_Memories = IERC721Enumerable(VOYR_Memories_address);
          creator_fee = 1; //in %
      }


      //@dev front-end will have to check isApprovedForAll(sender, marketplace address)
      //and setApprovalForAll(marketplace_addres, true)
      function newAuction(uint256 _token_id, uint256 _min_price, uint256 _deadline) external {
        auction current_new;
        require(_current.deadline == 0, "Ongoing auction");
        current_new.seller = msg.sender;
        current_new.min_price = _min_price;
        current_new.deadline = _deadline;

        current_auctions[_token_id] = current_new;
        listed_tokens.push(_token_id);

        VOYR_Memories.safeTransferFrom(msg.sender, address(this), token_id);
        emit New_listing(msg.sender, _token_id);
      }


      function newBid(uint256 _token_id) external payable {
        auction _current = current_auctions[_token_id];
        require(_current.deadline != 0, "No corresponding auction");
        require(_current.min_price < msg.value && _current.highest_bid < msg.value, "place a higher bid");
        require(_current.deadline >= block.timestamp, "auction expired");

        address prev_bidder = _current.highest_bidder;
        uint256 prev_bid = _current.highest_bid;

        current_auctions[_token_id].highest_bid = msg.value;
        current_auctions[_token_id].highest.bidder = msg.sender;

        safeTransfer(prev_bidder, prev_bid);
        emit New_bid(msg.sender, msg.value);
      }


      function closeSale(uint256 _token_id) external {
        auction _current = current_auctions[_token_id];
        require(_current.deadline != 0, "no corresponding auction");
        require(_current.deadline <= block.timestamp, "auction still running");

        uint256 _creator = VOYR_Memories.creator(_token_id);
        uint256 _creator_fee = _current.highest_bid.mul(creator_fee).div(100);

        delete current_auctions[_token_id];

        for (uint i=0; i< listed_tokens.length; i++) { //O(n) :(
            if (listed_tokens[i] == _token_id) {
                listed_tokens[i] = listed_tokens[listed_tokens.length-1];
                listed_tokens[listed_tokens.length-1].pop();
                break;
            }
        }

        VOYR_Memories.safeTransfer(_current.highest_bidder, token_id);
        safeTransfer(_current.seller, _current.highest_bid.sub(_creator_fee));
        safeTransfer(_creator, _creator_fee);

        emit Auction_closed(_current.seller, _current.highest_bidder, _token_id, _current._highest_bid);
      }


      //@dev 0 gas if called by user - watchout for gas from other contract
      function auctionsBySellers(address seller) external view returns(uint256[] memory){
        uint256[] memory auctions_by_seller = new uint256[]

        for(uint256 i = 0; i<listed_tokens.length; i++) {
            if(current_auctions[i].seller == msg.sender) {
              auctions_by_seller.push(i);
            }
        }
        return auctions_by_seller;
      }


      function allAuctions() external view returns(uint256[]) {
        return listed_tokens;
      }

      function auctionsDetails(uint256 _token_id) external view returns(uint256) {
        require(current_auctions[_token_id].min_price != 0, "No current auction");
        return current_auctions[_token_id];
      }

      function setCreatorFeePercent(uint8 _new_rate) external onlyOwner {
        creator_fee = _new_rate;
      }

      fallback () external payable {  //fallback. Why are you so generous anyway?
         revert () ;}

       //@dev taken from uniswapV2 TransferHelper lib
       function safeTransferETH(address to, uint value) internal {
           (bool success,) = to.call{value:value}(new bytes(0));
           require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
           emit Transfer(to, value);
       }

}
