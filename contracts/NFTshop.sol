// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "hardhat/console.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

import "./base/ERC721.sol";
import "./base/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NFTstore is ERC721Enumerable, Ownable {
  using Strings for uint256;

  uint256 royalityFee;
  uint256 defaultPrice = 0.000000000000000001 ether;
  address governance;
  string baseURI;
  string public baseExt = ".json";

  enum fileType {image, audio, video, gif, other}

  event Sale(address from, address to, uint256 value);

  mapping (uint => uint256) public typeToRoyalityFees;
  mapping (uint256 => Item) public idToItem;

  struct Item {
    uint256 id;
    address currentOwner;
    uint256 price;
    fileType ftype;
  }

constructor(string memory _initbaseURI,uint256 _royalityFee,address _governance)ERC721("MintyStudio","MS"){

  royalityFee=_royalityFee;
  governance=_governance;
  setBaseURI(_initbaseURI);

  for (uint i = 0; i < 4; i++) {
    typeToRoyalityFees[i] = _royalityFee;
  }

}

 // Governance functions
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        baseURI = _newBaseURI;
    }

      function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExt
                    )
                )
                : "";
    }

    function mint(uint256 _price, fileType _ftype ) public payable {
      uint256 supply = totalSupply();
      Item memory item = Item({
        id: supply,
        currentOwner: msg.sender,
        price: _price,
        ftype: _ftype
      });
//update ftype
      uint256 royality = typeToRoyalityFees[uint(_ftype)];

      require(_price > defaultPrice,"NFT have some value");
      if(msg.sender != governance){
           royality = (msg.value * royality) / 100;
          if(item.currentOwner != address(0)){
            _payRoyality(item.currentOwner,royality);
          }
          (bool success2, ) = payable(governance).call{
                value: (msg.value - royality)
            }("");
            require(success2);
      }
       _safeMint(msg.sender, uint8(supply + 1));
    }

    function _payRoyality(address caller, uint256 _royalityFee) internal {
        (bool success1, ) = payable(caller).call{value: _royalityFee}("");
        require(success1);
    }

    function transferFrom (address from, address to, uint256 tokenId) public payable override {
      require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NA");
      if(msg.value > 0){
        uint256 royality = typeToRoyalityFees[uint(idToItem[tokenId].ftype)];
        _payRoyality(idToItem[tokenId].currentOwner, royality);
        (bool success2, ) = payable(from).call{value: msg.value - royality}("");
        require(success2);
        emit Sale(from, to, msg.value);
      }
      safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public payable override {
      require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: NA");
       if(msg.value > 0){
        uint256 royality = typeToRoyalityFees[uint(idToItem[tokenId].ftype)];
        _payRoyality(idToItem[tokenId].currentOwner, royality);
        (bool success2, ) = payable(from).call{value: msg.value - royality}("");
        require(success2);
        emit Sale(from, to, msg.value);
      }
      safeTransferFrom(from, to, tokenId,_data);
    }

    function setRoyality ( fileType _ftype, uint256 value) external onlyOwner {
      typeToRoyalityFees[uint(_ftype)] = value;
    }

    function _baseURI () internal virtual view override returns (string memory) {
     return baseURI;
    }
}
