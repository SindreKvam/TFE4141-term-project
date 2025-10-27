import pytest
import logging

from generate_rsa_key_values import get_rsa_key_values

from montgomery import montgomery_modexp

logger = logging.getLogger(__name__)


# Keys used in LAB
KEY_N = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D
KEY_E = 0x0000000000000000000000000000000000000000000000000000000000010001
KEY_D = 0x0CEA1651EF44BE1F1F1476B7539BED10D73E3AAC782BD9999A1E5A790932BFE9

LAB_MESSAGE = 0x0000000011111111222222223333333344444444555555556666666677777777
EXPECTED_ENCODED = 0x23026C469918F5EA097F843DC5D5259192F9D3510415841CE834324F4C237AC7


def test_rsa_montgomery():
    """Test RSA with montgomery modexp algorithm
    using standard montgomery monpro"""

    n = KEY_N
    e = KEY_E
    d = KEY_D

    rsa_key_values = get_rsa_key_values(n, word_size=256)

    original_message = LAB_MESSAGE

    encoded = montgomery_modexp(original_message, e, n, rsa_key_values)
    decoded = montgomery_modexp(encoded, d, n, rsa_key_values)

    logger.info(f"Original message: {hex(original_message)}")
    logger.info(f"Encoded message: {hex(encoded)}")
    logger.info(f"Decoded message: {hex(decoded)}")

    # Using the keys and message that will be used in the LAB
    # Then the expected encrypted message is:
    assert encoded == EXPECTED_ENCODED
    assert original_message == decoded


def test_rsa_montgomery_cios():
    """Test RSA with montgomery modexp algorithm
    using CIOS monthomery monpro algorithm"""
