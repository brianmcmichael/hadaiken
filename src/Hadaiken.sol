pragma solidity ^0.5.15;

import { JugAbstract } from "lib/dss-interfaces/src/dss/JugAbstract.sol";
import { PotAbstract } from "lib/dss-interfaces/src/dss/PotAbstract.sol";
import { VatAbstract } from "lib/dss-interfaces/src/dss/VatAbstract.sol";
import { VowAbstract } from "lib/dss-interfaces/src/dss/VowAbstract.sol";
import { OsmAbstract } from "lib/dss-interfaces/src/dss/OsmAbstract.sol";

import { GemPitAbstract  } from "lib/dss-interfaces/src/sai/GemPitAbstract.sol";
import { DSTokenAbstract } from "lib/dss-interfaces/src/dapp/DSTokenAbstract.sol";

import { PotHelper   } from "lib/dss-interfaces/src/dss/PotHelper.sol";

// ༼つಠ益ಠ༽つ ─=≡Σ◈)) HADAIKEN
//
// Optimized contract for performing some or all of the functions that
//   keep Multi-Collateral Dai running.
contract Hadaiken {

    address constant internal PIT = address(0x69076e44a9C70a67D5b79d95795Aba299083c275);
    address constant internal MKR = address(0x9f8F72aA9304c8B593d555F12eF6589cC3A579A2);
    address constant internal JUG = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address constant internal POT = address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address constant internal VAT = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address constant internal VOW = address(0xA950524441892A31ebddF91d3cEEFa04Bf454466);

    address constant internal PIP_ETH = address(0x81FE72B5A8d1A857d176C3E7d5Bd2679A9B85763);
    address constant internal PIP_BAT = address(0xB4eb54AF9Cc7882DF0121d26c5b97E802915ABe6);

    GemPitAbstract  constant internal pit    = GemPitAbstract(PIT);
    DSTokenAbstract constant internal gem    = DSTokenAbstract(MKR);
    JugAbstract     constant internal jug    = JugAbstract(JUG);
    PotAbstract     constant internal pot    = PotAbstract(POT);
    VowAbstract     constant internal vow    = VowAbstract(VOW);
    VatAbstract     constant internal vat    = VatAbstract(VAT);
    OsmAbstract     constant internal osmeth = OsmAbstract(PIP_ETH);
    OsmAbstract     constant internal osmbat = OsmAbstract(PIP_BAT);
    PotHelper                internal poth;

    bytes32 constant internal ETH_A  = bytes32("ETH-A");
    bytes32 constant internal BAT_A  = bytes32("BAT-A");
    bytes32 constant internal USDC_A = bytes32("USDC-A");

    constructor() public {
        poth = new PotHelper(POT);
    }

    // Raw System Debt
    function _rawSysDebt() internal view returns (uint256) {
        return (vat.sin(VOW) - vow.Sin() - vow.Ash());
    }

    function rawSysDebt() external view returns (uint256) {
        return _rawSysDebt();
    }

    function _sysSurplusThreshold() internal view returns (uint256) {
        return (vat.sin(VOW) + vow.bump() + vow.hump());
    }

    function  sysSurplusThreshold() external view returns (uint256) {
        return _sysSurplusThreshold();
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
    function drip() external returns (uint256 chi) {
        chi = pot.drip();
        _dripIlks();
    }

    // Returns a simulated chi value
    function drop() external view returns (uint256) {
        return poth.drop();
    }

    function _dripPot() internal {
        pot.drip();
    }

    function dripIlks() external {
        _dripIlks();
    }

    function _dripIlks() internal {
        jug.drip(ETH_A);
        jug.drip(BAT_A);
        jug.drip(USDC_A);
    }

    function kickable() external view returns (bool) {
        return _kickable();
    }

    // Can we bump an auction?
    function _kickable() internal view returns (bool) {
        // Assume heal is called prior to kick.
        // require(vat.dai(address(this)) >= add(add(vat.sin(address(this)), bump), hump), "Vow/insufficient-surplus");
        // require(sub(sub(vat.sin(address(this)), Sin), Ash) == 0, "Vow/debt-not-zero");
        return (vat.dai(VOW) >= _sysSurplusThreshold());
    }

    // Burn all of the MKR in the Sai Pit
    function finishhim() external returns (uint256 burned) {
        burned = gem.balanceOf(PIT);
        _finishhim();
    }

    function _finishhim() internal {
        pit.burn(MKR);
    }

    // Kick off an auction and return the auction ID
    function ccccombobreaker() external returns (uint256) {
        _heal();  // Flap requires debt == 0
        return vow.flap();
    }

    // Kick off an auction and throw away id
    function _ccccombobreaker() internal {
        vow.flap();
    }

    function _pokeETH() internal {
        if (osmeth.pass()) { osmeth.poke(); }
    }

    function _pokeBAT() internal {
        if (osmbat.pass()) { osmbat.poke(); }
    }

    function _pokeThings() internal {
        _pokeETH();
        _pokeBAT();
    }

    function hundredHandSlap() external {
        _pokeThings();
    }

    // Kitchen sink. Call this early and often.
    function hadaiken() external {
        _pokeThings();                            // Update oracle prices
        _dripPot();                               // Update the chi
        _dripIlks();                              // Updates the Ilk rates
        _heal();                                  // Cancel out system debt with system surplus
        if (_kickable()) { _ccccombobreaker(); }  // Start an auction
    }
}
