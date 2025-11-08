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
async def test_lab_results(dut):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    dut.rst_n.value = 0
    dut.in_valid.value = 0

    await Timer(5, unit="ns")
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

    # Input has been loaded
    await RisingEdge(dut.clk)

    for _ in range(34):
        await RisingEdge(dut.clk)

    dut._log.info("Output value: \t\t 0x%X", dut.u.value)
    dut._log.info("Expected output value: \t 0x%X", LAB_EXPECTED_RESULT)
    assert dut.u.value == LAB_EXPECTED_RESULT
