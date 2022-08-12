// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract NFTV1 is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC2981,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeCast for uint256;

    string public VER = "1.0";
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    address private constant ERC20_CONTRACT_ADDRESS =
        0x145e892dEB69fDF39924595ec6635868c5a0fa51;

    Counters.Counter public lastTokenId;
    string private baseURI;

    struct CardInfo {
        uint256 cardIndex;
    }
    mapping(uint256 => CardInfo) public cardInfos;

    event evtNFTCreated(address _owner, uint256 _tokenId);

    constructor(string memory _name, string memory _symbol)
        public
        ERC721(_name, _symbol)
    {
        setBaseURI("https://webqa.zoidsnft.io/api/meta/");
        supportsInterface(_INTERFACE_ID_ERC2981);
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract-meta"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function getLastTokenId() public view returns (uint256) {
        return lastTokenId.current();
    }

    function getCardIndex(uint256 _tokenId) public view returns (uint256) {
        return cardInfos[_tokenId].cardIndex;
    }

    function tokensOfOwner(
        address _owner,
        uint256 _min,
        uint256 _max
    ) public view returns (uint256[] memory) {
        require(
            _min <= _max,
            "tokensOfOwner: min value is bigger than max value"
        );

        uint256 arrayLength = _max - _min + 1;
        uint256 count = 0;
        uint256[] memory tokenIds = new uint256[](arrayLength);
        for (uint256 index = _min; index <= _max; index++) {
            tokenIds[count] = tokenOfOwnerByIndex(_owner, index);
            count++;
        }
        return tokenIds;
    }

    function _createCard(
        address _toAddress,
        uint256 _cardIndex,
        uint96 _royalty
    ) private {
        lastTokenId.increment();

        uint256 _tokenId = lastTokenId.current();
        _safeMint(_toAddress, _tokenId);
        setRoyaltyInfo(_tokenId, owner(), _royalty);

        cardInfos[_tokenId] = CardInfo(_cardIndex);

        emit evtNFTCreated(_toAddress, _tokenId);
    }

    function createCard(
        address _toAddress,
        uint256 _cardIndex,
        uint96 _royalty
    ) public onlyOwner {
        _createCard(_toAddress, _cardIndex, _royalty);
    }

    function createCardWithBurn(
        address _toAddress,
        uint256 _cardIndex,
        uint256[] memory _burnTokenId,
        uint96 _royalty
    ) public onlyOwner {
        for (uint256 i = 0; i < _burnTokenId.length; i++) {
            _burn(_burnTokenId[i]);
        }

        _createCard(_toAddress, _cardIndex, _royalty);
    }

    function unpack(
        address _toAddress,
        uint256[] memory _cardIndex,
        uint256 _amount,
        uint96 _royalty
    ) public {
        require(_cardIndex.length == _amount, "unpack: values length mismatch");

        for (uint256 i = 0; i < _amount; i++) {
            _createCard(_toAddress, _cardIndex[i], _royalty);
        }
    }

    function market(
        uint256 _tokenId,
        address _buyer,
        uint256 _amount
    ) public {
        address royaltyReciever;
        uint256 royaltyAmount;
        (royaltyReciever, royaltyAmount) = royaltyInfo(_tokenId, _amount);
        uint256 tokenOwnerAmount = _amount - royaltyAmount;

        address tokenOwner = ownerOf(_tokenId);
        ERC20(ERC20_CONTRACT_ADDRESS).transferFrom(
            _buyer,
            tokenOwner,
            tokenOwnerAmount
        );

        ERC20(ERC20_CONTRACT_ADDRESS).transferFrom(
            _buyer,
            royaltyReciever,
            royaltyAmount
        );

        safeTransferFrom(tokenOwner, _buyer, _tokenId);
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    )
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function setRoyaltyInfo(
        uint256 _tokenId,
        address _receiver,
        uint96 _royalty
    ) public onlyOwner {
        _setTokenRoyalty(_tokenId, _receiver, _royalty);
    }

    function checkRoyalties(address _contractAddress)
        public
        view
        returns (bool)
    {
        bool _success = IERC165(_contractAddress).supportsInterface(
            _INTERFACE_ID_ERC2981
        );
        return _success;
    }

    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(IERC165, ERC721, ERC721Enumerable)
        returns (bool)
    {
        return (_interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(_interfaceId));
    }
}
