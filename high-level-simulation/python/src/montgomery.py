import math

from generate_rsa_key_values import RsaKeyValues, get_rsa_key_values


def montgomery_monpro(a, b, key_values: RsaKeyValues):
    """
    Perform the montgomery mod multiplication
    All inputs are k-bit numbers
    """
    t = a * b
    m = t * key_values.n_0_prime % key_values.r
    # bitshift to the right instead of dividing by r
    u = (t + m * key_values.n) >> int(math.log2(key_values.r))

    if u >= n:
        return u - key_values.n
    return u


def montgomery_modexp(M, e, n, key_values: RsaKeyValues):
    """
    Perform montgomery exponentiation to find the solution to
    X = M^e mod n
    """

    M_bar = montgomery_monpro(M, key_values.r2_mod_n, key_values)
    C_bar = montgomery_monpro(1, key_values.r2_mod_n, key_values)

    binary_e = f"{e:b}".zfill(word_size)
    for bit in binary_e:
        bit = int(bit)

        C_bar = montgomery_monpro(C_bar, C_bar, key_values)
        if bit == 1:
            C_bar = montgomery_monpro(M_bar, C_bar, key_values)
    return montgomery_monpro(C_bar, 1, key_values)


if __name__ == "__main__":
    word_size = 256
    n = 0x99925173AD65686715385EA800CD28120288FC70A9BC98DD4C90D676F8FF768D

    rsa_key_values = get_rsa_key_values(n, word_size)

    e = 0x0000000000000000000000000000000000000000000000000000000000010001
    d = 0x0CEA1651EF44BE1F1F1476B7539BED10D73E3AAC782BD9999A1E5A790932BFE9

    print(rsa_key_values)

    original_message = (
        0x0000000011111111222222223333333344444444555555556666666677777777
    )

    # With the keys and message that will be used for this LAB (as shown above)
    # The expected cryptated message is:
    # 0x23026c469918f5ea097f843dc5d5259192f9d3510415841ce834324f4c237ac7

    print(f"Original message {hex(original_message)}")
    encoded = montgomery_modexp(original_message, e, n, rsa_key_values)
    print(f"Encoded message {hex(encoded)}")
    assert encoded == 0x23026C469918F5EA097F843DC5D5259192F9D3510415841CE834324F4C237AC7
    decoded = montgomery_modexp(encoded, d, n, rsa_key_values)
    print(f"Decoded message {hex(decoded)}")
    assert decoded == original_message
