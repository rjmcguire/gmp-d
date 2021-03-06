/** High-level wrapper for GNU Multiple Precision (MP) library.
    See also: http://www.dsource.org/projects/bindings/browser/trunk/gmp
 */
module gmp;

debug import core.stdc.stdio : printf;

// import deimos.gmp.gmp;
// import deimos.gmp.integer;

/** Arbitrary precision signed integer (Z).
 */
struct Integer
{
    import std.typecons : Unqual;

    /// Default conversion base.
    private enum defaultBase = 10;

    pragma(inline)
    @trusted pure nothrow:

    /// Convert to string in base `base`.
    string toString(int base = defaultBase) const
    {
        assert(base >= -2 && base <= -36 ||
               base >= 2 && base <= 62);
        immutable size = sizeInBase(base);
        string str = new string(size + 1); // one extra for minus sign
        __gmpz_get_str(cast(char*)str.ptr, base, _ptr);
        return str[0] == '-' ? str : str.ptr[0 .. size];
    }

    @nogc:

    /// No default construction.
    @disable this();

    /// Construct empty (undefined) from explicit `null`.
    this(typeof(null))
    {
        initialize();           // TODO remove if this is same as zero bitblit
        assert(this == Integer.init); // if this is same as default
    }

    /// Construct from `value`.
    this(long value) { __gmpz_init_set_si(_ptr, value); }
    /// ditto
    this(ulong value) { __gmpz_init_set_ui(_ptr, value); }
    /// ditto
    this(double value) { __gmpz_init_set_d(_ptr, value); } // TODO Use Optional/Nullable when value is nan, or inf

    /// Construct from `value` in base `base`.
    this(const string value, int base = 0) // TODO Use Optional/Nullable when value is nan, or inf
    {
        assert(base == 0 || base >= 2 && base <= 62);

        // @nogc variant of `toStringz` with scoped heap allocation of null-terminated C-string `stringz`
        char* stringz = cast(char*)qualifiedMalloc(value.length + 1);
        stringz[0 .. value.length] = value[];
        stringz[value.length] = '\0'; // set C null terminator

        const int status = __gmpz_init_set_str(_ptr, stringz, base);

        qualifiedFree(stringz);
        assert(status == 0, "Parameter `value` does not contain an integer");
    }

    enum useCopy = false;       // disable copy construction for now
    static if (useCopy)
    {
        this()(auto ref const Integer value)
        {
            mpz_init_set(_ptr, value._pt);
        }
    }
    else
    {
        /// Disable copy construction.
        @disable this(this);
    }

    /** Initialize internal struct.
        Cannot be called `init` as that will override builtin type property.
     */
    private void initialize()
    {
        __gmpz_init(_ptr);
    }

    /// Swap content of `this` with `rhs`.
    void swap(ref Integer rhs)
    {
        __gmpz_swap(_ptr, rhs._ptr);
    }

    /// Returns: deep copy (duplicate) of `this`.
    Integer dup() const
    {
        typeof(return) y = void;
        __gmpz_init_set(y._ptr, _ptr);
        return y;
    }

    /// Destruct `this`.
    ~this() { if (_ptr) { __gmpz_clear(_ptr); } }

    /// Returns: `true` iff `this` equals `rhs`.
    bool opEquals(const ref Integer rhs) const
    {
        return (_ptr == rhs._ptr || // fast compare
                __gmpz_cmp(_ptr, rhs._ptr) == 0);
    }
    /// ditto
    bool opEquals(in Integer rhs) const
    {
        return (_ptr == rhs._ptr || // fast compare
                __gmpz_cmp(_ptr, rhs._ptr) == 0);
    }
    /// ditto
    bool opEquals(double rhs) const { return __gmpz_cmp_d(_ptr, rhs) == 0; }
    /// ditto
    bool opEquals(long rhs) const { return __gmpz_cmp_si(_ptr, rhs) == 0; }
    /// ditto
    bool opEquals(ulong rhs) const { return __gmpz_cmp_ui(_ptr, rhs) == 0; }

    // comparison
    int opCmp(const ref Integer rhs) const { return __gmpz_cmp(_ptr, rhs._ptr); }
    int opCmp(in Integer rhs) const { return __gmpz_cmp(_ptr, rhs._ptr); }
    int opCmp(double rhs) const { return __gmpz_cmp_d(_ptr, rhs); }
    int opCmp(long rhs) const { return __gmpz_cmp_si(_ptr, rhs); }
    int opCmp(ulong rhs) const { return __gmpz_cmp_ui(_ptr, rhs); }

