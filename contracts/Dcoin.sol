//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DCoin is ERC721, AccessControl, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    uint256 mintPrice = 1e8 gwei;
    uint256 maxGasPrice = 64 gwei;
    uint8 public minterLength = 0;

    Counters.Counter private _idCounter;
    uint256 public maxSupply;
    mapping(uint256 => address) public mintersList;
    mapping(address => bool) public mintersMap;
    mapping(address => uint256) public royaltiesMap;
    address daoWallet;
    address fCWallet;
    string private baseURI;

    bool public paused = false;

    modifier onlyPerson() {
        require(msg.sender == tx.origin, "CONTRACT_MINTING_NOT_PERMITTED");
        _;
    }

    constructor(
        uint256 _maxSupply,
        address _daoWallet,
        address _fCWallet,
        string memory _baseURI
    ) ERC721("DCoin", "DC") {
        maxSupply = _maxSupply;
        daoWallet = _daoWallet;
        fCWallet = _fCWallet;
        baseURI = _baseURI;
    }

    function mint() public payable onlyPerson {
        uint256 current = _idCounter.current();
        require(!mintersMap[msg.sender], "you already minted a worm");
        require(!paused, "Worms is paused");
        require(current < maxSupply, "No Worms left :(");
        require(msg.value >= mintPrice, "Not enough ETH to mint a Worm");

        mintersList[current] = msg.sender;
        mintersMap[msg.sender] = true;
        royaltiesMap[msg.sender] = 0;
        minterLength++;
        _idCounter.increment();

        _safeMint(msg.sender, current);

        uint256 quantity = msg.value;
        uint256 daoQtty = quantity.div(100).mul(30);
        uint256 fcQtty = quantity.div(100).mul(70);
        royaltiesMap[daoWallet] += daoQtty;
        royaltiesMap[fCWallet] += fcQtty;
    }

    function setNewMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function getBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }

    function setFCWallet(address _FCWallet) public onlyOwner {
        fCWallet = _FCWallet;
    }

    function setDaoWallet(address _DaoWallet) public onlyOwner {
        daoWallet = _DaoWallet;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function changeBaseURI(string memory baseURI_) public onlyOwner {
        baseURI = baseURI_;
    }

    function withdrawMoney() public onlyPerson nonReentrant {
        require(royaltiesMap[msg.sender] > 0, "You have no money to withdraw");
        uint256 auxBalance = royaltiesMap[msg.sender];
        royaltiesMap[msg.sender] -= auxBalance;
        (bool success, ) = payable(msg.sender).call{value: auxBalance}("");
        require(success, "TRANSFER_FAILED");
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
