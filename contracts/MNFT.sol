// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/extensions/ERC1155SupplyUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";


    contract Whitelist is Initializable, OwnableUpgradeable {
      
        function initializeWhitelist() internal  {
        __Ownable_init();
        whitelistEnabled = true;
    }
      
    // Mapping of address to boolean indicating whether the address is whitelisted
    mapping(address => bool) private whitelistMap;

    // flag controlling whether whitelist is enabled.
    bool private whitelistEnabled;

    event AddToWhitelist(address indexed _newAddress);
    event RemoveFromWhitelist(address indexed _removedAddress);

    /**
   * @dev Enable or disable the whitelist
   * @param _enabled bool of whether to enable the whitelist.
   */
    function enableWhitelist(bool _enabled) public onlyOwner {
        whitelistEnabled = _enabled;
    }

    /**
   * @dev Adds the provided address to the whitelist
   * @param _newAddress address to be added to the whitelist
   */
    function addToWhitelist(address _newAddress) public onlyOwner {
        _whitelist(_newAddress);
        
        emit AddToWhitelist(_newAddress);
    }

    /**
   * @dev Removes the provided address to the whitelist
   * @param _removedAddress address to be removed from the whitelist
   */
    function removeFromWhitelist(address _removedAddress) public onlyOwner {
        _unWhitelist(_removedAddress);
        emit RemoveFromWhitelist(_removedAddress);
    }

    /**
   * @dev Returns whether the address is whitelisted
   * @param _address address to check
   * @return bool
   */
    function isWhitelisted(address _address) public view returns (bool) {
        if (whitelistEnabled) {
            return whitelistMap[_address];
        } else {
            return true;
        }
    }

    /**
   * @dev Internal function for removing an address from the whitelist
   * @param _removedAddress address to unwhitelisted
   */
    function _unWhitelist(address _removedAddress) internal {
        whitelistMap[_removedAddress] = false;
    }

    /**
   * @dev Internal function for adding the provided address to the whitelist
   * @param _newAddress address to be added to the whitelist
   */
    function _whitelist(address _newAddress) internal {
        whitelistMap[_newAddress] = true;
    }
}
contract MNFT is Initializable, ERC1155Upgradeable, OwnableUpgradeable, PausableUpgradeable, ERC1155SupplyUpgradeable , Whitelist{

    using CountersUpgradeable for CountersUpgradeable.Counter;
    using StringsUpgradeable for string;
    CountersUpgradeable.Counter private _tokenIds;


    uint256 public constant Bronze = 1;
    uint256 public constant Silver = 2;
    uint256 public constant Gold = 3;
    uint256 public constant Platinum = 4;
    uint256 public constant Legendary = 5;
    address marketPlace;

    //how many tokens a user can mint, not admin
    uint minterCopyAmount;
    event MarketplaceAddress(address);

    mapping (uint256 => string) private _uris;

    // Mapping from token ID to the creator's address.
    mapping(uint256 => address) private tokenCreators;

    event Received(address, uint256);

    function initialize() initializer public {
        __ERC1155_init("");
        __Ownable_init();
        __Pausable_init();
        __ERC1155Supply_init();
        Whitelist.initializeWhitelist();
        addToWhitelist(owner());
        minterCopyAmount = 1;
    }

    function initTokens(address  _marketAddress) external onlyOwner {
        marketPlace =  _marketAddress;
        createToken(owner(),200,"");
        createToken(owner(),100,"");
        createToken(owner(),50,"");
        createToken(owner(),15,"");
        createToken(owner(),1,"");
        setTokenURIsForPtokens();
    }

        /**
     * @dev Whitelists a bunch of addresses.
     * @param _whitelistees address[] of addresses to whitelist.
     */
    function initWhitelist(address[] memory _whitelistees) public onlyOwner {
      // Add all whitelistees.
      for (uint256 i = 0; i < _whitelistees.length; i++) {
        address creator = _whitelistees[i];
        if (!isWhitelisted(creator)) {
          _whitelist(creator);
        }
      }
      
    }
    // a function for minting tokens
    //admin can mint a token with multiple copies
    //other user can only mint one token, unique token
     function createToken(address _to, uint _copies, string memory _uri) public returns (uint) {
        require(isWhitelisted(msg.sender), "must be whitelisted to create tokens");
         _tokenIds.increment();
         uint256 ItemId = _tokenIds.current();
          _setTokenCreator(ItemId, _to);
         if (msg.sender == owner()) {
         uint256 newItemId = _tokenIds.current();
             _mint(_to, newItemId, _copies, "");
            setTokenUri(newItemId,_uri);
            setApprovalForAll(marketPlace,true);
             return newItemId;
         }
         else{
            require(msg.sender != owner(),"error: admin cannot mint this");
            uint256 newItemId = _tokenIds.current();
            _mint(_to, newItemId, minterCopyAmount, "");
            setTokenUri(newItemId,_uri);
            setApprovalForAll(marketPlace,true);
            return newItemId;
         }
    }

    //setting token URI's for cards
    function setTokenURIsForPtokens() private onlyOwner {
        _uris[Bronze] = "https://ipfs.io/ipfs/QmV2iGCCPbuzsvNVDc37s/1.json";
        _uris[Silver] = "https://ipfs.io/ipfs/QmV2fCdzuiVAbVDc37s/2.json";
        _uris[Gold] = "https://ipfs.io/ipfs/QmV2iGCCPbuzzuiVAbVDc37s/3.json";
        _uris[Platinum] = "https://ipfs.io/ipfs/QmV2iGCCPVDc37s/4.json";
        _uris[Legendary] = "https://ipfs.io/ipfs/QmV2iGCCPVAbVDc37s/5.json";
    }

    //address of the market place to sell token on
    function setMarketPlaceAddress(address _marketPlaceAddress) public onlyOwner{
        marketPlace = _marketPlaceAddress;
        emit MarketplaceAddress(marketPlace);
    }

     function setTokenUri(uint256 _tokenId, string memory newuri) public {
        require(bytes(_uris[_tokenId]).length == 0, "Cannot set uri twice");
        _uris[_tokenId] = newuri;
    }

    function uri(uint256 _tokenId) public view override returns(string memory){
        string memory hexstringtokenID;
        hexstringtokenID =  StringsUpgradeable.toString(_tokenId);
        if (_tokenId < 6) {
            return string( abi.encodePacked( "https://ipfs.io/ipfs/QmV2iGCCPb",hexstringtokenID,".json") );
        } else {
            return(_uris[_tokenId]);
        }
    }

     /**
    * @dev Gets the creator of the token.
    * @param _tokenId uint256 ID of the token.
    * @return address of the creator.
    */
    function tokenCreator(uint256 _tokenId) public view returns (address) {
        return tokenCreators[_tokenId];
    }

    /**
     * @dev Internal function for setting the token's creator.
     * @param _tokenId uint256 id of the token.
     * @param _creator address of the creator of the token.
     */
    function _setTokenCreator(uint256 _tokenId, address _creator) internal {
      tokenCreators[_tokenId] = _creator;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address account, uint256 id, uint256 amount, bytes memory data)
        public
        onlyOwner
    {
        require(id <=_tokenIds.current(),"");
        _mint(account, id, amount, data);
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        public
        onlyOwner
    {
        _mintBatch(to, ids, amounts, data);
    }

    /**
     * @dev Deletes the token with the provided ID.
     * @param _tokenId uint256 ID of the token.
    //  */
    function deleteToken(address from,uint256 _tokenId, uint amount) public onlyOwner {
    
      _burn(from, _tokenId, amount);
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155Upgradeable, ERC1155SupplyUpgradeable)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }
      function setMinterCopyAmount(uint _minterCopyAmount) public onlyOwner {
        minterCopyAmount = _minterCopyAmount;
    }
    function getMinterCopyAmount() public view returns (uint) {
        return minterCopyAmount;
    }

     function getMarketPlaceAddress() public onlyOwner view returns (address){
      return marketPlace;
    }
      receive() external payable {
      emit Received(msg.sender, msg.value);
    }
}