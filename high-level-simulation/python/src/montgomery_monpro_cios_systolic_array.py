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

    valid_num_limbs = [8, 16]
    if s not in valid_num_limbs:
        raise NotImplementedError(
            f"Only systolic arrays of size {valid_num_limbs} are implemented."
        )

    a = to_limbs(a, s, w)
    b = to_limbs(b, s, w)
    n = to_limbs(n, s, w)
    n_prime = to_limbs(n_prime, s, w)

    print("-" * 50)
    for arr in [a, b, n, n_prime]:
        print([hex(val) for val in arr])
    print("-" * 50)

    alpha_carry = alpha_sum = np.zeros(shape=(s + 1,))
    beta_carry = beta_sum = 0
    gamma_carry = gamma_sum = np.zeros(shape=(s + 2,))

    for limb_index in range(s):
        for word_index in range(w + 1):
            i = limb_index
            j = word_index

            if word_index < w:
                alpha_carry[j + 1], alpha_sum[j + 1] = alpha(
                    a[i], b[j], alpha_carry[j], alpha_sum[j], w=w
                )
                # print(alpha_carry[j + 1], alpha_sum[j + 1])

            if word_index == 1:
                beta_carry, beta_sum = beta(alpha_sum[j], n[0], n_prime[0], w=w)

            elif word_index == 2:
                gamma_carry[j + 1], gamma_sum[j + 1] = gamma(
                    n[i], beta_sum, beta_carry, alpha_sum[j], w=w
                )

            elif word_index == w - 1:
                alpha_carry[j + 1], alpha_sum[j + 1] = alpha_final(
                    alpha_carry[j], alpha_sum[j], w=w
                )

            elif word_index == w:
                gamma_carry[j + 1], gamma_sum[j + 1] = gamma_final(
                    gamma_carry[j], gamma_sum[j], alpha_sum[j], w=w
                )

            elif word_index > 2:
                gamma_carry[j + 1], gamma_sum[j + 1] = gamma(
                    n[i], gamma_sum[j], 0, 0, w=w
                )

        print("-" * 50)
        print(f"Alpha sum: {[hex(int(val)) for val in alpha_sum]}")
        print(f"Alpha carry: {[hex(int(val)) for val in alpha_carry]}")
        print(f"Gamma sum: {[hex(int(val)) for val in gamma_sum]}")
        print(f"Gamma carry: {[hex(int(val)) for val in gamma_carry]}")
        print("-" * 50)

        if limb_index > 1:
            exit()


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
            M, key_values.r2_mod_n, w, s, n, key_values.n_0_prime
        ),
        w(1, key_values.r2_mod_n, w, s, n, key_values.n_0_prime),
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
