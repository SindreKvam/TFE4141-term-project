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
    x_bar = r % n

    binary_e = f"{e:b}".zfill(word_size)
    for bit in binary_e:
        bit = int(bit)

        x_bar = montgomery_monpro(x_bar, x_bar)
        if bit == 1:
            x_bar = montgomery_monpro(M_bar, x_bar)
    return montgomery_monpro(x_bar, 1)


if __name__ == "__main__":
    word_size = 256
    limbs = 4

    # Let R = 2^w
    r = 1 << word_size

    # Ensure gcd(r,n) = 1
    # for n in range(33, r, 2):
    # if math.gcd(r, n) == 1:
    # break
    n = 0x99925173ad65686715385ea800cd28120288fc70a9bc98dd4c90d676f8ff768d
    assert math.gcd(r, n) == 1
    assert n % 2 != 0

    # Precompute n_0 = -n^(-1) (mod R)
    # nx + Ry = gcd(n, R)
    # nx = 1 (mod R)
    # n^(-1) = x (mod R)
    # n_0' = -n^(-1) = -x (mod R)
    gcd, x, _ = gcd_extended_ensure_positive_x(n, r)
    n_0_prime = r - x

    # Check if valid:
    # (n * n_0' + 1) mod R = 0
    assert (n * n_0_prime + 1) % r == 0

    e = 0x0000000000000000000000000000000000000000000000000000000000010001
    d = 0x0cea1651ef44be1f1f1476b7539bed10d73e3aac782bd9999a1e5a790932bfe9
    original_message = 0x0000000011111111222222223333333344444444555555556666666677777777

    # With the keys and message that will be used for this LAB (as shown above)
    # The expected cryptated message is:
    # 0x23026c469918f5ea097f843dc5d5259192f9d3510415841ce834324f4c237ac7

    print(f"{'-' * 50}")
    print(f"R = {r}")
    print(f"log2(R) = {int(math.log2(r))}")
    print(f"R² mod n = {(r * r) % n}")
    print(f"n = {n}")
    print(f"n' = {n_0_prime}")
    print(f"encryption key = {e}")
    print(f"decryption key = {d}")
    print(f"{'-' * 50}")

    print(f"Original message {hex(original_message)}")
    encoded = montgomery_modexp(original_message, e, n)
    print(f"Encoded message {hex(encoded)}")
    decoded = montgomery_modexp(encoded, d, n)
    print(f"Decoded message {hex(decoded)}")

    assert original_message == decoded
