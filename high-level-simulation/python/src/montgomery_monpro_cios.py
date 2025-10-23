import numpy as np


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
    Split x to 's' limbs
    """

    _arr = np.ndarray(shape=(width, s))
    for index, limb in enumerate(range(0, s * width, width)):
        _arr[index] = limb

    return _arr


def montgomery_monpro_cios(a, b, R, w, s, p, p_prime):
    """
    Perform the montgomery mod multiplication using the CIOS algorithm
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
