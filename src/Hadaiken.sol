pragma solidity ^0.5.15;

import { JugAbstract } from "lib/dss-interfaces/src/dss/JugAbstract.sol";
import { PotAbstract } from "lib/dss-interfaces/src/dss/PotAbstract.sol";
import { VatAbstract } from "lib/dss-interfaces/src/dss/VatAbstract.sol";
import { VowAbstract } from "lib/dss-interfaces/src/dss/VowAbstract.sol";
import { PotHelper   } from "lib/dss-interfaces/src/dss/PotHelper.sol";

// ༼つಠ益ಠ༽つ ─=≡Σ◈)) HADAIKEN
//
// Optimized contract for performing some or all of the functions that
//   keep Multi-Collateral Dai running.
contract Hadaiken {

    address constant internal JUG = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address constant internal POT = address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address constant internal VAT = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address constant internal VOW = address(0xA950524441892A31ebddF91d3cEEFa04Bf454466);

    JugAbstract constant internal jug  = JugAbstract(JUG);
    PotAbstract constant internal pot  = PotAbstract(POT);
    VowAbstract constant internal vow  = VowAbstract(VOW);
    VatAbstract constant internal vat  = VatAbstract(VAT);
    PotHelper   constant internal poth = PotHelper(POT);

    bytes32 constant internal ETH_A = bytes32("ETH-A");
    bytes32 constant internal BAT_A = bytes32("BAT-A");

    // Raw System Debt
    function _rawSysDebt() internal view returns (uint256) {
        // Not using safemath for gas efficiency and any side-effects are on MakerDao
        return vat.sin(VOW) - vow.Sin() - vow.Ash();
    }

    function rawSysDebt() external view returns (uint256) {
        return _rawSysDebt();
    }

    // Saves you money.
    function heal() external {
        _heal();
    }

    // Returns the amount of debt healed if you're curious about that sort of thing.
    function healStat() external returns (uint256 sd) {
        sd = _rawSysDebt();
        _heal();
    }

    // No return here. I want to save gas and who cares.
    function _heal() internal {
        vow.heal(_rawSysDebt());
    }

    // Return the new chi value after drip.
    function drip() external returns (uint256) {
        return pot.drip();
    }

    // Returns a simulated chi value
    function drop() external view returns (uint256) {
        return poth.drop();
    }

    function _dripPot() internal {
        pot.drip();
    }

    function _dripIlks() internal {
        jug.drip(ETH_A);
        jug.drip(BAT_A);
    }

    // Can we bump an auction?
    // sump: debt auction bid size, i.e. the fixed debt quantity to be covered by any one debt auction
    // dump: debt auction lot size, i.e. the starting amount of MKR offered to cover the lot/sump
    // bump: surplus auction lot size, i.e. the fixed surplus quantity to be sold by any one surplus
    // hump: surplus buffer
    // Call heal first or this will fail.
    function _bumppable() internal view returns (bool) {
        // minSurplus = vow.hump() + vow.bump();
        // sysSurplus = vat.dai(VOW) - vat.sin(VOW);
        return (vow.hump() + vow.bump()) > (vat.dai(VOW) - vat.sin(VOW));
    }

    // Kick off an auction and return the auction ID
    function cccombobreaker() external returns (uint256) {
        _heal();
        return vow.flap();
    }

    // Kick off an auction and throw away id
    function _ccccombobreaker() internal {
        vow.flap();
    }

    // Kitchen sink. Call this early and often.
    function hadaiken() public {
        _dripPot();                                // Update the chi
        _dripIlks();                               // Updates the Ilk rates
        _heal();                                   // Cancel out system debt with system surplus
        if (_bumppable()) { _ccccombobreaker(); }  // Start an auction
    }
}
