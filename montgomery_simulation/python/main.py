"""This module contains code to simulate a RSA cryptosystem."""

import math
import logging


def eulers_totient_function(a: int, b: int):
    """Calculate the eulers totient function from two integers"""
    return (a - 1) * (b - 1)


def find_valid_exponent(p, q):
    """Find valid exponent from chosen p and q"""

    for e in range(2, eulers_totient_function(p, q)):
        gcd = math.gcd(eulers_totient_function(p, q), e)

        if gcd == 1:
            break
    else:
        raise ValueError("No valid exponent found")

    return e


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


def chunk_bytearray(data, n):
    for i in range(0, len(data), n):
        yield data[i : i + n]


def rsa_crypt(M: int, e: int, n: int):
    """Encrypt using RSA methodology"""
    return (M**e) % n


def rsa_decrypt(C: int, d: int, n: int):
    """Decrypt using RSA methodology"""
    return (C**d) % n


def encrypt_from_bytearray(
    message: bytearray, e: int, n: int, *, endianness: str = "little"
):
    """Use RSA to encrypt a message"""

    logging.info(f"Encrypting message: {message}")

    secret_message = b""
    for b in message:
        raw_crypt = rsa_crypt(b, e, n)
        secret_message += raw_crypt.to_bytes(
            math.ceil(math.log2(n)), byteorder=endianness
        )

    return secret_message


def decrypt_from_bytearray(
    message: bytearray, d: int, n: int, *, endianness: str = "little"
):
    """Use RSA to decrypt a message"""

    logging.info(f"Decrypting message: {message}")

    recovered_message = b""
    for chunk in chunk_bytearray(message, int(math.ceil(math.log2(n)))):
        b = int.from_bytes(chunk, byteorder=endianness)
        raw_crypt = rsa_decrypt(b, d, n)
        recovered_message += raw_crypt.to_bytes(1, byteorder=endianness)

    return recovered_message


def main():
    """Run main procedure"""
    q = 53
    p = 61

    n = p * q

    # Find a suitable exponent
    e = find_valid_exponent(p, q)

    # Calculate d the modular multiplicative inverse of e modulo Phi(n).
    # The extended euclidian algorithm is a fast way of finding this.
    gcd, d, _ = gcd_extended(e, eulers_totient_function(p, q))

    # if d is negative, add Phi(n) to get a positive value
    if d < 0:
        d += eulers_totient_function(p, q)

    # Print the relevant values calculated
    print(f"p: {p}", f"q: {q}", f"n: {n}", f"e: {e}", f"d: {d}")

    message = b"Hey there, how are you doing on a fine day like this?"
    print(f"Original message {message}")
    secret_message = encrypt_from_bytearray(message, e, n)
    print(f"Secret message {secret_message}")
    recovered_message = decrypt_from_bytearray(secret_message, d, n)
    print(f"Decrypted message: {recovered_message}")


if __name__ == "__main__":
    """Run main method"""
    main()
