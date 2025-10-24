import logging

import pytest

from generate_rsa_key_values import get_rsa_key_values
from montgomery_monpro_cios import to_limbs, carry_sum, montgomery_monpro_cios
from montgomery import montgomery_monpro

from key_values import KEY_N, KEY_D, KEY_E, LAB_MESSAGE, EXPECTED_ENCODED

logger = logging.getLogger(__name__)


@pytest.mark.parametrize("x, s, w", [(0xDEAD, 4, 4), (0xDEAD, 8, 2), (0xDEAD, 2, 8)])
def test_to_limbs(x: int, s: int, w: int):
    """Check if x is splitted into 's' limbs with width 'w'."""

    out = to_limbs(x, s=s, width=w)

    assert out[0] == (x & (2**w - 1))
    assert out.shape == (s,)


@pytest.mark.parametrize("a, b", [(45321, 1234), (6323, 6324), (0xdead, 0xbeef)])
def test_montgomery_monpro(a, b):
    """Test the standard implementation of montgomery monpro"""

    key_values = get_rsa_key_values(KEY_N, 256)

    ans = montgomery_monpro(a, b, key_values)
    expected_ans = (a * b * key_values.r_inv) % key_values.n

    logger.info(f"montgomery product: {hex(ans)}")

    assert ans == expected_ans


def test_montgomery_monpro_cios():
    """Test the CIOS implementation of the montgomery monpro algorithm"""
