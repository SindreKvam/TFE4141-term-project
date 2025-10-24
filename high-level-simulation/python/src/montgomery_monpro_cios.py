import logging

import numpy as np

from generate_rsa_key_values import RsaKeyValues, get_rsa_key_values

logger = logging.getLogger(__name__)


def carry_sum(a, x, y, b, width=16):
    """
    Calculate carry and sum from a + x*y + b
    """

    bitmask = (1 << width) - 1
    calculated_value = a + x * y + b
    s = calculated_value & bitmask
    c = calculated_value >> width

    return c, s


def to_limbs(x, s, width) -> np.ndarray:
    """
    Split x to 's' limbs of width 'width'
    """

    _arr = np.zeros(s)

    bitmask = 2**width - 1

    for index, limb in enumerate(range(0, s * width, width)):
        _arr[index] = (x & bitmask) >> limb

        bitmask = bitmask << width

    logger.debug(f"x: {x} to limbs: {_arr}")

    return _arr


def montgomery_monpro_cios(a, b, R, w, s, p, p_prime):
    """
    Perform the montgomery mod multiplication using the CIOS algorithm

    a * b * R^(-1) mod p

    Arguments:
        - a: input 1
        - b: input 2
        - R: 2 ^ K (where K = w*s)
        - w: word size
        - s: number of words
    """

    # K = s * w

    # Create array T to store all intermediate results
    T = np.zeros(s + 2)

    for i in range(s):
        C = 0

        for j in range(s):
            C, S = carry_sum(T[j], a[i], b[j], C, width=w)
            T[j] = S

        C, S = carry_sum(T[s], 0, 0, C, width=w)
        T[s] = S
        T[s + 1] = C

        C = 0
        m = T[0] * p_prime % 2**w
        C, S = carry_sum(T[0], m, p[0], 0, width=w)

        for j in range(1, s):
            C, S = carry_sum(T[j], m, p[j], C, width=w)
            T[j] = S

        C, S = carry_sum(T[s], 0, 0, C, width=w)
        T[s - 1] = S
        T[s] = T[s + 1] + C

    return T


def montgomery_modexp(M, e, n, key_values: RsaKeyValues):
    """
    Perform montgomery exponentiation to find the solution to
    X = M^e mod n
    """

    M_bar = montgomery_monpro_cios(M, key_values.r2_mod_n, key_values)
    C_bar = montgomery_monpro_cios(1, key_values.r2_mod_n, key_values)

    binary_e = f"{e:b}".zfill(key_values.word_size)
    for bit in binary_e:
        bit = int(bit)

        C_bar = montgomery_monpro_cios(C_bar, C_bar, key_values)
        if bit == 1:
            C_bar = montgomery_monpro_cios(M_bar, C_bar, key_values)

    return montgomery_monpro_cios(C_bar, 1, key_values)


if __name__ == "__main__":
    k = 256
    word_size = 16
    num_limbs = k // word_size

    n = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D

    rsa_key_values = get_rsa_key_values(n, word_size, num_limbs)

    e = 0x0000000000000000000000000000000000000000000000000000000000010001
    d = 0x0CEA1651EF44BE1F1F1476B7539BED10D73E3AAC782BD9999A1E5A790932BFE9

    print(rsa_key_values)

    original_message = to_limbs(
        0x0000000011111111222222223333333344444444555555556666666677777777,
        num_limbs,
        word_size,
    )

    encoded = montgomery_modexp(original_message, e, n, rsa_key_values)
    decoded = montgomery_modexp(encoded, d, n, rsa_key_values)

    assert decoded == original_message
