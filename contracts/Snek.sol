// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract SnakeEggNFT is ERC721URIStorage, Ownable {
    ERC20Burnable public foodToken;
    uint256 public hatchTime;
    uint256 public nextTokenId;

    struct Snake {
        uint256 birthTime;
        string color;
        string speckles;
        bool hatched;
        uint256 lastFed;
    }

    mapping(uint256 => Snake) public snakes;

    event EggMinted(address indexed to, uint256 tokenId);
    event EggHatched(uint256 tokenId);
    event SnakeFed(uint256 tokenId, uint256 amount);

    constructor() Ownable(msg.sender)  ERC721("SnakeEgg", "EGG") {
        foodToken = ERC20Burnable(0x36C02dA8a0983159322a80FFE9F24b1acfF8B570);
        hatchTime = 10 minutes;
        nextTokenId = 0;
    }

    function mintEgg() external returns (uint256) {
        uint256 newId = nextTokenId;
        nextTokenId++;

        _mint(msg.sender, newId);
        _setTokenURI(newId, "ipfs://placeholder-egg-uri");

        string memory color = _randomColor(newId);
        string memory speckles = _randomSpeckles(newId);

        snakes[newId] = Snake(block.timestamp, color, speckles, false, block.timestamp);

        emit EggMinted(msg.sender, newId);
        return newId;
    }

    function hatch(uint256 tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "Not your egg");
        Snake storage snake = snakes[tokenId];
        require(!snake.hatched, "Already hatched");
        require(block.timestamp >= snake.birthTime + hatchTime, "Not ready to hatch");

        snake.hatched = true;
        _setTokenURI(tokenId, _generateSnakeURI(tokenId));

        emit EggHatched(tokenId);
    }

function feed(uint256 tokenId, uint256 amount) external {
    require(ownerOf(tokenId) == msg.sender, "You do not own this snake.");
    require(snakes[tokenId].hatched, "Snake is not hatched yet.");

    uint256 timeSinceLastFed = block.timestamp - snakes[tokenId].lastFed;
    uint256 feedingCost;

    if (timeSinceLastFed < 4 hours) {
        feedingCost = 10 * 10**18; // 10 tokens
    } else if (timeSinceLastFed >= 24 hours) {
        feedingCost = 100 * 10**18; // 100 tokens
    } else {
        feedingCost = 10 * 10**18; // 10 tokens
    }

    require(amount >= feedingCost, "Insufficient feeding amount.");

    // Transfer tokens from the sender to this contract
    foodToken.approve(msg.sender, amount);
    bool received = foodToken.transferFrom(msg.sender, address(this), amount);
    require(received, "Token transfer failed.");

    // Burn the received tokens by sending them to the zero address
    foodToken.approve(address(this), amount);
    foodToken.burnFrom(address(this), amount);

    // Update the lastFed timestamp
    snakes[tokenId].lastFed = block.timestamp;

    // Implement additional logic for feeding the snake, if necessary
}

    function getOwnedTokens(address owner) external view returns (uint256[] memory) {
        uint256 total = nextTokenId;
        uint256 count = 0;
        uint256[] memory temp = new uint256[](total);

        for (uint256 i = 0; i < total; i++) {
            try this.ownerOf(i) returns (address tokenOwner) {
                if (tokenOwner == owner) {
                    temp[count] = i;
                    count++;
                }
            } catch {
                // Token does not exist, skip
            }
        }

        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = temp[j];
        }

        return result;
    }

    function _randomColor(uint256 seed) internal view returns (string memory) {
        string[3] memory colors = ["green", "brown", "gold"];
        return colors[uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))) % colors.length];
    }

    function _randomSpeckles(uint256 seed) internal view returns (string memory) {
        string[3] memory speckles = ["none", "dots", "stripes"];
        return speckles[uint256(keccak256(abi.encodePacked(block.difficulty, msg.sender, seed))) % speckles.length];
    }

    function _generateSnakeURI(uint256 tokenId) internal view returns (string memory) {
        Snake memory snake = snakes[tokenId];
        return string(abi.encodePacked("ipfs://placeholder-snake-uri/", snake.color, "-", snake.speckles));
    }

    function setEggURI(uint256 tokenId, string memory uri) external onlyOwner {
        _setTokenURI(tokenId, uri);
    }

    function withdrawFood() external onlyOwner {
        uint256 balance = foodToken.balanceOf(address(this));
        foodToken.transfer(msg.sender, balance);
    }
}
