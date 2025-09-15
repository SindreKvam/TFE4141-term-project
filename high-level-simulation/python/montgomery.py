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
    word_size = 8
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
    n_0_prime = -x

    # Check if valid:
    # (n * n_0' + 1) mod R = 0
    assert (n * n_0_prime + 1) % r == 0


    # encoded = montgomery_modexp(7, 10, n)) # n=13, r=2^4 should return 4
    encoded = montgomery_modexp(69, 7, n)
    print(encoded)
    decoded = montgomery_modexp(encoded, 103, n)
    print(decoded)
