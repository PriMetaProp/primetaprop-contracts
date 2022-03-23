// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./utils/ECRecovery.sol";
import "./extensions/ERC721Royalty.sol";
import "./utils/Strings.sol";

contract PRMT is ERC721Royalty {
    //uint256 tokenPrice ;
    address owner;
    address payable receiver;
    string baseURI;
    uint256 public maxSupply;
    uint256 public totalSupply;

    /*
    * Whether or not this contract has been initialized. 
    */
    bool private _initialized;

    /*constructor(string memory name, string memory symbol, address payable _receiver, string memory _initBaseURI) ERC721(name, symbol) {
        //tokenPrice=100000000000000000;
        owner = msg.sender;
        receiver = _receiver;

        //Set the base URI for the metadata
        baseURI = _initBaseURI;
    }*/

    function initialize(string memory name, string memory symbol, address payable _receiver, string memory _initBaseURI, uint256 _initMaxSupply) external
    {
        // Assert that the contract hasn't already been initialized
        require(!_initialized, "The token has been alrady initialized");

        //Set name and symbol
        _name = name;
        _symbol = symbol;

        //Set the receiver address and the owner
        owner = msg.sender;
        receiver = _receiver;

        //Set the base URI for the metadata
        baseURI = _initBaseURI;

        //Set the  max supply
        maxSupply = _initMaxSupply;
        _initialized = true;
    }

    /**
     * @return True if the contract has been initialized, otherwise false
     */
    function initialized() external view returns (bool) 
    {
        return _initialized;
    }

    modifier onlyOwner() {
    require(owner == msg.sender, "only owner can execute this function");
    _;
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address recipient,
        uint96 fraction
    ) public {
        _setTokenRoyalty(tokenId, recipient, fraction);
    }

    function setDefaultRoyalty(address recipient, uint96 fraction) public {
        _setDefaultRoyalty(recipient, fraction);
    }

    //function mint(address to, uint256 tokenId) payable public
    function mint(uint256 trxId, uint256 tokenId, bytes memory sig) payable public
    {
        require(totalSupply < maxSupply,"the maximum allowed of tokens have been reached.");


        //Added by MOHAMAD GHANEM on 15th of March 2022
        //Digital signature part
        // recreates the message that was signed on the client.
        bytes32 message = hashFun(msg.sender, address(this), trxId, tokenId, msg.value);
        require(ECDSA.recover(message, sig)==owner, "Invalid signature");


        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(Strings.toString(tokenId), ".json")));
        totalSupply+=1;

        //This is a mint function
        //Transfer the amount to the receiver address
        receiver.transfer(msg.value);
    }

    function mintByOwner (address to,uint256 tokenId) onlyOwner public
    {
        require(totalSupply < maxSupply,"the maximum allowed of tokens have been reached.");
        _mint(to, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(Strings.toString(tokenId), ".json")));
        totalSupply+=1;
    }

    function setMaxSupply (uint256 _newMaxSupply) onlyOwner public
    {
        require(_newMaxSupply > 0, "The Max supply must be greater than zero.");
        require(_newMaxSupply >= totalSupply, "Max supply must be equal or greater than the total supply.");
        maxSupply =_newMaxSupply;
    }

    /*function setPrice(uint256 newPrice) onlyOwner public
    {
        tokenPrice = newPrice;
    }*/

    function setOwnership(address newOwner) onlyOwner public
    {
        owner = newOwner;
    }

    function getOwner() view external returns (address) 
    {
        return owner;
    }
    /*function getTokenPrice() view external returns (uint256) 
    {
        return tokenPrice;
    }*/

    function burn(uint256 tokenId) internal {
        _burn(tokenId);
        totalSupply-=1;
    }

    function deleteDefaultRoyalty() public {
        _deleteDefaultRoyalty();
    }

    function hashFun (address _receiver, address _poolContract, uint256 _trxId, uint256 _tokenId, uint256 _tokenPrice) internal pure returns (bytes32)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(abi.encode(prefix, keccak256(abi.encode(_receiver, _poolContract, _trxId, _tokenId, _tokenPrice))));
    }

    function setReceiverAddress(address payable newReceiverAddress) onlyOwner public
    {
        receiver = newReceiverAddress;
    }

    function getReceiverAddress() view external returns (address) 
    {
        return receiver;
    }

    function setBaseURI(string memory _newBaseURI) onlyOwner public
    {
        require(bytes(_newBaseURI).length > 0, "Invalid base URI");
        baseURI = _newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /*
    * Below function will double check if only the owner of the token will try to burn it
    */
    function _beforeTokenTransfer(address from,address to,uint256 tokenId) internal virtual override
    {
        if (to==address(0))
        {
            //This is a burn action
            require(from==msg.sender, "You are not the owner of the token.");
        }
    }
}
