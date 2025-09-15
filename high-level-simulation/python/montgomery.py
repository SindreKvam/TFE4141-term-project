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

    M_bar = M * r % n
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
    n = 0x008E4926DB131F8ADAFFD7806AF801E0CDB607DEA857441D059514F8E0D9CAEE01
    assert math.gcd(r, n) == 1
    assert n % 2 != 0

    # Precompute n_0 = -n^(-1) (mod R)
    # nx + Ry = gcd(n, R)
    # nx = 1 (mod R)
    # n^(-1) = x (mod R)
    # n_0' = -n^(-1) = -x (mod R)
    gcd, x, _ = gcd_extended_ensure_positive_x(n, r)
    n_0_prime = -x

    # Check if valid:
    # (n * n_0' + 1) mod R = 0
    assert (n * n_0_prime + 1) % r == 0

    e = 0x10001
    d = 0x2DFCDAC027F823EB1091D881BA52F1134E30FBBF6DCFCDA2343B7592D29F0001
    original_message = 0x48656C6C6F2074686572652E2047656E6572616C204B656E6F62692E

    print(f"Original message {hex(original_message)}")
    encoded = montgomery_modexp(original_message, e, n)
    print(f"Encoded message {hex(encoded)}")
    decoded = montgomery_modexp(encoded, d, n)
    print(f"Decoded message {hex(decoded)}")

    assert original_message == decoded