    /// Add `this` with `rhs`.
    Integer opBinary(string s)(const auto ref Integer rhs) const
        if (s == "+")
    {
        typeof(return) y = null;
        __gmpz_add(y._ptr, this._ptr, rhs._ptr);
        return y;
    }
    /// ditto
    Integer opBinary(string s)(ulong rhs) const
        if (s == "+")
    {
        typeof(return) y = null;
        __gmpz_add_ui(y._ptr, this._ptr, rhs);
        return y;
    }

    /// Subtract `rhs` from `this`.
    Integer opBinary(string s)(const auto ref Integer rhs) const
        if (s == "-")
    {
        typeof(return) y = null;
        __gmpz_sub(y._ptr, this._ptr, rhs._ptr);
        return y;
    }
    /// ditto
    Integer opBinary(string s)(ulong rhs) const
        if (s == "-")
    {
        typeof(return) y = null;
        __gmpz_sub_ui(y._ptr, this._ptr, rhs);
        return y;
    }

    /// Multiply with `rhs`.
    Integer opBinary(string s)(const auto ref Integer rhs) const
        if (s == "*")
    {
        typeof(return) y = null;
        __gmpz_mul(y._ptr, this._ptr, rhs._ptr);
        return y;
    }
    /// ditto
    Integer opBinary(string s)(long rhs) const
        if (s == "*")
    {
        typeof(return) y = null;
        __gmpz_mul_si(y._ptr, this._ptr, rhs);
        return y;
    }
    /// ditto
    Integer opBinary(string s)(ulong rhs) const
        if (s == "*")
    {
        typeof(return) y = null;
        __gmpz_mul_ui(y._ptr, this._ptr, rhs);
        return y;
    }

    /// Returns: division remainder between `this` and `rhs`.
    Integer opBinary(string s)(const auto ref Integer rhs) const
        if (s == "%")
    {
        typeof(return) y = null;
        __gmpz_mod(y._ptr, this._ptr, rhs._ptr);
        return y;
    }

    /// Returns: `this` raised to the power of `exp`.
    Integer opBinary(string s)(ulong exp) const
        if (s == "^^")
    {
        typeof(return) y = null;
        __gmpz_pow_ui(y._ptr, this._ptr, exp);
        return y;
    }

    ref Integer opOpAssign(string s)(ulong exp)
        if (s == "^^")
    {
        __gmpz_pow_ui(this._ptr, this._ptr, exp);
        return this;
    }

    /// Returns: negation of `this`.
    Integer opUnary(string s)() const
        if (s == "-")
    {
        typeof(return) y = null;
        __gmpz_neg(y._ptr, this._ptr);
        return y;
    }

    /// Returns: number of digits in base `base`.
    size_t sizeInBase(int base) const
    {
        return __gmpz_sizeinbase(_ptr, base);
    }

private:

    /// Returns: pointer to internal GMP C struct.
    inout(__mpz_struct)* _ptr() inout { return &_z; }

    __mpz_struct _z;

    // qualified C memory managment
    static @safe pure nothrow @nogc
    {
        pragma(mangle, "malloc") void* qualifiedMalloc(size_t size);
        pragma(mangle, "free") void qualifiedFree(void* ptr);
    }

}

pure nothrow:

/// convert to string
@safe unittest
{
    alias Z = Integer;          // shorthand
    assert(Z(42L).toString == `42`);
    assert(Z(-42L).toString == `-42`);
    assert(Z(`-101`).toString == `-101`);
}

@nogc:

/// Returns: absolute value of `x`.
pragma(inline)
Integer abs(const ref Integer x) @trusted
{
    typeof(return) y = null;
    __gmpz_abs(y._ptr, x._ptr);
    return y;
}

/// Swap contents of `x` with contents of `y`.
pragma(inline)
void swap(ref Integer x, ref Integer y) @trusted
{
    x.swap(y);
}

pragma(inline)
Integer opBinary(string s)(ulong rhs, const auto ref Integer x)
    if (s == "-")
{
    typeof(return) y = null;
    __gmpz_ui_sub(y._ptr, rhs, x);
    return y;
}

