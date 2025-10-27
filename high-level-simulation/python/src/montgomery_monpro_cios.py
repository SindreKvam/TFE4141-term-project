import logging

import numpy as np

from generate_rsa_key_values import RsaKeyValues, get_rsa_key_values

logger = logging.getLogger(__name__)


def carry_sum(a: int, x: int, y: int, b: int, width=16):
    """
    Calculate carry and sum from a + x*y + b
    """

    bitmask = (1 << width) - 1
    calculated_value = int(a + x * y + b)
    s = calculated_value & bitmask
    c = calculated_value >> width

    return c, s


def to_limbs(x, s, width) -> np.ndarray:
    """
    Split x to 's' limbs of width 'width'
    """

    _arr = np.zeros(s, dtype=int)

    bitmask = 2**width - 1

    for index, limb in enumerate(range(0, s * width, width)):
        _arr[index] = (x & bitmask) >> limb

        bitmask = bitmask << width

    # logger.debug(f"x: {hex(x)} to limbs: {[hex(val) for val in _arr]}")

    return _arr


def from_limbs(x: np.ndarray, width: int) -> int:
    """Turn splitted x back into integer"""

    _value = 0

    for limb in x[::-1]:
        _value <<= width
        _value |= int(limb)

    return _value


def montgomery_monpro_cios(a, b, w, s, n, n_prime):
    """
    Perform the montgomery mod multiplication using the CIOS algorithm

    a * b * R^(-1) mod n

    Arguments:
        - a: input 1
        - b: input 2
        - w: word size
        - s: number of words
    """

    a = to_limbs(a, s, w)
    b = to_limbs(b, s, w)
    n = to_limbs(n, s, w)
    n_prime = to_limbs(n_prime, s, w)

    BITMASK = (1 << w) - 1

    # Create array T to store all intermediate results
    T = np.zeros(s + 2)

    for i in range(s):
        C = 0

        for j in range(s):
            C, T[j] = carry_sum(T[j], a[j], b[i], C, width=w)

        T[s + 1], T[s] = carry_sum(T[s], 0, 0, C, width=w)

        C = 0
        m = int(T[0] * n_prime[0]) & BITMASK  # AND instead of modulo 2^w

        C, _ = carry_sum(T[0], m, n[0], 0, width=w)
        for j in range(1, s):
            C, T[j - 1] = carry_sum(T[j], m, n[j], C, width=w)

        C, T[s - 1] = carry_sum(T[s], 0, 0, C, width=w)
        T[s] = T[s + 1] + C

    if from_limbs(T, w) >= from_limbs(n, w):
        T_int = int(from_limbs(T, w)) - from_limbs(n, w)
        T = to_limbs(T_int, s, w)

    return T


def montgomery_modexp(M, e, n, w, s, key_values: RsaKeyValues):
    """
    Perform montgomery exponentiation to find the solution to
    X = M^e mod n
    """

    k = w * s

    M_bar = from_limbs(
        montgomery_monpro_cios(M, key_values.r2_mod_n, w, s, n, key_values.n_0_prime), w
    )
    C_bar = from_limbs(
        montgomery_monpro_cios(1, key_values.r2_mod_n, w, s, n, key_values.n_0_prime), w
    )

    binary_e = f"{e:b}".zfill(k)
    for bit in binary_e:
        bit = int(bit)

        C_bar = from_limbs(
            montgomery_monpro_cios(C_bar, C_bar, w, s, n, key_values.n_0_prime), w
        )
        if bit == 1:
            C_bar = from_limbs(
                montgomery_monpro_cios(M_bar, C_bar, w, s, n, key_values.n_0_prime), w
            )
    return from_limbs(
        montgomery_monpro_cios(C_bar, 1, w, s, n, key_values.n_0_prime), w
    )


if __name__ == "__main__":
    k = 256
    word_size = 16
    num_limbs = k // word_size

    n = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D

    rsa_key_values = get_rsa_key_values(n, word_size, num_limbs)

    e = 0x0000000000000000000000000000000000000000000000000000000000010001
    d = 0x0CEA1651EF44BE1F1F1476B7539BED10D73E3AAC782BD9999A1E5A790932BFE9

    print(rsa_key_values)

    original_message = (
        0x0000000011111111222222223333333344444444555555556666666677777777
    )

    encoded = montgomery_modexp(
        original_message, e, n, word_size, num_limbs, rsa_key_values
    )
    decoded = montgomery_modexp(encoded, d, n, word_size, num_limbs, rsa_key_values)

    print(f"Original message: {hex(original_message)}")
    print(f"Encoded message: {hex(encoded)}")
    print(f"Decoded message: {hex(decoded)}")

    assert decoded == original_message
