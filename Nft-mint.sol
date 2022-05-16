//For 1000usd equivalent ether according to market price.
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts@4.6.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.6.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.6.0/security/Pausable.sol";
import "@openzeppelin/contracts@4.6.0/access/AccessControl.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Counters.sol";

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Aiverse is ERC721, ERC721Enumerable, ERC721URIStorage, Pausable, AccessControl {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds; 

    AggregatorV3Interface internal priceFeed;
    mapping(address=>uint) public contributors;
    uint256 public totalsupply = 35;
    address public admin;
    uint public noOfContributors;
    uint public totalAmount;
    uint256 public constant mintprice = 1000;
    uint public decimals = 18;

    constructor() ERC721("aiverse", "AVS") {
        priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        admin=msg.sender;
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(PAUSER_ROLE, admin);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function getlatestprice() public view returns(int256){
        (, int256 answer , , , ) = priceFeed.latestRoundData();
        return int256(answer*10**10); //in wei 18 decimal

    }

    function getPriceRate() public view returns (uint) {
        (, int price,,,) = priceFeed.latestRoundData();
        uint adjust_price = uint(price) * 1e10;
        uint usd = mintprice * 1e18;
        uint rate = (usd * 1e18) / adjust_price;
        return rate;
    }



    
    function safeMint(address payable to, string memory tokenURi)
        public virtual payable
    {
        require(msg.value == getPriceRate(), "Not enough ETH sent; check price!");

        if(contributors[msg.sender]==0){
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        totalAmount+=msg.value;

        require(contributors[msg.sender]>=msg.value , "Amount not payed");
        require(totalsupply>0 ,"limit exceeded");
        _tokenIds.increment();
        totalsupply -= 1;
        
        uint256 newItemId = _tokenIds.current();
        _mint(to, newItemId);
        _setTokenURI(newItemId , tokenURi);

    }
    function withdrawal(uint256 amnt)
    public payable onlyRole(DEFAULT_ADMIN_ROLE)
    {
        address payable recipient= payable(msg.sender);
        recipient.transfer(amnt);
        totalAmount = totalAmount -amnt;
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