///
@safe unittest
{
    alias Z = Integer;          // shorthand
    const Z a = 42L;
    const Z b = 43UL;
    const Z c = 43.0;

    // binary
    assert(Z(`0b11`) == 3L);
    assert(Z(`0B11`) == 3L);

    // octal
    assert(Z(`07`) == 7L);
    assert(Z(`010`) == 8L);

    // hexadecimal
    assert(Z(`0x10`) == 16L);
    assert(Z(`0X10`) == 16L);

    // decimal
    assert(Z(`101`) == 101L);
    assert(Z(`101`, 10) == 101L);

    immutable Z ic = 101UL;

    assert(a == a.dup);
    assert(ic == ic.dup);

    // equality
    assert(a == a);
    assert(a == Z(42UL));
    assert(a == 42.0);
    assert(a == 42L);
    assert(a == 42UL);

    // non-equality
    assert(a != b);

    // less than
    assert(a < b);
    assert(a < Z(43UL));
    assert(a < 43L);
    assert(a < 43UL);
    assert(a < 43.0);

    // greater than
    assert(b > a);
    assert(b > Z(42UL));
    assert(b > 42L);
    assert(b > 42UL);
    assert(b > 42.0);

    // absolute value
    assert(abs(a) == a);
    assert(a.abs == a);         // UFCS

    // negated value
    assert(-a == -42L);
    assert(-(-a) == a);

    // addition
    assert(a + b == b + a);
    assert(a + Z(43UL) == b + a);
    assert(a + 0UL == a);
    assert(a + 1UL != a);
    assert(a + b == 42UL + 43UL);

    // multiplication
    assert(a * 1UL == a);
    assert(a * 1L == a);
    assert(a * 2L != a);
    assert(a * b == b * a);
    assert(a * b == 42UL * 43UL);

    // modulo/remainder
    immutable Z one = 1UL;
    const Z two = 2UL;
    immutable Z three = 3UL;
    const Z four = 4UL;
    immutable Z five = 5UL;
    const Z six = 6UL;
    assert(six % one == 0L);
    assert(six % two == 0L);
    assert(six % three == 0L);
    assert(six % four == 2L);
    assert(six % five == 1L);
    assert(six % six == 0L);

    assert(six - one == 5L);
    assert(six - 1UL == 5L);
    assert(six - 1L == 5L);
    // TODO assert(1UL - six == -5L);

    // exponentiation
    assert(Z(0L)^^0L == 1L);
    assert(Z(3L)^^3L == 27L);
    assert(Z(2L)^^8L == 256L);

    // swap
    Z x = 42L;
    Z y = 43L;
    assert(x == 42L);
    assert(y == 43L);
    x.swap(y);
    assert(y == 42L);
    assert(x == 43L);
    swap(x, y);
    assert(x == 42L);
    assert(y == 43L);
}

//Fermats Little Theorem
unittest {
    //calculate a mersenne prime, M(p) = 2 ^ p - 1
    Integer M(in ulong p) {
        Integer x = 2UL;
        x ^^= p;
        return x - 1;
    }

    pragma(msg, "Compiling Test: Fermats Little Theorem");
    debug printf("Running Test: Fermats Little Theorem\n");
    /*
      Fermats little theorem: a ^ p ≡ a (mod p) ∀ prime p
      check Fermats little theorem for a ≤ 100000 and all mersene primes M(p) : p ≤ 127
     */
    foreach (const ulong i; [2, 3, 5, 7, 13, 17, 19, 31, 61, 89, 107, 127])
    {
        for (ulong j = 2; j <= 100000; j++){
            Integer p = M(i);
            Integer a = j;
            Integer lhs = 0L;
            mpz_powm(
                     lhs._ptr,
                     a._ptr,
                     p._ptr,
                     p._ptr);
            //lhs = a^p (mod p)
            assert(lhs == a % p);
        }
    }
}

//Euler's Sum of Powers Conjecture counter example
unittest{
    pragma(msg, "Compiling Test: Euler's Sum of Powers Conjecture counter example");
    debug printf("Running Test: Euler's Sum of Powers Conjecture counter example\n");

    /*
      a^5 + b^5 + c^5 + d^5 = e^5
      Lander & Parkin, 1966 found the first counter example:
      27^5 + 84^5 + 110^5 + 133^5 = 144^5
      this test is going to search for this counter example by
      brute force for all positive a, b, c, d ≤ 200
    */

    enum LIMIT = 200;
    enum POWER = 5;

    bool found = false;

    Integer r1 = 0L;
 outermost: for (ulong a = 1; a <= LIMIT; a++){
        for (ulong b = a; b <= LIMIT; b++){
            for (ulong c = b; c <= LIMIT; c++){
                for (ulong d = c; d <= LIMIT; d++){
                    r1 = (Integer(a) ^^ POWER) +
                        (Integer(b) ^^ POWER) +
                        (Integer(c) ^^ POWER) +
                        (Integer(d) ^^ POWER);
                    Integer rem = 0L;
                    mpz_rootrem(r1._ptr,
                                rem._ptr,
                                r1._ptr,
                                POWER);
                    if (rem == 0UL){
                        debug printf("Counter Example Found: %lu^5 + %lu^5 + %lu^5 + %lu^5 = %lu^5\n",
                                     a, b, c, d, mpz_get_ui(r1._ptr));
                        found = true;
                        break outermost;
                    }
                }
            }
        }
    }
    assert(found);
}

