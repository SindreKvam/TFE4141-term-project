"""CocoTB testbench for montgomery modexp implementation"""

import logging

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

logger = logging.getLogger(__name__)

CLK_FREQUENCY_HZ = 100e6
CLK_PERIOD_S = 1 / CLK_FREQUENCY_HZ
CLK_PERIOD_NS = CLK_PERIOD_S * 1e9

# Values used during testing in the LAB
LAB_MESSAGE = 0x0000000011111111222222223333333344444444555555556666666677777777
LAB_KEY_ENCRYPT = 0x0000000000000000000000000000000000000000000000000000000000010001
LAB_KEY_DECRYPT = 0x0CEA1651EF44BE1F1F1476B7539BED10D73E3AAC782BD9999A1E5A790932BFE9
LAB_KEY_N = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D
LAB_KEY_N_PRIME = 0xCEC4F7862F7488BC9635DA7471B8A8DE5DA7FB55C04749FFA617A7468833C3BB
LAB_KEY_R_SQUARED_MOD_N = (
    0x56DDF8B43061AD3DBCD1757244D1A19E2E8C849DDE4817E55BB29D1C20C06364
)
LAB_EXPECTED_ENCRYPTED_MESSAGE = (
    0x23026C469918F5EA097F843DC5D5259192F9D3510415841CE834324F4C237AC7
)


@cocotb.test()
@cocotb.parametrize(
    test_data=[
        (LAB_KEY_ENCRYPT, LAB_MESSAGE, LAB_EXPECTED_ENCRYPTED_MESSAGE),
        (LAB_KEY_DECRYPT, LAB_EXPECTED_ENCRYPTED_MESSAGE, LAB_MESSAGE),
        (
            LAB_KEY_ENCRYPT,
            0x8888888899999999AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFF,
            0x4DD5E8DFDA5DA31A8881B3FDD37DD9F3A5009F1354CD078E5C2C49B54CCB5F3F,
        ),
        (
            LAB_KEY_DECRYPT,
            0x4DD5E8DFDA5DA31A8881B3FDD37DD9F3A5009F1354CD078E5C2C49B54CCB5F3F,
            0x8888888899999999AAAAAAAABBBBBBBBCCCCCCCCDDDDDDDDEEEEEEEEFFFFFFFF,
        ),
    ]
)
async def test_encryptdecrypt(dut, test_data):
    cocotb.start_soon(Clock(dut.clk, CLK_PERIOD_NS, unit="ns").start())

    key, message, expected_message = test_data

    # dut.reset_n.value = 0
    await RisingEdge(dut.clk)
    dut.reset_n.value = 1
    await RisingEdge(dut.clk)

    dut.message.value = message
    dut.key.value = key
    dut.n.value = LAB_KEY_N
    dut.n_prime.value = LAB_KEY_N_PRIME
    dut.r_stuff.value = LAB_KEY_R_SQUARED_MOD_N

    while int(dut.ready_in.value) == 0:
        await RisingEdge(dut.clk)

    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0

    await RisingEdge(dut.clk)

    await RisingEdge(dut.valid_out)

    dut._log.info("Output value: 0x%X", dut.result.value)
    dut._log.info("Expected output value: 0x%X", expected_message)

    assert dut.result.value == expected_message

    # Make sure DUT goes back into ST_IDLE
    dut.ready_out.value = 1
    await RisingEdge(dut.clk)
    dut.ready_out.value = 0
