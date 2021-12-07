// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";


abstract contract DualOwnable is Context {
    address private _owner;
    address private _serviceManager;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ServiceManagerChanged(address indexed previousManager, address indexed newManager);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function serviceManager() public view virtual returns (address) {
        return _serviceManager;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyServiceManager() {
        require(serviceManager() == _msgSender(), "Ownable: caller is not the Service Manager");
        _;
    }

    modifier onlyOwnerOrServiceManager() {
        require(owner() == _msgSender() || serviceManager() == _msgSender(), "Ownable: caller is neither owner nor service manager");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function _setServiceManager(address newServiceManager) internal {
        address oldServiceManager = _serviceManager;
        _serviceManager = newServiceManager;
        emit ServiceManagerChanged(oldServiceManager, newServiceManager);
    }
}
