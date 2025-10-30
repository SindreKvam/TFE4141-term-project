import logging

import numpy as np

from generate_rsa_key_values import RsaKeyValues, get_rsa_key_values
from montgomery_monpro_cios import carry_sum, to_limbs, from_limbs

logger = logging.getLogger(__name__)


def alpha(a, b, C_in, S_in, w) -> tuple[int, int]:
    """Alpha cell of the systolic array"""

    return carry_sum(S_in, a, b, C_in, width=w)


def beta(S_in, n_0, n_0_prime, w):
    """Beta cell of the systolic array"""

    _, m = carry_sum(0, S_in, n_0_prime, 0, width=w)
    C, _ = carry_sum(S_in, n_0, m, 0, width=w)

    return C, m


def gamma(n_i, m, C_in, S_in, w):
    """Gamma cell of the systolic array"""

    return carry_sum(S_in, n_i, m, C_in, width=w)


def alpha_final(C_in, S_in, w):
    """Final alpha cell of the systolic array"""

    return carry_sum(S_in, 0, 0, C_in, width=w)


def gamma_final(C_in, S1_in, S2_in, w):
    """Final gamma cell of the systolic array"""

    S2, S1 = carry_sum(S1_in, 0, 0, C_in, width=w)
    S2 += S2_in

    return S1, S2


def montgomery_monpro_cios_systolic_array(a, b, w, s, n, n_prime):
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

    # Create array T to store all intermediate results
    T = np.zeros(s + 2)

    for i in range(s):
        C = 0

        for j in range(s):
            C, T[j] = alpha(a[j], b[i], T[j], C, w=w)

        T[s + 1], T[s] = alpha_final(C, T[s], w=w)

        C, m = beta(T[0], n[0], n_prime[0], w=w)

        for j in range(1, s):
            C, T[j - 1] = gamma(n[j], m, C, T[j], w=w)

        T[s - 1], T[s] = gamma_final(C, T[s], T[s + 1], w=w)

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
        montgomery_monpro_cios_systolic_array(
            M, key_values.r2_mod_n, w, s, n, key_values.n_0_prime
        ),
        w,
    )
    C_bar = from_limbs(
        montgomery_monpro_cios_systolic_array(
            1, key_values.r2_mod_n, w, s, n, key_values.n_0_prime
        ),
        w,
    )

    binary_e = f"{e:b}".zfill(k)
    for bit in binary_e:
        bit = int(bit)

        C_bar = from_limbs(
            montgomery_monpro_cios_systolic_array(
                C_bar, C_bar, w, s, n, key_values.n_0_prime
            ),
            w,
        )
        if bit == 1:
            C_bar = from_limbs(
                montgomery_monpro_cios_systolic_array(
                    M_bar, C_bar, w, s, n, key_values.n_0_prime
                ),
                w,
            )
    return from_limbs(
        montgomery_monpro_cios_systolic_array(C_bar, 1, w, s, n, key_values.n_0_prime),
        w,
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
