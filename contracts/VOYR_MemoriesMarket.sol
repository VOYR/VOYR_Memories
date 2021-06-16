// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


import "@OpenZeppelin/contracts/access/Ownable.sol";
import "@OpenZeppelin/contracts/math/SafeMath.sol";
import "@OpenZeppelin/contracts/token/ERC721/IERC721Enumerable.sol";
import "@OpenZeppelin/contracts/token/ERC721/ERC721Holder.sol";
import "@OpenZeppelin/contracts/introspection/ERC165.sol";



contract stake_anz is Ownable, IERC721Receiver, ERC165, ERC721Holder{
  using SafeMath for uint256;

      bool public allow_staking;
      uint256[] public rate;  //0 -> base rate; 1 -> coef for 1 extra NFT staked, etc -> not defined=linear decay?
      //rate array allows doing really fun stuff -> if you stake 5 token, get extra rate on this one, etc
      address public approved_shop;
      IERC721Enumerable main_anonz;

      event Staking_deposit(address sender, uint token_id);
      event Init_stacking(address sender);
      event Stacking_retrieval(address sender, uint token_id, uint reward);
      event New_shop(address sender, address shop_contract);

      struct Struct_token {
          uint256 puzzles;
          uint256 lastRewardTimestamp;
      }

      mapping(uint256 => Struct_token) private tokens_carac;

      mapping(address => uint256[]) private staked_tokens;

      mapping(uint256 => address) private token_owners;

      modifier onlyShop() {
        require(msg.sender == approved_shop, "only the shop contract can spend PZL");
        _;
      }

      modifier stakingActive() {
          require(allow_staking==true, "staking inactive");
          _;
      }

      constructor() {
          rate.push(1); //by default, same rate for multi-stacking.
          _registerInterface(IERC721Receiver.onERC721Received.selector);
      }

      function start(address main_contract) public onlyOwner {
          require(allow_staking == false, "Staking already active");
          allow_staking = true;
          main_anonz = IERC721Enumerable(main_contract);
          emit Init_stacking(main_contract);
      }

      function stop() public onlyOwner stakingActive {
          allow_staking = false;
      }

      function set_shop(address shop_contract) public onlyOwner {
          approved_shop = shop_contract;
          emit New_shop(msg.sender, approved_shop);
      }

      function stake(uint256 token_id) public stakingActive {
        main_anonz.safeTransferFrom(msg.sender, address(this), token_id);
        //will reverse if staking someone's else token or if already staked

        staked_tokens[msg.sender].push(token_id);
        tokens_carac[token_id].lastRewardTimestamp = block.timestamp;
        token_owners[token_id] = msg.sender;
        emit Staking_deposit(msg.sender, token_id);
      }

      function get_staked() public view returns (uint256[] memory) {
          return staked_tokens[msg.sender];
      }

      function update_reward() public {

          uint256[] memory owner_tokens = get_staked();
          uint nb_tokens = owner_tokens.length;
          uint nb_rates = rate.length;

          for (uint i=0; i<nb_tokens; i++) {

            uint256 delta = block.timestamp.sub(tokens_carac[owner_tokens[i]].lastRewardTimestamp);

            if(delta==0) {
                break;
            }

            if (i>=nb_rates) {  //undefined rate for that n-th tokens -> use last one in rate array (rate fwd propagation)
                tokens_carac[owner_tokens[i]].puzzles = tokens_carac[owner_tokens[i]].puzzles.add(delta * rate[nb_rates-1]);
            }
            else {
                tokens_carac[owner_tokens[i]].puzzles = tokens_carac[owner_tokens[i]].puzzles.add(delta * rate[i]);
            }

            tokens_carac[owner_tokens[i]].lastRewardTimestamp = block.timestamp;
          }

      }


      function unstake(uint256 token_id) public {
        require(token_owners[token_id] == msg.sender, "cannot unstake tokens not owned");

        main_anonz.safeTransferFrom(address(this), token_owners[token_id], token_id);

        update_reward(); //last reward update
        uint256[] memory owner_tokens = get_staked();
        uint nb_tokens = owner_tokens.length;

        for (uint i=0; i< nb_tokens; i++) { //alternative would have been another mapping - similar gaz
            if (owner_tokens[i] == token_id) {
                tokens_carac[owner_tokens[i]].lastRewardTimestamp = 0; //for when re-staking - keep puzzle balance!
                staked_tokens[msg.sender][i] = staked_tokens[msg.sender][nb_tokens-1]; //no order needed -> swap&delete
                staked_tokens[msg.sender].pop();
                delete token_owners[token_id];//we used to save gaz with this, in the good ol' days
                break;
            }
        }
      }

      function get_pzl_balance() view public returns (uint256) {//public -> UI use
          uint256 total = get_reward(); //stake token are in stake_contract...
          uint balance_tot = main_anonz.balanceOf(msg.sender);
          for (uint i=0; i<balance_tot; i++) { //...while unstaked are in sender's wallet
            total += tokens_carac[main_anonz.tokenOfOwnerByIndex(msg.sender, i)].puzzles;
          }
          return total;
      }

      function pzl_balance_by_token(uint256 token_id) view public returns (uint256) { //public -> UI use
          require(token_owners[token_id] == address(0), "Unstake first");
          return tokens_carac[token_id].puzzles;
      }

      function burn(uint256 token_id, uint256 amount) public onlyShop { //total pzl by owner (summing tokens) is determined in shop contract
        update_reward();
        require(tokens_carac[token_id].puzzles >= amount, "Not enough PZL");
        tokens_carac[token_id].puzzles = tokens_carac[token_id].puzzles.sub(amount);
      }

      function get_reward() public view returns (uint256) {
          uint256[] memory owner_tokens = get_staked();
          uint256 nb_tokens = owner_tokens.length; //1
          uint256 nb_rates = rate.length; //1
          uint256 total = 0;

          for (uint i=0; i<nb_tokens; i++) {
            uint256 delta = block.timestamp-tokens_carac[owner_tokens[i]].lastRewardTimestamp;

            if (i>=nb_rates) {  //undefined rate for that much tokens -> use last one in rate array
                total = total.add(tokens_carac[owner_tokens[i]].puzzles + (delta * rate[nb_rates-1]));
            }
            else {
                total = total.add(tokens_carac[owner_tokens[i]].puzzles + (delta * rate[i]));
            }
          }

        return total;
      }


      fallback () external payable {  //fallback. Why are you so generous anyway?
         revert () ;}

      function is_stacked(uint256 token_id) public view returns (bool) {
          return (token_owners[token_id] != address(0));
      }

    function is_approved() public view returns (bool) {  //use main contract via web3 instead (gaz) - backup for "testing in prod"
        return main_anonz.isApprovedForAll(address(this), msg.sender);
    }

}
