pragma solidity ^0.5.11;

// ../test-hadaiken.sh

import "ds-test/test.sol";

import { Hadaiken } from "./Hadaiken.sol";

import { JugAbstract } from "lib/dss-interfaces/src/dss/JugAbstract.sol";
import { PotAbstract } from "lib/dss-interfaces/src/dss/PotAbstract.sol";
import { VatAbstract } from "lib/dss-interfaces/src/dss/VatAbstract.sol";
import { VowAbstract } from "lib/dss-interfaces/src/dss/VowAbstract.sol";
import { PotHelper   } from "lib/dss-interfaces/src/dss/PotHelper.sol";

contract Hevm {
    function warp(uint256) public;
}

contract HadaikenTest is DSTest {
    Hadaiken hadaiken;
    Hevm hevm;

    // CHEAT_CODE = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D
    bytes20 constant CHEAT_CODE =
        bytes20(uint160(uint256(keccak256('hevm cheat code'))));

    address constant internal JUG = address(0x19c0976f590D67707E62397C87829d896Dc0f1F1);
    address constant internal POT = address(0x197E90f9FAD81970bA7976f33CbD77088E5D7cf7);
    address constant internal VAT = address(0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B);
    address constant internal VOW = address(0xA950524441892A31ebddF91d3cEEFa04Bf454466);

    JugAbstract constant internal jug  = JugAbstract(JUG);
    PotAbstract constant internal pot  = PotAbstract(POT);
    VowAbstract constant internal vow  = VowAbstract(VOW);
    VatAbstract constant internal vat  = VatAbstract(VAT);

    function setUp() public {
        hadaiken = new Hadaiken();
        hevm = Hevm(address(CHEAT_CODE));
        hevm.warp(now);
    }

    function testHeal() public {
        hevm.warp(now + 2 days);
        pot.drip();
        jug.drip("ETH-A");
        jug.drip("BAT-A");
        assert((vat.sin(VOW) - vow.Sin() - vow.Ash()) > 0);
        hadaiken.heal();
        assertEq((vat.sin(VOW) - vow.Sin() - vow.Ash()), 0);
    }

    function testCanHealSuccessively() public {
        assert((vat.sin(VOW) - vow.Sin() - vow.Ash()) > 0);
        hadaiken.heal();
        hadaiken.heal();
        hadaiken.heal();
        assertEq((vat.sin(VOW) - vow.Sin() - vow.Ash()), 0);
    }

    function testHealWithoutDrip() public {
        hevm.warp(now + 2 days);
        assert((vat.sin(VOW) - vow.Sin() - vow.Ash()) > 0);
        hadaiken.heal();
        assertEq((vat.sin(VOW) - vow.Sin() - vow.Ash()), 0);
    }

    function testHealStat() public {
        uint256 debt = (vat.sin(VOW) - vow.Sin() - vow.Ash());
        assertEq(hadaiken.healStat(), debt);
    }

    function testRawSysDebt() public {
        uint256 rsd = hadaiken.rawSysDebt();
        assert(rsd > 0);
        hevm.warp(now + 2 days);
        assertEq(hadaiken.rawSysDebt(), rsd);
        pot.drip();
        assert(hadaiken.rawSysDebt() > rsd);
        hadaiken.heal();
        assertEq(hadaiken.rawSysDebt(), 0);
    }

    function testSysSurplus() public {
        assert(hadaiken.sysSurplus() > 0);
    }

    function testBumppable() public {
        assertTrue(!hadaiken.bumppable());
        hevm.warp(now + 20 days);
        pot.drip();
        jug.drip("ETH-A");
        jug.drip("BAT-A");
        hadaiken.heal();
        assertTrue(hadaiken.bumppable());
    }

    function testCCCComboBreaker() public {
        hevm.warp(now + 20 days);
        assert(hadaiken.rawSysDebt() > 0);
        pot.drip();
        jug.drip("ETH-A");
        jug.drip("BAT-A");
        hadaiken.heal();
        assertTrue(hadaiken.bumppable());
        uint256 id = hadaiken.ccccombobreaker();
        assertEq(id, 0);
        assertEq(hadaiken.rawSysDebt(), 0);
    }

    function testHadaiken() public {
        hevm.warp(now + 20 days);
        assert(hadaiken.rawSysDebt() > 0);
        hadaiken.hadaiken();
        assertEq(hadaiken.rawSysDebt(), 0);
    }
}
