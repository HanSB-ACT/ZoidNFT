// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC721Enumerable.sol";
import "./ERC2981.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeCast.sol";

contract ZoidsNFT is
    ERC721Enumerable,
    ERC721Burnable,
    ERC721Pausable,
    ERC2981,
    Ownable
{
    using Counters for Counters.Counter;
    using SafeCast for uint256;

    string public VER;
    bytes4 public constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    Counters.Counter public lastTokenId;
    Counters.Counter public totalTokenCount;
    string public baseTokenURI;
    address public coinContractAddress;

    event evtNFTCreated(address _toAddress, uint256 _tokenId);

    constructor(
        string memory _ver,
        string memory _name,
        string memory _symbol,
        string memory _uri,
        address _erc20
    ) public ERC721(_name, _symbol) {
        VER = _ver;
        setBaseURI(_uri);
        setCoinContractAddress(_erc20);
        supportsInterface(_INTERFACE_ID_ERC2981);
    }

    function setCoinContractAddress(address _contractAddress) public onlyOwner {
        coinContractAddress = _contractAddress;
    }

    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(_baseURI(), "contract-meta"));
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _uri) public onlyOwner {
        baseTokenURI = _uri;
    }

    function totalSupply() public view returns (uint256) {
        return totalTokenCount.current();
    }

    function getLastTokenId() public view returns (uint256) {
        return lastTokenId.current();
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

    function _createCard(address _toAddress, uint96 _royalty) private {
        lastTokenId.increment();
        totalTokenCount.increment();

        uint256 _tokenId = lastTokenId.current();
        _safeMint(_toAddress, _tokenId);

        setRoyaltyInfo(_tokenId, owner(), _royalty);

        emit evtNFTCreated(_toAddress, _tokenId);
    }

    function createCard(address _toAddress, uint96 _royalty) public onlyOwner {
        _createCard(_toAddress, _royalty);
    }

    function createCardWithBurn(
        address _toAddress,
        uint256[] memory _burnTokenIds,
        uint96 _royalty
    ) public onlyOwner {
        _burnCards(_burnTokenIds);
        _createCard(_toAddress, _royalty);
    }

    function unpack(
        address _toAddress,
        uint256 _amount,
        uint96 _royalty
    ) public {
        for (uint256 i = 0; i < _amount; i++) {
            _createCard(_toAddress, _royalty);
        }
    }

    function burn(uint256 _tokenId) public override {
        totalTokenCount.decrement();
        super.burn(_tokenId);
    }

    function _burnCards(uint256[] memory _burnTokenIds) private {
        for (uint256 i = 0; i < _burnTokenIds.length; i++) {
            totalTokenCount.decrement();
            _burn(_burnTokenIds[i]);
        }
    }

    function market(
        address _buyer,
        uint256 _tokenId,
        uint256 _coinAmount
    ) public {
        address royaltyReciever;
        uint256 royaltyAmount;
        (royaltyReciever, royaltyAmount) = royaltyInfo(_tokenId, _coinAmount);
        ERC20(coinContractAddress).transferFrom(
            _buyer,
            royaltyReciever,
            royaltyAmount
        );

        address tokenOwner = ownerOf(_tokenId);
        uint256 tokenOwnerAmount = _coinAmount - royaltyAmount;
        ERC20(coinContractAddress).transferFrom(
            _buyer,
            tokenOwner,
            tokenOwnerAmount
        );

        safeTransferFrom(tokenOwner, _buyer, _tokenId);
    }

    function marketMulti(
        address _buyer,
        uint256[] memory _tokenId,
        uint256[] memory _coinAmount
    ) public {
        require(
            _tokenId.length == _coinAmount.length,
            "marketMulti: values length mismatch"
        );

        for (uint256 i = 0; i < _tokenId.length; i++) {
            market(_buyer, _tokenId[i], _coinAmount[i]);
        }
    }

    function pause() public virtual onlyOwner {
        _pause();
    }

    function unpause() public virtual onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address _fromAddress,
        address _toAddress,
        uint256 _tokenId
    )
        internal
        virtual
        override(ERC721, ERC721Enumerable, ERC721Pausable)
        whenNotPaused
    {
        super._beforeTokenTransfer(_fromAddress, _toAddress, _tokenId);
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
