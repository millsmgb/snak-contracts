// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CompoundingStakableERC20Token
 * @dev ERC20 token with staking functionality that compounds yield automatically.
 */
contract CompoundingStakableERC20Token is ERC20, ERC20Burnable, Ownable {
    // APR in basis points (10000 = 100%)
    uint256 public aprBasisPoints;
    uint256 private constant BASIS_POINTS_DIVISOR = 10000;
    uint256 private constant SECONDS_IN_YEAR = 365 days;

    struct Stake {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event APRUpdated(uint256 newAprBasisPoints);

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        uint256 aprBasisPoints_
    ) Ownable(msg.sender) ERC20(name_, symbol_) ERC20Burnable() {
        _mint(msg.sender, initialSupply);
        aprBasisPoints = aprBasisPoints_;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake zero");
        _compound(msg.sender);
        _transfer(msg.sender, address(this), amount);
        stakes[msg.sender].amount += amount;
        stakes[msg.sender].timestamp = block.timestamp;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        Stake storage userStake = stakes[msg.sender];
        require(amount <= userStake.amount, "Insufficient stake");
        _compound(msg.sender);
        userStake.amount -= amount;
        stakes[msg.sender].timestamp = block.timestamp;
        _transfer(address(this), msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function pendingRewards(address account) public view returns (uint256) {
        Stake memory userStake = stakes[account];
        if (userStake.amount == 0) return 0;
        uint256 timeElapsed = block.timestamp - userStake.timestamp;
        return (userStake.amount * aprBasisPoints * timeElapsed) / (BASIS_POINTS_DIVISOR * SECONDS_IN_YEAR);
    }

    function updateAPR(uint256 newAprBasisPoints) external onlyOwner {
        aprBasisPoints = newAprBasisPoints;
        emit APRUpdated(newAprBasisPoints);
    }

    function _compound(address account) internal {
        uint256 reward = pendingRewards(account);
        if (reward > 0) {
            stakes[account].amount += reward;
            _mint(address(this), reward);
        }
        stakes[account].timestamp = block.timestamp;
    }
}
