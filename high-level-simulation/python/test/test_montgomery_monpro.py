import logging

import pytest
import numpy as np

from generate_rsa_key_values import get_rsa_key_values, RsaKeyValues
from montgomery_monpro_cios import to_limbs, carry_sum, montgomery_monpro_cios
from montgomery import montgomery_monpro

from key_values import KEY_N, KEY_D, KEY_E, LAB_MESSAGE, EXPECTED_ENCODED


logger = logging.getLogger(__name__)


@pytest.fixture
def key_values() -> RsaKeyValues:
    _rsa_key_values = get_rsa_key_values(KEY_N, 256)

    logger.debug("RSA Key values:\n")
    logger.debug(_rsa_key_values)

    yield _rsa_key_values


@pytest.mark.parametrize(
    "x, s, w",
    [
        (0xDEAD, 4, 4),
        (0xDEAD, 8, 2),
        (0xDEAD, 2, 8),
        (LAB_MESSAGE, 256, 1),
        (LAB_MESSAGE, 128, 2),
        (LAB_MESSAGE, 16, 16),
    ],
)
def test_to_limbs(x: int, s: int, w: int):
    """Check if x is splitted into 's' limbs with width 'w'."""

    logger.info(f"Splitting {hex(x)} into {s} limbs with width of {w} bits")

    out = to_limbs(x, s=s, width=w)

    logger.info(f"Output limbs: {[hex(o) for o in out]}")

    assert out[-1] == (x & (2**w - 1))
    assert out.shape == (s,)


@pytest.mark.parametrize(
    "a, b",
    [
        (0xBADEBABE, 0xDEADBEEF),
        (0xDEAD, 0xBEEF),
        (LAB_MESSAGE, EXPECTED_ENCODED),
    ],
)
def test_montgomery_monpro(a, b, key_values):
    """Test the standard implementation of montgomery monpro"""

    logger.info(
        "Running test with standard implementation of montgomery monpro algorithm"
    )

    logger.info(f"Calculating {hex(a)} * {hex(b)} mod {hex(key_values.n)}")

    ans = montgomery_monpro(a, b, key_values)
    expected_ans = (a * b * key_values.r_inv) % key_values.n

    logger.info(f"montgomery product: {hex(ans)}")
    logger.info(f"expected montgomery product: {hex(expected_ans)}")

    assert ans == expected_ans


@pytest.mark.parametrize(
    "a, b",
    [
        (0xBADEBABE, 0xDEADBEEF),
        (0xDEAD, 0xBEEF),
        (LAB_MESSAGE, EXPECTED_ENCODED),
    ],
)
def test_montgomery_monpro_cios(a, b, key_values, w=16, s=16):
    """Test the CIOS implementation of the montgomery monpro algorithm"""

    assert w * s == 256

    logger.info("Running test with CIOS implementation")

    logger.info(f"Calculating {hex(a)} * {hex(b)} mod {hex(key_values.n)}")

    a = to_limbs(a, s, w)
    b = to_limbs(b, s, w)
    R = to_limbs(key_values.r, s, w)
    p = to_limbs(key_values.n, s, w)
    p_prime = to_limbs(key_values.n_0_prime, s, w)

    ans = montgomery_monpro_cios(a, b, key_values.r, w, s, p, key_values.n_0_prime)
    expected_ans = np.array(
        [(a[i] * b[i] * key_values.r_inv) % key_values.n for i in range(s)]
    )

    logger.info(f"montgomery product: {[hex(int(a)) for a in ans]}")
    logger.info(f"expected montgomery product: {[hex(int(a)) for a in expected_ans]}")

    assert ans.all(expected_ans)
