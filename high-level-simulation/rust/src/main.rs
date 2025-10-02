#[derive(Debug)]
struct RsaKeyValues {
    n: i64,
    n_0_prime: i64,
    word_size: i64,
    r: i64,
    r2_mod_n: i64,
    e: i64,
    d: i64,
}

fn gcd_extended(a: i64, b: i64) -> (i64, i64, i64) {
    if a == 0 {
        return (b, 0, 1);
    }

    let (gcd, x1, y1) = gcd_extended(b % a, a);

    let x: i64 = y1 - (b / a) * x1;
    let y: i64 = x1;

    (gcd, x, y)
}

fn gcd_ensure_positive_x(a: i64, b: i64) -> (i64, i64, i64) {
    let (gcd, mut x, y) = gcd_extended(a, b);
    if x < 0 {
        x = x + b;
    }

    (gcd, x, y)
}

fn montgomery_monpro(a: i64, b: i64, key_values: &RsaKeyValues) -> i64 {
    let t = a * b;
    let m = t * key_values.n_0_prime % key_values.r;
    let u = (t + m * key_values.n) >> key_values.word_size;

    if u >= key_values.n {
        return u - key_values.n;
    }
    u
}

fn montgomery_modexp(m: i64, e: i64, key_values: &RsaKeyValues) -> i64 {
    let m_bar = montgomery_monpro(m, key_values.r2_mod_n, key_values);
    let mut x_bar = key_values.r % key_values.n;

    for n in (0..key_values.word_size).rev() {
        let bit = (e >> n) & 1;

        x_bar = montgomery_monpro(x_bar, x_bar, key_values);
        if bit == 1 {
            x_bar = montgomery_monpro(m_bar, x_bar, key_values);
        }
    }
    return montgomery_monpro(x_bar, 1, key_values);
}

fn main() {
    let word_size = 16;

    // Define constants to be used for calculating RSA
    // using montgomery exponentiation
    // let r = 2^w
    let r = 1 << word_size;
    let n = 143;

    // Make sure that n is an odd number.
    assert_eq!(n % 2, 1);

    let (gcd, x, _) = gcd_ensure_positive_x(n, r);
    let n_0_prime = r - x;

    // gcd(r,n) = 1
    assert_eq!(gcd, 1);
    // Make sure that n_0' is valid
    assert_eq!((n * n_0_prime + 1) % r, 0);

    let key_values = RsaKeyValues {
        r: r,
        n: n,
        r2_mod_n: (r * r) % n,
        n_0_prime: n_0_prime,
        word_size: word_size,
        d: 103,
        e: 7,
    };

    println!("{:?}", key_values);

    let original_message = 130;

    // Message cannot be larger than n
    assert!(original_message < n);

    println!("Original message {}", original_message);
    let encrypted_message = montgomery_modexp(original_message, key_values.e, &key_values);
    println!("Encrypted message {}", encrypted_message);
    let decrypted_message = montgomery_modexp(encrypted_message, key_values.d, &key_values);
    println!("Decrypted message {}", decrypted_message);
}
