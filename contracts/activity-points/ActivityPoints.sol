// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import { OwnableWithManagers } from "../access/OwnableWithManagers.sol";

interface IStats {
  function getWeiSpent(address user_) external view returns (uint256);
  function weiSpentTotal() external view returns (uint256);
}

/** 
@title Collect all wei spending stats from different contracts and return them as one
@author Tempe Techie
*/
contract ActivityPoints is OwnableWithManagers {
  address public statsAddress; // stats for NFT launchpad, Friend Keys, Swap etc.
  address public mintedPostsStatsAddress;
  address public tldStatsAddress;

  uint256 public bonusWeiTotal; // total bonus wei (without multiplier)

  uint256 public multiplier; // multiplier for points (e.g. 1 means 1 wei spent = 1 point)

  mapping (address => uint256) public bonusWei; // bonus wei (without multiplier)

  // EVENTS
  event BonusPointsAdded(address indexed manager_, address indexed user_, uint256 bp_);
  event BonusPointsRemoved(address indexed manager_, address indexed user_, uint256 bp_);

  constructor(
    address _statsAddress,
    address _mintedPostsStatsAddress,
    address _tldStatsAddress,
    uint256 _multiplier
  ) {
    statsAddress = _statsAddress;
    mintedPostsStatsAddress = _mintedPostsStatsAddress;
    tldStatsAddress = _tldStatsAddress;
    multiplier = _multiplier;
  }

  // READ

  function getPoints(address user_) external view returns (uint256) {
    return (bonusWei[user_] + getTotalWeiSpent(user_)) * multiplier;
  }

  function getTotalPointsAllUsers() external view returns (uint256) {
    return (bonusWeiTotal + getTotalWeiSpentAllUsers()) * multiplier;
  }

  function getTotalWeiSpent(address _user) public view returns (uint256) {
    uint256 totalWeiSpent;

    if (statsAddress != address(0)) {
      totalWeiSpent += IStats(statsAddress).getWeiSpent(_user);
    }
    
    if (mintedPostsStatsAddress != address(0)) {
      totalWeiSpent += IStats(mintedPostsStatsAddress).getWeiSpent(_user);
    }

    if (tldStatsAddress != address(0)) {
      totalWeiSpent += IStats(tldStatsAddress).getWeiSpent(_user);
    }

    return totalWeiSpent;
  }

  function getTotalWeiSpentAllUsers() public view returns (uint256) {
    uint256 totalWeiSpent;

    if (statsAddress != address(0)) {
      totalWeiSpent += IStats(statsAddress).weiSpentTotal();
    }
    
    if (mintedPostsStatsAddress != address(0)) {
      totalWeiSpent += IStats(mintedPostsStatsAddress).weiSpentTotal();
    }

    if (tldStatsAddress != address(0)) {
      totalWeiSpent += IStats(tldStatsAddress).weiSpentTotal();
    }

    return totalWeiSpent;
  }

  // OWNER

  /// @notice These points already include the multiplier
  function addBonusPoints(address _user, uint256 _bp) external onlyManagerOrOwner {
    bonusWei[_user] += _bp / multiplier;
    bonusWeiTotal += _bp / multiplier;
    emit BonusPointsAdded(msg.sender, _user, _bp);
  }

  /// @notice These points already include the multiplier
  function removeBonusPoints(address _user, uint256 _bp) external onlyManagerOrOwner {
    require(bonusWei[_user] >= _bp / multiplier, "ActivityPoints: not enough bonus points");
    bonusWei[_user] -= _bp / multiplier;
    bonusWeiTotal -= _bp / multiplier;
    emit BonusPointsRemoved(msg.sender, _user, _bp);
  }

  /// @notice Bonus wei does not include the multiplier
  function addBonusWei(address _user, uint256 _wei) external onlyManagerOrOwner {
    bonusWei[_user] += _wei;
    bonusWeiTotal += _wei;
  }

  /// @notice Bonus wei does not include the multiplier
  function removeBonusWei(address _user, uint256 _wei) external onlyManagerOrOwner {
    require(bonusWei[_user] >= _wei, "ActivityPoints: not enough bonus wei");
    bonusWei[_user] -= _wei;
    bonusWeiTotal -= _wei;
  }

  function setMintedPostsStatsAddress(address _mintedPostsStatsAddress) external onlyManagerOrOwner {
    mintedPostsStatsAddress = _mintedPostsStatsAddress;
  }

  function setMultiplier(uint256 _multiplier) external onlyManagerOrOwner {
    multiplier = _multiplier;
  }

  function setStatsAddress(address _statsAddress) external onlyManagerOrOwner {
    statsAddress = _statsAddress;
  }

  function setTldStatsAddress(address _tldStatsAddress) external onlyManagerOrOwner {
    tldStatsAddress = _tldStatsAddress;
  }
  
}