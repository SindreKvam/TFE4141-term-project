import math


def gcd_extended(a, b):
    """Method for calculating the extended euclidean algorithm"""
    # Base Case
    if a == 0:
        return b, 0, 1

    gcd, x1, y1 = gcd_extended(b % a, a)

    # Update x and y using results of recursive
    # call
    x = y1 - (b // a) * x1
    y = x1

    return gcd, x, y


def gcd_extended_ensure_positive_x(a, b):
    gcd, x, y = gcd_extended(a, b)

    if x < 0:
        x + b

    return gcd, x, y


def montgomery_monpro(a, b):
    """
    Perform the montgomery mod multiplication
    All inputs are k-bit numbers
    """
    t = a * b
    m = t * n_0_prime % r
    # bitshift to the right instead of dividing by r
    u = (t + m * n) >> int(math.log2(r))

    if u >= n:
        return u - n
    return u


def montgomery_modexp(M, e, n):
    """
    Perform montgomery exponentiation to find the solution to
    X = M^e mod n
    """

    M_bar = montgomery_monpro(M, (r * r) % n)
    C_bar = montgomery_monpro(1, (r * r) % n)

    binary_e = f"{e:b}".zfill(word_size)
    for bit in binary_e:
        bit = int(bit)

        C_bar = montgomery_monpro(C_bar, C_bar)
        if bit == 1:
            C_bar = montgomery_monpro(M_bar, C_bar)
    return montgomery_monpro(C_bar, 1)


if __name__ == "__main__":
    word_size = 16
    limbs = 4

    # Let R = 2^w
    r = 1 << word_size

    # Ensure gcd(r,n) = 1
    # for n in range(33, r, 2):
    # if math.gcd(r, n) == 1:
    # break
    n = 143
    assert math.gcd(r, n) == 1
    assert n % 2 != 0

    # Precompute n_0 = -n^(-1) (mod R)
    # nx + Ry = gcd(n, R)
    # nx = 1 (mod R)
    # n^(-1) = x (mod R)
    # n_0' = -n^(-1) = -x (mod R)
    gcd, x, _ = gcd_extended_ensure_positive_x(n, r)
    n_0_prime = r - x
    print(f"n' is equal to: {n_0_prime}")

    # Check if valid:
    # (n * n_0' + 1) mod R = 0
    assert (n * n_0_prime + 1) % r == 0

    e = 7
    d = 103
    original_message = (
        0x0000
    )

    # With the keys and message that will be used for this LAB (as shown above)
    # The expected cryptated message is:
    # 0x23026c469918f5ea097f843dc5d5259192f9d3510415841ce834324f4c237ac7

    print(f"{'-' * 50}")
    print(f"R = {hex(r)}")
    print(f"log2(R) = {int(math.log2(r))}")
    print(f"R² mod n = {hex((r * r) % n)}")
    print(f"n = {hex(n)}")
    print(f"n' = {hex(n_0_prime)}")
    print(f"encryption key = {hex(e)}")
    print(f"decryption key = {hex(d)}")
    print(f"{'-' * 50}")

    print(f"Original message {hex(original_message)}")
    encoded = montgomery_modexp(original_message, e, n)
    print(f"Encoded message {hex(encoded)}")
    # assert encoded == 0x23026C469918F5EA097F843DC5D5259192F9D3510415841CE834324F4C237AC7
    decoded = montgomery_modexp(encoded, d, n)
    print(f"Decoded message {hex(decoded)}")
    assert decoded == original_message

    assert original_message == decoded
