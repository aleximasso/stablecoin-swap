//SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.0;

import '@openzeppelin/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol';


contract MockStablecoin is ERC20PresetMinterPauser {
    constructor (string memory name, string memory symbol) ERC20PresetMinterPauser(name, symbol) {
        // Silence
    }

    function burn(uint256 amount) public virtual override {
        require(hasRole(MINTER_ROLE, _msgSender()), "MockStablecoin: must have minter role to burn!");

        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public virtual override {
        require(hasRole(MINTER_ROLE, _msgSender()), "MockStablecoin: must have minter role to burn!");

        super.burnFrom(account, amount);
    }
}