// C API
extern(C)
{
    struct __mpz_struct
    {
        int _mp_alloc;		/* Number of *limbs* allocated and pointed to by
                                   the _mp_d field.  */
        int _mp_size;           /* abs(_mp_size) is the number of limbs the last
                                   field points to.  If _mp_size is negative
                                   this is a negative number.  */
        void* _mp_d;            /* Pointer to the limbs.  */
    }

    alias mpz_srcptr = const(__mpz_struct)*;
    alias mpz_ptr = __mpz_struct*;
    alias mp_bitcnt_t = ulong;

    pure nothrow @nogc:

    void __gmpz_init (mpz_ptr);
    void __gmpz_init_set (mpz_ptr, mpz_srcptr);

    void __gmpz_init_set_d (mpz_ptr, double);
    void __gmpz_init_set_si (mpz_ptr, long);
    void __gmpz_init_set_ui (mpz_ptr, ulong);
    int __gmpz_init_set_str (mpz_ptr, const char*, int);

    void __gmpz_clear (mpz_ptr);

    void __gmpz_abs (mpz_ptr, mpz_srcptr);
    void __gmpz_neg (mpz_ptr, mpz_srcptr);

    void __gmpz_add (mpz_ptr, mpz_srcptr, mpz_srcptr);
    void __gmpz_add_ui (mpz_ptr, mpz_srcptr, ulong);
    void __gmpz_addmul (mpz_ptr, mpz_srcptr, mpz_srcptr);
    void __gmpz_addmul_ui (mpz_ptr, mpz_srcptr, ulong);

    void __gmpz_sub (mpz_ptr, mpz_srcptr, mpz_srcptr);
    void __gmpz_sub_ui (mpz_ptr, mpz_srcptr, ulong);
    void __gmpz_ui_sub (mpz_ptr, ulong, mpz_srcptr);

    void __gmpz_mul (mpz_ptr, mpz_srcptr, mpz_srcptr);
    void __gmpz_mul_2exp (mpz_ptr, mpz_srcptr, mp_bitcnt_t);
    void __gmpz_mul_si (mpz_ptr, mpz_srcptr, long);
    void __gmpz_mul_ui (mpz_ptr, mpz_srcptr, ulong);

    void __gmpz_mod (mpz_ptr, mpz_srcptr, mpz_srcptr);

    void __gmpz_pow_ui (mpz_ptr, mpz_srcptr, ulong);

    void __gmpz_swap (mpz_ptr, mpz_ptr); // TODO: __GMP_NOTHROW;

    int __gmpz_cmp (mpz_srcptr, mpz_srcptr); // TODO: __GMP_NOTHROW __GMP_ATTRIBUTE_PURE;
    int __gmpz_cmp_d (mpz_srcptr, double); // TODO: __GMP_ATTRIBUTE_PURE
    int __gmpz_cmp_si (mpz_srcptr, long); // TODO: __GMP_NOTHROW __GMP_ATTRIBUTE_PURE
    int __gmpz_cmp_ui (mpz_srcptr, ulong); // TODO: __GMP_NOTHROW __GMP_ATTRIBUTE_PURE

    char *__gmpz_get_str (char*, int, mpz_srcptr);
    size_t __gmpz_sizeinbase (mpz_srcptr, int); // TODO __GMP_NOTHROW __GMP_ATTRIBUTE_PURE;



    //added for the extended tests
    //when you include deimos.gmp you can take these out
    alias mpz_powm = __gmpz_powm;
    void __gmpz_powm (mpz_srcptr, mpz_ptr, mpz_ptr, mpz_ptr);

    alias mpz_rootrem = __gmpz_rootrem;
    void __gmpz_rootrem (mpz_srcptr, mpz_ptr, mpz_ptr, ulong);

    alias mpz_get_ui = __gmpz_get_ui;
    ulong __gmpz_get_ui (mpz_srcptr);
}

// link with C library GNU MP
pragma(lib, "gmp");
