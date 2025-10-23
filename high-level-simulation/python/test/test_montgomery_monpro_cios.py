import logging

import pytest

from montgomery_monpro_cios import to_limbs, carry_sum, montgomery_monpro_cios

logger = logging.getLogger(__name__)


@pytest.mark.parametrize("x, s, w", [(0xDEAD, 4, 4), (0xDEAD, 8, 2), (0xDEAD, 2, 8)])
def test_to_limbs(x: int, s: int, w: int):
    """Check if x is splitted into 's' limbs with width 'w'."""

    out = to_limbs(x, s=s, width=w)

    assert out[0] == (x & (2**w - 1))
    assert out.shape == (s,)
