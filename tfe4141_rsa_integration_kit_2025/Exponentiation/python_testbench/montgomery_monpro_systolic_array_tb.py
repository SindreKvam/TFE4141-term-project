"""CocoTB testbench for montgomery monpro implementation"""

import logging

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
from montgomery_monpro_cios import to_limbs

logger = logging.getLogger(__name__)

CLK_FREQUENCY_HZ = 100e6
CLK_PERIOD_S = 1 / CLK_FREQUENCY_HZ
CLK_PERIOD_NS = CLK_PERIOD_S * 1e9


# Values used during testing in the LAB
LAB_KEY_N = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D
LAB_KEY_N_PRIME = 0x8833C3BB
LAB_INPUT_A = 0x0000000011111111222222223333333344444444555555556666666677777777
LAB_INPUT_B = 0x56DDF8B43061AD3DBCD1757244D1A19E2E8C849DDE4817E55BB29D1C20C06364
LAB_EXPECTED_RESULT = 0x8ABE76B2CF6E603497A8BA867EDDC580B943F5690777E388FAE627E05449851A

EXPECTED_BETA_M = [
    0x150EA394,
    0x5257A149,
    0x3F146A58,
    0x907D544E,
    0x195752EE,
    0xBF39F894,
    0x1162587E,
    0xE748676F,
]


@cocotb.test()
async def test_loading_input(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Load input values
    dut.n.value = LAB_KEY_N
    dut.n_prime.value = LAB_KEY_N_PRIME
    dut.a.value = LAB_INPUT_A
    dut.b.value = LAB_INPUT_B

    while int(dut.in_ready.value) == 0:
        await RisingEdge(dut.clk)

    dut.in_valid.value = 1
    await RisingEdge(dut.clk)
    dut.in_valid.value = 0

    await RisingEdge(dut.clk)

    s_a = [hex(int(val)) for val in dut.s_a.value]
    s_a_expected = [hex(int(val)) for val in to_limbs(LAB_INPUT_A, 8, 32)]

    s_b = [hex(int(val)) for val in dut.s_b.value]
    s_b_expected = [hex(int(val)) for val in to_limbs(LAB_INPUT_B, 8, 32)]

    assert s_a == s_a_expected, "Input not loaded successfully"
    assert s_b == s_b_expected, "Input not loaded successfully"

    dut._log.info(f"s_a: {s_a}")
    dut._log.info(f"s_a_expected: {s_a_expected}")
    dut._log.info(f"s_b: {s_b}")
    dut._log.info(f"s_b_expected: {s_b_expected}")


@cocotb.test()
@cocotb.parametrize(
    test_data=[
        (LAB_INPUT_A, LAB_INPUT_B, LAB_EXPECTED_RESULT),
        (
            0x8ABE76B2CF6E603497A8BA867EDDC580B943F5690777E388FAE627E05449851A,
            0x61DD65C6CF9D5CDAC7A55013F065678E4580B069817FA98DBB772EDA623B92FC,
            0x6261B7082F228B5C46106884D6ED9D3177D09D2DE0CA87FAE1E80AA5A0966312,
        ),
        (
            0x6261B7082F228B5C46106884D6ED9D3177D09D2DE0CA87FAE1E80AA5A0966312,
            0x1,
            0x23026C469918F5EA097F843DC5D5259192F9D3510415841CE834324F4C237AC7,
        ),
    ],
)
async def test_lab_results(dut, test_data):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    a, b, result = test_data

    dut.rst_n.value = 0
    dut.in_valid.value = 0

    await Timer(5, unit="ns")
    await RisingEdge(dut.clk)
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)

    # Load input values
    dut.n.value = LAB_KEY_N
    dut.n_prime.value = LAB_KEY_N_PRIME
    dut.a.value = a
    dut.b.value = b

    assert a < LAB_KEY_N
    assert b < LAB_KEY_N

    while int(dut.in_ready.value) == 0:
        await RisingEdge(dut.clk)

    dut.in_valid.value = 1
    await RisingEdge(dut.clk)
    dut.in_valid.value = 0

    # Input has been loaded
    await RisingEdge(dut.clk)

    for _ in range(34):
        await RisingEdge(dut.clk)

    dut._log.info("Output value: \t\t 0x%X", dut.u.value)
    dut._log.info("Expected output value: \t 0x%X", result)
    assert dut.u.value == result
