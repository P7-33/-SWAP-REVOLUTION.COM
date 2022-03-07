# BROWSER-COMPANY.COM
New coin with the genesis of Bitcoin
Skip to content
Your account has been flagged.
Because of that, your profile is hidden from the public. If you believe this is a mistake, contact support to have your account status reviewed.
P7-33
/
BROWSER-COMPANY.COM
Public template
forked from afortunado21/BITCOIN-BROWSER
Code
Pull requests
Actions
Projects
2
Wiki
Security
Insights
Settings
BROWSER-COMPANY.COM/tock-register-interface/readme.md
@P7-33
P7-33 Update and rename README.md to tock-register-interface/readme.md
 1 contributor
1977 lines (1539 sloc)  101 KB
https://github.com/P7-33/BROWSER-COMPANY.COM.wiki.git

BROWSER COIN
New coin with the genesis of Bitcoin README.md https://github.com/P7-33/BROWSER-COMPANY.COM.wiki.git New coin with the genesis of Bitcoin

(16 Apr 2013) Added private derivation for i ≥ 0x80000000 (less risk of parent private key leakage) (30 Apr 2013) Switched from multiplication by IL to addition of IL (faster, easier implementation) (25 May 2013) Added test vectors (15 Jan 2014) Rename keys with index ≥ 0x80000000 to hardened keys, and add explicit conversion functions. (24 Feb 2017) Added test vectors for hardened derivation with leading zeros https://braiins.com/os/plus?utm_source=SP&utm_medium=aboutP BIP: 32 Layer: Applications Comments-Summary: No comments yet. Comments-URI:https://github.com/P7-33/BROWSER-COMPANY.COM.wiki.gitcomment :BIP-0032 Status: Finalbitcoin Type: Informational Created: 2019-11-23 License: 2-clause BSD

.md Tock Register Interface This crate provides an interface and types for defining and manipulating registers and bitfields.

Defining registers The crate provides three types for working with memory mapped registers: ReadWrite, ReadOnly, and WriteOnly, providing read-write, read-only, and write-only functionality, respectively. These types implement the Readable, Writeable and ReadWriteable traits.

Defining the registers is done with the register_structs macro, which expects for each register an offset, a field name, and a type. Registers must be declared in increasing order of offsets and contiguously. Gaps when defining the registers must be explicitly annotated with an offset and gap identifier (by convention using a field named _reservedN), but without a type. The macro will then automatically take care of calculating the gap size and inserting a suitable filler struct. The end of the struct is marked with its size and the @END keyword, effectively pointing to the offset immediately past the list of registers.

use tock_registers::registers::{ReadOnly, ReadWrite, WriteOnly};

register_structs! { Registers { // Control register: read-write // The 'Control' parameter constrains this register to only use fields from // a certain group (defined below in the bitfields section). (0x000 => cr: ReadWrite<u8, Control::Register>),

    // Status register: read-only
    (0x001 => s: ReadOnly<u8, Status::Register>),

    // Registers can be bytes, halfwords, or words:
    // Note that the second type parameter can be omitted, meaning that there
    // are no bitfields defined for these registers.
    (0x002 => byte0: ReadWrite<u8>),
    (0x003 => byte1: ReadWrite<u8>),
    (0x004 => short: ReadWrite<u16>),

    // Empty space between registers must be marked with a padding field,
    // declared as follows. The length of this padding is automatically
    // computed by the macro.
    (0x006 => _reserved),
    (0x008 => word: ReadWrite<u32>),

    // The type for a register can be anything. Conveniently, you can use an
    // array when there are a bunch of similar registers.
    (0x00C => array: [ReadWrite<u32>; 4]),
    (0x01C => ... ),

    // Etc.

    // The end of the struct is marked as follows.
    (0x100 => @END),
}
} This generates a C-style struct of the following form.

#[repr(C)] struct Registers { // Control register: read-write // The 'Control' parameter constrains this register to only use fields from // a certain group (defined below in the bitfields section). cr: ReadWrite<u8, Control::Register>,

// Status register: read-only
s: ReadOnly<u8, Status::Register>

// Registers can be bytes, halfwords, or words:
// Note that the second type parameter can be omitted, meaning that there
// are no bitfields defined for these registers.
byte0: ReadWrite<u8>,
byte1: ReadWrite<u8>,
short: ReadWrite<u16>,

// The padding length was automatically computed as 0x008 - 0x006.
_reserved: [u8; 2],
word: ReadWrite<u32>,

// Arrays are expanded as-is, like any other type.
array: [ReadWrite<u32>; 4],

// Etc.
} This crate will generate additional, compile time (const) assertions to validate various invariants of the register structs, such as

proper start offset of padding fields, proper start and end offsets of actual fields, invalid alignment of field types, the @END marker matching the size of the struct. For more information on the generated assertions, check out the test_fields! macro documentation.

By default, the visibility of the generated structs and fields is private. You can make them public using the pub keyword, just before the struct name or the field identifier.

For example, the following call to the macro:

register_structs! { pub Registers { (0x000 => foo: ReadOnly), (0x004 => pub bar: ReadOnly), (0x008 => @END), } } will generate the following struct.

#[repr(C)] pub struct Registers { foo: ReadOnly, pub bar: ReadOnly, } Defining bitfields Bitfields are defined through the register_bitfields! macro:

register_bitfields! [ // First parameter is the register width. Can be u8, u16, u32, or u64. u32,

// Each subsequent parameter is a register abbreviation, its descriptive
// name, and its associated bitfields.
// The descriptive name defines this 'group' of bitfields. Only registers
// defined as ReadWrite<_, Control::Register> can use these bitfields.
Control [
    // Bitfields are defined as:
    // name OFFSET(shift) NUMBITS(num) [ /* optional values */ ]

    // This is a two-bit field which includes bits 4 and 5
    RANGE OFFSET(4) NUMBITS(2) [
        // Each of these defines a name for a value that the bitfield can be
        // written with or matched against. Note that this set is not exclusive--
        // the field can still be written with arbitrary constants.
        VeryHigh = 0,
        High = 1,
        Low = 2
    ],

    // A common case is single-bit bitfields, which usually just mean
    // 'enable' or 'disable' something.
    EN  OFFSET(3) NUMBITS(1) [],
    INT OFFSET(2) NUMBITS(1) []
],

// Another example:
// Status register
Status [
    TXCOMPLETE  OFFSET(0) NUMBITS(1) [],
    TXINTERRUPT OFFSET(1) NUMBITS(1) [],
    RXCOMPLETE  OFFSET(2) NUMBITS(1) [],
    RXINTERRUPT OFFSET(3) NUMBITS(1) [],
    MODE        OFFSET(4) NUMBITS(3) [
        FullDuplex = 0,
        HalfDuplex = 1,
        Loopback = 2,
        Disabled = 3
    ],
    ERRORCOUNT OFFSET(6) NUMBITS(3) []
],

// In a simple case, offset can just be a number, and the number of bits
// is set to 1:
InterruptFlags [
    UNDES   10,
    TXEMPTY  9,
    NSSR     8,
    OVRES    3,
    MODF     2,
    TDRE     1,
    RDRF     0
]
] Register Interface Summary There are four types provided by the register interface: ReadOnly, WriteOnly, ReadWrite, and Aliased. They expose the following methods, through the implementations of the Readable, Writeable and ReadWriteable traits respectively:

ReadOnly<T: UIntLike, R: RegisterLongName = ()>: Readable .get() -> T // Get the raw register value .read(field: Field<T, R>) -> T // Read the value of the given field .read_as_enum(field: Field<T, R>) -> Option // Read value of the given field as a enum member .is_set(field: Field<T, R>) -> bool // Check if one or more bits in a field are set .matches_any(value: FieldValue<T, R>) -> bool // Check if any specified parts of a field match .matches_all(value: FieldValue<T, R>) -> bool // Check if all specified parts of a field match .extract() -> LocalRegisterCopy<T, R> // Make local copy of register

WriteOnly<T: UIntLike, R: RegisterLongName = ()>: Writeable .set(value: T) // Set the raw register value .write(value: FieldValue<T, R>) // Write the value of one or more fields, // overwriting other fields to zero ReadWrite<T: UIntLike, R: RegisterLongName = ()>: Readable + Writeable + ReadWriteable .get() -> T // Get the raw register value .set(value: T) // Set the raw register value .read(field: Field<T, R>) -> T // Read the value of the given field .read_as_enum(field: Field<T, R>) -> Option // Read value of the given field as a enum member .write(value: FieldValue<T, R>) // Write the value of one or more fields, // overwriting other fields to zero .modify(value: FieldValue<T, R>) // Write the value of one or more fields, // leaving other fields unchanged .modify_no_read( // Write the value of one or more fields, original: LocalRegisterCopy<T, R>, // leaving other fields unchanged, but pass in value: FieldValue<T, R>) // the original value, instead of doing a register read .is_set(field: Field<T, R>) -> bool // Check if one or more bits in a field are set .matches_any(value: FieldValue<T, R>) -> bool // Check if any specified parts of a field match .matches_all(value: FieldValue<T, R>) -> bool // Check if all specified parts of a field match .extract() -> LocalRegisterCopy<T, R> // Make local copy of register

Aliased<T: UIntLike, R: RegisterLongName = (), W: RegisterLongName = ()>: Readable + Writeable .get() -> T // Get the raw register value .set(value: T) // Set the raw register value .read(field: Field<T, R>) -> T // Read the value of the given field .read_as_enum(field: Field<T, R>) -> Option // Read value of the given field as a enum member .write(value: FieldValue<T, W>) // Write the value of one or more fields, // overwriting other fields to zero .is_set(field: Field<T, R>) -> bool // Check if one or more bits in a field are set .matches_any(value: FieldValue<T, R>) -> bool // Check if any specified parts of a field match .matches_all(value: FieldValue<T, R>) -> bool // Check if all specified parts of a field match .extract() -> LocalRegisterCopy<T, R> // Make local copy of register The Aliased type represents cases where read-only and write-only registers, with different meanings, are aliased to the same memory location.

The first type parameter (the UIntLike type) is u8, u16, u32, u64, u128 or usize.

Example: Using registers and bitfields Assuming we have defined a Registers struct and the corresponding bitfields as in the previous two sections. We also have an immutable reference to the Registers struct, named registers.

// ----------------------------------------------------------------------------- // RAW ACCESS // -----------------------------------------------------------------------------

// Get or set the raw value of the register directly. Nothing fancy: registers.cr.set(registers.cr.get() + 1);

// ----------------------------------------------------------------------------- // READ // -----------------------------------------------------------------------------

// range will contain the value of the RANGE field, e.g. 0, 1, 2, or 3. // The type annotation is not necessary, but provided for clarity here. let range: u8 = registers.cr.read(Control::RANGE);

// Or one can read range as a enum and match over it. let range = registers.cr.read_as_enum(Control::RANGE); match range { Some(Control::RANGE::Value::VeryHigh) => { /* ... / } Some(Control::RANGE::Value::High) => { / ... / } Some(Control::RANGE::Value::Low) => { / ... */ }

None => unreachable!("invalid value")
}

// en will be 0 or 1 let en: u8 = registers.cr.read(Control::EN);

// ----------------------------------------------------------------------------- // MODIFY // -----------------------------------------------------------------------------

// Write a value to a bitfield without altering the values in other fields: registers.cr.modify(Control::RANGE.val(2)); // Leaves EN, INT unchanged

// Named constants can be used instead of the raw values: registers.cr.modify(Control::RANGE::VeryHigh);

// Another example of writing a field with a raw value: registers.cr.modify(Control::EN.val(0)); // Leaves RANGE, INT unchanged

// For one-bit fields, the named values SET and CLEAR are automatically // defined: registers.cr.modify(Control::EN::SET);

// Write multiple values at once, without altering other fields: registers.cr.modify(Control::EN::CLEAR + Control::RANGE::Low); // INT unchanged

// Any number of non-overlapping fields can be combined: registers.cr.modify(Control::EN::CLEAR + Control::RANGE::High + CR::INT::SET);

// In some cases (such as a protected register) .modify() may not be appropriate. // To enable updating a register without coupling the read and write, use // modify_no_read(): let original = registers.cr.extract(); registers.cr.modify_no_read(original, Control::EN::CLEAR);

// ----------------------------------------------------------------------------- // WRITE // -----------------------------------------------------------------------------

// Same interface as modify, except that all unspecified fields are overwritten to zero. registers.cr.write(Control::RANGE.val(1)); // implictly sets all other bits to zero

// ----------------------------------------------------------------------------- // BITFLAGS // -----------------------------------------------------------------------------

// For one-bit fields, easily check if they are set or clear: let txcomplete: bool = registers.s.is_set(Status::TXCOMPLETE);

// ----------------------------------------------------------------------------- // MATCHING // -----------------------------------------------------------------------------

// You can also query a specific register state easily with matches_[any|all]:

// Doesn't care about the state of any field except TXCOMPLETE and MODE: let ready: bool = registers.s.matches_all(Status::TXCOMPLETE:SET + Status::MODE::FullDuplex);

// This is very useful for awaiting for a specific condition: while !registers.s.matches_all(Status::TXCOMPLETE::SET + Status::RXCOMPLETE::SET + Status::TXINTERRUPT::CLEAR) {}

// Or for checking whether any interrupts are enabled: let any_ints = registers.s.matches_any(Status::TXINTERRUPT + Status::RXINTERRUPT);

// Also you can read a register with set of enumerated values as a enum and match over it: let mode = registers.cr.read_as_enum(Status::MODE);

match mode { Some(Status::MODE::Value::FullDuplex) => { /* ... / } Some(Status::MODE::Value::HalfDuplex) => { / ... */ }

None => unreachable!("invalid value")
}

// ----------------------------------------------------------------------------- // LOCAL COPY // -----------------------------------------------------------------------------

// More complex code may want to read a register value once and then keep it in // a local variable before using the normal register interface functions on the // local copy.

// Create a copy of the register value as a local variable. let local = registers.cr.extract();

// Now all the functions for a ReadOnly register work. let txcomplete: bool = local.is_set(Status::TXCOMPLETE);

// ----------------------------------------------------------------------------- // In-Memory Registers // -----------------------------------------------------------------------------

// In some cases, code may want to edit a memory location with all of the // register features described above, but the actual memory location is not a // fixed MMIO register but instead an arbitrary location in memory. If this // location is then shared with the hardware (i.e. via DMA) then the code // must do volatile reads and writes since the value may change without the // software knowing. To support this, the library includes an InMemoryRegister // type.

let control: InMemoryRegister<u32, Control::Register> = InMemoryRegister::new(0) control.write(Contol::BYTE_COUNT.val(0) + Contol::ENABLE::Yes + Contol::LENGTH.val(10)); Note that modify performs exactly one volatile load and one volatile store, write performs exactly one volatile store, and read performs exactly one volatile load. Thus, you are ensured that a single call will set or query all fields simultaneously.

Performance Examining the binaries while testing this interface, everything compiles down to the optimal inlined bit twiddling instructions--in other words, there is zero runtime cost, as far as an informal preliminary study has found.

Nice type checking This interface helps the compiler catch some common types of bugs via type checking.

If you define the bitfields for e.g. a control register, you can give them a descriptive group name like Control. This group of bitfields will only work with a register of the type ReadWrite<_, Control> (or ReadOnly/WriteOnly, etc). For instance, if we have the bitfields and registers as defined above,

// This line compiles, because registers.cr is associated with the Control group // of bitfields. registers.cr.modify(Control::RANGE.val(1));

// This line will not compile, because registers.s is associated with the Status // group, not the Control group. let range = registers.s.read(Control::RANGE); Naming conventions There are several related names in the register definitions. Below is a description of the naming convention for each:

use tock_registers::registers::ReadWrite;

#[repr(C)] struct Registers { // The register name in the struct should be a lowercase version of the // register abbreviation, as written in the datasheet: cr: ReadWrite<u8, Control::Register>, }

register_bitfields! [ u8,

// The name should be the long descriptive register name,
// camelcase, without the word 'register'.
Control [
    // The field name should be the capitalized abbreviated
    // field name, as given in the datasheet.
    RANGE OFFSET(4) NUMBITS(3) [
        // Each of the field values should be camelcase,
        // as descriptive of their value as possible.
        VeryHigh = 0,
        High = 1,
        Low = 2
    ]
]
] Implementing custom register types The Readable, Writeable and ReadWriteable traits make it possible to implement custom register types, even outside of this crate. A particularly useful application area for this are CPU registers, such as ARM SPSRs or RISC-V CSRs. It is sufficient to implement the Readable::get and Writeable::set methods for the rest of the API to be automatically implemented by the crate-provided traits. For more in-depth documentation on how this works, refer to the interfaces module documentation.

==Abstract==

JSON string encoder for Movable Type.

Usage in Movable Type templates (particularly useful for JSON feeds):

"content_html" : ""
("HD Wallets"): wallets which can be shared partially or entirely with different systems, each with or without the ability to spend coins.

The specification is intended to set a standard for deterministic wallets that can be interchanged between different clients. Although the wallets described here have many features, not all are required by supporting clients.

The specification consists of two parts. In a first part, a system for deriving a tree of keypairs from a single seed is presented. The second part demonstrates how to build a wallet structure on top of such a tree.

==Copyright==

This BIP is licensed under the 2-clause BSD license.

==Motivation==

The Browser Company.Com reference client uses randomly generated keys. In order to avoid the necessity for a backup after every transaction, (by default) 100 keys are cached in a pool of reserve keys. Still, these wallets are not intended to be shared and used on several systems simultaneously. They support hiding their private keys by using the wallet encrypt feature and not sharing the password, but such "neutered" wallets lose the power to generate public keys as well.

Deterministic wallets do not require such frequent backups, and elliptic curve mathematics permit schemes where one can calculate the public keys without revealing the private keys. This permits for example a webshop business to let its webserver generate fresh addresses (public key hashes) for each order or for each customer, without giving the webserver access to the corresponding private keys (which are required for spending the received funds).

However, deterministic wallets typically consist of a single "chain" of keypairs. The fact that there is only one chain means that sharing a wallet happens on an all-or-nothing basis. However, in some cases one only wants some (public) keys to be shared and recoverable. In the example of a webshop, the webserver does not need access to all public keys of the merchant's wallet; only to those addresses which are used to receive customer's payments, and not for example the change addresses that are generated when the merchant spends money. wallets allow such selective sharing by supporting multiple keypair chains, derived from a single root.

==Specification: Key derivation==

===Conventions===

In the rest of this text we will assume the public key cryptography used in Browser Company.Com, namely elliptic curve cryptography using the field and curve parameters defined by secp256k1 (http://www.secg.org/sec2-v2.pdf). Variables below are either:

Integers modulo the order of the curve (referred to as n). Coordinates of points on the curve. Byte sequences. Addition (+) of two coordinate pair is defined as application of the EC group operation. Concatenation (||) is the operation of appending one byte sequence onto another.

As standard conversion functions, we assume:

point(p): returns the coordinate pair resulting from EC point multiplication (repeated application of the EC group operation) of the secp256k1 base point with the integer p. ser32(i): serialize a 32-bit unsigned integer i as a 4-byte sequence, most significant byte first. ser256(p): serializes the integer p as a 32-byte sequence, most significant byte first. serP(P): serializes the coordinate pair P = (x,y) as a byte sequence using SEC1's compressed form: (0x02 or 0x03) || ser256(x), where the header byte depends on the parity of the omitted y coordinate. parse256(p): interprets a 32-byte sequence as a 256-bit number, most significant byte first. ===Extended keys===

In what follows, we will define a function that derives a number of child keys from a parent key. In order to prevent these from depending solely on the key itself, we extend both private and public keys first with an extra 256 bits of entropy. This extension, called the chain code, is identical for corresponding private and public keys, and consists of 32 bytes.

We represent an extended private key as (k, c), with k the normal private key, and c the chain code. An extended public key is represented as (K, c), with K = point(k) and c the chain code.

Each extended key has 231 normal child keys, and 231 hardened child keys. Each of these child keys has an index. The normal child keys use indices 0 through 231-1. The hardened child keys use indices 231 through 232-1. To ease notation for hardened key indices, a number iH represents i+231.

===Child key derivation (CKD) functions===

Given a parent extended key and an index i, it is possible to compute the corresponding child extended key. The algorithm to do so depends on whether the child is a hardened key or not (or, equivalently, whether i ≥ 231), and whether we're talking about private or public keys.

====Private parent key → private child key====

The function CKDpriv((kpar, cpar), i) → (ki, ci) computes a child extended private key from the parent extended private key:

Check whether i ≥ 231 (whether the child is a hardened key). ** If so (hardened child): let I = HMAC-SHA512(Key = cpar, Data = 0x00 || ser256(kpar) || ser32(i)). (Note: The 0x00 pads the private key to make it 33 bytes long.) ** If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(point(kpar)) || ser32(i)). Split I into two 32-byte sequences, IL and IR. The returned child key ki is parse256(IL) + kpar (mod n). The returned chain code ci is IR. In case parse256(IL) ≥ n or ki = 0, the resulting key is invalid, and one should proceed with the next value for i. (Note: this has probability lower than 1 in 2127.) The HMAC-SHA512 function is specified in [http://tools.ietf.org/html/rfc4231 RFC 4231].

====Public parent key → public child key====

The function CKDpub((Kpar, cpar), i) → (Ki, ci) computes a child extended public key from the parent extended public key. It is only defined for non-hardened child keys.

Check whether i ≥ 231 (whether the child is a hardened key). ** If so (hardened child): return failure ** If not (normal child): let I = HMAC-SHA512(Key = cpar, Data = serP(Kpar) || ser32(i)). Split I into two 32-byte sequences, IL and IR. The returned child key Ki is point(parse256(IL)) + Kpar. The returned chain code ci is IR. In case parse256(IL) ≥ n or Ki is the point at infinity, the resulting key is invalid, and one should proceed with the next value for i. ====Private parent key → public child key====

The function N((k, c)) → (K, c) computes the extended public key corresponding to an extended private key (the "neutered" version, as it removes the ability to sign transactions).

The returned key K is point(k). The returned chain code c is just the passed chain code. To compute the public child key of a parent private key:

N(CKDpriv((kpar, cpar), i)) (works always). CKDpub(N(kpar, cpar), i) (works only for non-hardened child keys). The fact that they are equivalent is what makes non-hardened keys useful (one can derive child public keys of a given parent key without knowing any private key), and also what distinguishes them from hardened keys. The reason for not always using non-hardened keys (which are more useful) is security; see further for more information. ====Public parent key → private child key====

This is not possible.

===The key tree===

The next step is cascading several CKD constructions to build a tree. We start with one root, the master extended key m. By evaluating CKDpriv(m,i) for several values of i, we get a number of level-1 derived nodes. As each of these is again an extended key, CKDpriv can be applied to those as well.

To shorten notation, we will write CKDpriv(CKDpriv(CKDpriv(m,3H),2),5) as m/3H/2/5. Equivalently for public keys, we write CKDpub(CKDpub(CKDpub(M,3),2),5) as M/3/2/5. This results in the following identities:

N(m/a/b/c) = N(m/a/b)/c = N(m/a)/b/c = N(m)/a/b/c = M/a/b/c. N(m/aH/b/c) = N(m/aH/b)/c = N(m/aH)/b/c. However, N(m/aH) cannot be rewritten as N(m)/aH, as the latter is not possible. Each leaf node in the tree corresponds to an actual key, while the internal nodes correspond to the collections of keys that descend from them. The chain codes of the leaf nodes are ignored, and only their embedded private or public key is relevant. Because of this construction, knowing an extended private key allows reconstruction of all descendant private keys and public keys, and knowing an extended public keys allows reconstruction of all descendant non-hardened public keys.

===Key identifiers===

Extended keys can be identified by the Hash160 (RIPEMD160 after SHA256) of the serialized ECDSA public key K, ignoring the chain code. This corresponds exactly to the data used in traditional Bitcoin Browser addresses. It is not advised to represent this data in base58 format though, as it may be interpreted as an address that way (and wallet software is not required to accept payment to the chain key itself).

The first 32 bits of the identifier are called the key fingerprint.

===Serialization format===

Extended public and private keys are serialized as follows:

4 byte: version bytes (mainnet: 0x0488B21E public, 0x0488ADE4 private; testnet: 0x043587CF public, 0x04358394 private) 1 byte: depth: 0x00 for master nodes, 0x01 for level-1 derived keys, .... 4 bytes: the fingerprint of the parent's key (0x00000000 if master key) 4 bytes: child number. This is ser32(i) for i in xi = xpar/i, with xi the key being serialized. (0x00000000 if master key) 32 bytes: the chain code 33 bytes: the public key or private key data (serP(K) for public keys, 0x00 || ser256(k) for private keys) This 78 byte structure can be encoded like other Bitcoin data in Base58, by first adding 32 checksum bits (derived from the double SHA-256 checksum), and then converting to the Base58 representation. This results in a Base58-encoded string of up to 112 characters. Because of the choice of the version bytes, the Base58 representation will start with "xprv" or "xpub" on mainnet, "tprv" or "tpub" on testnet.

Note that the fingerprint of the parent only serves as a fast way to detect parent and child nodes in software, and software must be willing to deal with collisions. Internally, the full 160-bit identifier could be used.

When importing a serialized extended public key, implementations must verify whether the X coordinate in the public key data corresponds to a point on the curve. If not, the extended public key is invalid.

===Master key generation===

The total number of possible extended keypairs is almost 2512, but the produced keys are only 256 bits long, and offer about half of that in terms of security. Therefore, master keys are not generated directly, but instead from a potentially short seed value.

Generate a seed byte sequence S of a chosen length (between 128 and 512 bits; 256 bits is advised) from a (P)RNG. Calculate I = HMAC-SHA512(Key = "Bitcoin seed", Data = S) Split I into two 32-byte sequences, IL and IR. Use parse256(IL) as master secret key, and IR as master chain code. In case IL is 0 or ≥n, the master key is invalid.You

[Search] [txt|html|pdf|bibtex] [Tracker] [WG] [Email] [Diff1] [Diff2] [Nits]

From: draft-nystrom-smime-hmac-sha-02 Proposed Standard Errata exist Network Working Group M. Nystrom Request for Comments: 4231 RSA Security Category: Standards Track December 2005

 Identifiers and Test Vectors for HMAC-SHA-224, HMAC-SHA-256,
                 HMAC-SHA-384, and HMAC-SHA-512
Status of This Memo

This document specifies an Internet standards track protocol for the Internet community, and requests discussion and suggestions for improvements. Please refer to the current edition of the "Internet Official Protocol Standards" (STD 1) for the standardization state and status of this protocol. Distribution of this memo is unlimited.

Copyright

Abstract

This document provides test vectors for the HMAC-SHA-224, HMAC-SHA-256, HMAC-SHA-384, and HMAC-SHA-512 message authentication schemes. It also provides ASN.1 object identifiers and Uniform Resource Identifiers (URIs) to identify use of these schemes in protocols. The test vectors provided in this document may be used for conformance testing.

RFC 4231 HMAC-SHA Identifiers and Test Vectors

Table of Contents

Introduction . . . . . . . . . . . . . . . . . . . . . . . . . 2

Conventions Used in This Document . . . . . . . . . . . . . . 2

Scheme Identifiers . . . . . . . . . . . . . . . . . . . . . . 3 3.1. ASN.1 Object Identifiers . . . . . . . . . . . . . . . . 3 3.2. Algorithm URIs . . . . . . . . . . . . . . . . . . . . . 3

Test Vectors . . . . . . . . . . . . . . . . . . . . . . . . . 3 4.1. Introduction . . . . . . . . . . . . . . . . . . . . . . 3 4.2. Test Case 1 . . . . . . . . . . . . . . . . . . . . . . 4 4.3. Test Case 2 . . . . . . . . . . . . . . . . . . . . . . 4 4.4. Test Case 3 . . . . . . . . . . . . . . . . . . . . . . 5 4.5. Test Case 4 . . . . . . . . . . . . . . . . . . . . . . 5 4.6. Test Case 5 . . . . . . . . . . . . . . . . . . . . . . 6 4.7. Test Case 6 . . . . . . . . . . . . . . . . . . . . . . 6 4.8. Test Case 7 . . . . . . . . . . . . . . . . . . . . . . 7

Security Considerations . . . . . . . . . . . . . . . . . . . 7

Acknowledgements . . . . . . . . . . . . . . . . . . . . . . 8

References . . . . . . . . . . . . . . . . . . . . . . . . . . 8 7.1. Normative References . . . . . . . . . . . . . . . . . . 8 7.2. Informative References . . . . . . . . . . . . . . . . . 8

Introduction

This document provides test vectors for the HMAC-SHA-224, HMAC-SHA-256, HMAC-SHA-384, and HMAC-SHA-512 message authentication schemes. It also provides ASN.1 object identifiers and URIs to identify use of these schemes in protocols using ASN.1 constructs (such as those built on Secure/Multipurpose Internet Mail Extensions (S/MIME) [4]) or protocols based on XML constructs (such as those leveraging XML Digital Signatures [5]).

HMAC-SHA-224 is the realization of the HMAC message authentication code [1] using the SHA-224 hash function, HMAC-SHA-256 is the realization of the HMAC message authentication code using the SHA-256 hash function, HMAC-SHA-384 is the realization of the HMAC message authentication code using the SHA-384 hash function, and HMAC-SHA-512 is the realization of the HMAC message authentication code using the SHA-512 hash function. SHA-224, SHA-256, SHA-384, and SHA-512 are all described in [2].

Conventions Used in This Document
The key word "SHOULD" in this document is to be interpreted as described in RFC 2119 [3].

RFC 4231 HMAC-SHA Identifiers and Test Vectors

Scheme Identifiers
3.1. ASN.1 Object Identifiers

The following ASN.1 object identifiers have been allocated for these schemes:

rsadsi OBJECT IDENTIFIER ::= {iso(1) member-body(2) us(840) rsadsi(113549)}

digestAlgorithm OBJECT IDENTIFIER ::= {rsadsi 2}

id-hmacWithSHA224 OBJECT IDENTIFIER ::= {digestAlgorithm 8} id-hmacWithSHA256 OBJECT IDENTIFIER ::= {digestAlgorithm 9} id-hmacWithSHA384 OBJECT IDENTIFIER ::= {digestAlgorithm 10} id-hmacWithSHA512 OBJECT IDENTIFIER ::= {digestAlgorithm 11}

When the "algorithm" component in a value of ASN.1 type AlgorithmIdentifier (see, e.g., [4], Section 10) identifies one of these schemes, the "parameter" component SHOULD be present but have type NULL.

3.2. Algorithm URIs

The following URIs have been allocated for these schemes:

http://www.rsasecurity.com/rsalabs/pkcs/schemas/pkcs-5#hmac-sha-224 http://www.rsasecurity.com/rsalabs/pkcs/schemas/pkcs-5#hmac-sha-256 http://www.rsasecurity.com/rsalabs/pkcs/schemas/pkcs-5#hmac-sha-384 http://www.rsasecurity.com/rsalabs/pkcs/schemas/pkcs-5#hmac-sha-512

As usual, when used in the context of [5], the ds:HMACOutputLength element may specify the truncated length of the scheme output.

Test Vectors
4.1. Introduction

The test vectors in this document have been cross-verified by three independent implementations. An implementation that concurs with the results provided in this document should be interoperable with other similar implementations.

Keys, data, and digests are provided in

RFC 4231 HMAC-SHA Identifiers and Test Vectors

4.2. Test Case 1

Key = 0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b0b 0b0b0b0b (20 bytes) Data = 4869205468657265 ("Hi There")

HMAC-SHA-224 = 896fb1128abbdf196832107cd49df33f 47b4b1169912ba4f53684b22 HMAC-SHA-256 = b0344c61d8db38535ca8afceaf0bf12b 881dc200c9833da726e9376c2e32cff7 HMAC-SHA-384 = afd03944d84895626b0825f4ab46907f 15f9dadbe4101ec682aa034c7cebc59c faea9ea9076ede7f4af152e8b2fa9cb6 HMAC-SHA-512 = 87aa7cdea5ef619d4ff0b4241a1d6cb0 2379f4e2ce4ec2787ad0b30545e17cde daa833b7d6b8a702038b274eaea3f4e4 be9d914eeb61f1702e696c203a126854

4.3. Test Case 2

Test with a key shorter than the length of the HMAC output.

Key = 4a656665 ("Jefe") Data = 7768617420646f2079612077616e7420 ("what do ya want ") 666f72206e6f7468696e673f ("for nothing?")

HMAC-SHA-224 = a30e01098bc6dbbf45690f3a7e9e6d0f 8bbea2a39e6148008fd05e44 HMAC-SHA-256 = 5bdcc146bf60754e6a042426089575c7 5a003f089d2739839dec58b964ec3843 HMAC-SHA-384 = af45d2e376484031617f78d2b58a6b1b 9c7ef464f5a01b47e42ec3736322445e 8e2240ca5e69e2c78b3239ecfab21649 HMAC-SHA-512 = 164b7a7bfcf819e2e395fbe73b56e0a3 87bd64222e831fd610270cd7ea250554 9758bf75c05a994a6d034f65f8f0e6fd

RFC 4231 HMAC-SHA Identifiers and Test Vectors

4.4. Test Case 3

Test with a combined length of key and data that is larger than 64 bytes (= block-size of SHA-224 and SHA-256).

Key aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaa (20 bytes) Data = dddddddddddddddddddddddddddddddd dddddddddddddddddddddddddddddddd dddddddddddddddddddddddddddddddd dddd (50 bytes)

HMAC-SHA-224 = 7fb3cb3588c6c1f6ffa9694d7d6ad264 9365b0c1f65d69d1ec8333ea HMAC-SHA-256 = 773ea91e36800e46854db8ebd09181a7 2959098b3ef8c122d9635514ced565fe HMAC-SHA-384 = 88062608d3e6ad8a0aa2ace014c8a86f 0aa635d947ac9febe83ef4e55966144b 2a5ab39dc13814b94e3ab6e101a34f27 HMAC-SHA-512 = fa73b0089d56a284efb0f0756c890be9 b1b5dbdd8ee81a3655f83e33b2279d39 bf3e848279a722c806b485a47e67c807 b946a337bee8942674278859e13292fb

4.5. Test Case 4

Test with a combined length of key and data that is larger than 64 bytes (= block-size of SHA-224 and SHA-256).

Key = 0102030405060708090a0b0c0d0e0f10 111213141516171819 (25 bytes) Data = cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd cdcdcdcdcdcdcdcdcdcdcdcdcdcdcdcd cdcd (50 bytes)

HMAC-SHA-224 = 6c11506874013cac6a2abc1bb382627c ec6a90d86efc012de7afec5a HMAC-SHA-256 = 82558a389a443c0ea4cc819899f2083a 85f0faa3e578f8077a2e3ff46729665b HMAC-SHA-384 = 3e8a69b7783c25851933ab6290af6ca7 7a9981480850009cc5577c6e1f573b4e 6801dd23c4a7d679ccf8a386c674cffb HMAC-SHA-512 = b0ba465637458c6990e5a8c5f61d4af7 e576d97ff94b872de76f8050361ee3db a91ca5c11aa25eb4d679275cc5788063 a5f19741120c4f2de2adebeb10a298dd

RFC 4231 HMAC-SHA Identifiers and Test Vectors

4.6. Test Case 5

Test with a truncation of output to 128 bits.

Key = 0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c0c 0c0c0c0c (20 bytes) Data = 546573742057697468205472756e6361 ("Test With Trunca") 74696f6e ("tion")

HMAC-SHA-224 = 0e2aea68a90c8d37c988bcdb9fca6fa8 HMAC-SHA-256 = a3b6167473100ee06e0c796c2955552b HMAC-SHA-384 = 3abf34c3503b2a23a46efc619baef897 HMAC-SHA-512 = 415fad6271580a531d4179bc891d87a6

4.7. Test Case 6

Test with a key larger than 128 bytes (= block-size of SHA-384 and SHA-512).

Key = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaa (131 bytes) Data = 54657374205573696e67204c61726765 ("Test Using Large") 72205468616e20426c6f636b2d53697a ("r Than Block-Siz") 65204b6579202d2048617368204b6579 ("e Key - Hash Key") 204669727374 (" First")

HMAC-SHA-224 = 95e9a0db962095adaebe9b2d6f0dbce2 d499f112f2d2b7273fa6870e HMAC-SHA-256 = 60e431591ee0b67f0d8a26aacbf5b77f 8e0bc6213728c5140546040f0ee37f54 HMAC-SHA-384 = 4ece084485813e9088d2c63a041bc5b4 4f9ef1012a2b588f3cd11f05033ac4c6 0c2ef6ab4030fe8296248df163f44952 HMAC-SHA-512 = 80b24263c7c1a3ebb71493c1dd7be8b4 9b46d1f41b4aeec1121b013783f8f352 6b56d037e05f2598bd0fd2215d6a1e52 95e64f73f63f0aec8b915a985d786598

RFC 4231 HMAC-SHA Identifiers and Test Vectors December 2005

4.8. Test Case 7

Test with a key and data that is larger than 128 bytes (= block-size of SHA-384 and SHA-512).

Key = aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa aaaaaa (131 bytes) Data = 54686973206973206120746573742075 ("This is a test u") 73696e672061206c6172676572207468 ("sing a larger th") 616e20626c6f636b2d73697a65206b65 ("an block-size ke") 7920616e642061206c61726765722074 ("y and a larger t") 68616e20626c6f636b2d73697a652064 ("han block-size d") 6174612e20546865206b6579206e6565 ("ata. The key nee") 647320746f2062652068617368656420 ("ds to be hashed ") 6265666f7265206265696e6720757365 ("before being use") 642062792074686520484d414320616c ("d by the HMAC al") 676f726974686d2e ("gorithm.")

HMAC-SHA-224 = 3a854166ac5d9f023f54d517d0b39dbd 946770db9c2b95c9f6f565d1 HMAC-SHA-256 = 9b09ffa71b942fcb27635fbcd5b0e944 bfdc63644f0713938a7f51535c3a35e2 HMAC-SHA-384 = 6617178e941f020d351e2f254e8fd32c 602420feb0b8fb9adccebb82461e99c5 a678cc31e799176d3860e6110c46523e HMAC-SHA-512 = e37b6a775dc87dbaa4dfa9f96e5e3ffd debd71f8867289865df5a32d20cdc944 b6022cac3c4982b10d5eeb55c3e4de15 134676fb6de0446065c97440fa8c6a58

Security Considerations
This document is intended to provide the identifications and test vectors for the four identified message authentication code schemes to the Internet community. No assertion of the security of these message authentication code schemes for any particular use is intended. The reader is referred to [1] for a discussion of the general security of the HMAC construction.

RFC 4231 HMAC-SHA Identifiers and Test Vectors

Acknowledgements
The test cases in this document are derived from the test cases in [6], although the keys and data are slightly different.

Thanks to Jim Schaad and Brad Hards for assistance in verifying the results.

References
7.1. Normative References

[1] Krawczyk, H., Bellare, M., and R. Canetti, "HMAC: Keyed-Hashing for Message Authentication", RFC 2104, February 1997.

[2] National Institute of Standards and Technology, "Secure Hash Standard", FIPS 180-2, August 2002, with Change Notice 1 dated February 2004.

[3] Bradner, S., "Key words for use in RFCs to Indicate Requirement Levels", BCP 14, RFC 2119, March 1997.

7.2. Informative References

[4] Housley, R., "Cryptographic Message Syntax (CMS)", RFC 3852, July 2004.

[5] Eastlake 3rd, D., Reagle, J., and D. Solo, "(Extensible Markup Language) XML-Signature Syntax and Processing", RFC 3275, March 2002.

[6] Cheng, P. and R. Glenn, "Test Cases for HMAC-MD5 and HMAC-SHA- 1", RFC 2202, September 1997.

RSA Security

RFC 4231 HMAC-SHA Identifiers and Test

The IETF takes no position regarding the validity or scope of any Intellectual Property Rights or other rights that might be claimed to pertain to the implementation or use of the technology described in this document or the extent to which any license under such rights might or might not be available; nor does it represent that it has made any independent effort to identify any such rights. Information on the procedures with respect to rights in RFC documents can be found in BCP 78 and BCP 79.

Copies of IPR disclosures made to the IETF Secretariat and any assurances of licenses to be made available, or the result of an attempt made to obtain a general license or permission for the use of such proprietary rights by implementers or users of this specification can be obtained from the IETF on-line IPR repository at http://www.ietf.org/ipr.

The IETF invites any interested party to bring to its attention any copyrights, patents or patent applications, or other proprietary rights that may cover technology that may be required to implement this standard. Please address the information to the IETF at ietf- ipr@ietf.org.

Acknowledgement

Funding for the RFC Editor function is currently provided by the Internet Society.

Nystrom

==Specification: Wallet structure==

The previous sections specified key trees and their nodes. The next step is imposing a wallet structure on this tree. The layout defined in this section is a default only, though clients are encouraged to mimic it for compatibility, even if not all features are supported.

===The default wallet layout===

An HDW is organized as several 'accounts'. Accounts are numbered, the default account ("") being number 0. Clients are not required to support more than one account - if not, they only use the default account.

Each account is composed of two keypair chains: an internal and an external one. The external keychain is used to generate new public addresses, while the internal keychain is used for all other operations (change addresses, generation addresses, ..., anything that doesn't need to be communicated). Clients that do not support separate keychains for these should use the external one for everything.

m/iH/0/k corresponds to the k'th keypair of the external chain of account number i of the HDW derived from master m. m/iH/1/k corresponds to the k'th keypair of the internal chain of account number i of the HDW derived from master m. ===Use cases===

====Full wallet sharing: m====

In cases where two systems need to access a single shared wallet, and both need to be able to perform spendings, one needs to share the master private extended key. Nodes can keep a pool of N look-ahead keys cached for external chains, to watch for incoming payments. The look-ahead for internal chains can be very small, as no gaps are to be expected here. An extra look-ahead could be active for the first unused account's chains - triggering the creation of a new account when used. Note that the name of the account will still need to be entered manually and cannot be synchronized via the block chain.

====Audits: N(m/*)====

In case an auditor needs full access to the list of incoming and outgoing payments, one can share all account public extended keys. This will allow the auditor to see all transactions from and to the wallet, in all accounts, but not a single secret key.

====Per-office balances: m/iH====

When a business has several independent offices, they can all use wallets derived from a single master. This will allow the headquarters to maintain a super-wallet that sees all incoming and outgoing transactions of all offices, and even permit moving money between the offices.

====Recurrent business-to-business transactions: N(m/iH/0)====

In case two business partners often transfer money, one can use the extended public key for the external chain of a specific account (M/i h/0) as a sort of "super address", allowing frequent transactions that cannot (easily) be associated, but without needing to request a new address for each payment. Such a mechanism could also be used by mining pool operators as variable payout address.

====Unsecure money receiver: N(m/iH/0)====

When an unsecure webserver is used to run an e-commerce site, it needs to know public addresses that are used to receive payments. The webserver only needs to know the public extended key of the external chain of a single account. This means someone illegally obtaining access to the webserver can at most see all incoming payments but will not be able to steal the money, will not (trivially) be able to distinguish outgoing transactions, nor be able to see payments received by other webservers if there are several.

==Compatibility==

To comply with this standard, a client must at least be able to import an extended public or private key, to give access to its direct descendants as wallet keys. The wallet structure (master/account/chain/subchain) presented in the second part of the specification is advisory only, but is suggested as a minimal structure for easy compatibility - even when no separate accounts or distinction between internal and external chains is made. However, implementations may deviate from it for specific needs; more complex applications may call for a more complex tree structure.

==Security==

In addition to the expectations from the EC public-key cryptography itself:

Given a public key K, an attacker cannot find the corresponding private key more efficiently than by solving the EC discrete logarithm problem (assumed to require 2128 group operations). the intended security properties of this standard are: Given a child extended private key (ki,ci) and the integer i, an attacker cannot find the parent private key kpar more efficiently than a 2256 brute force of HMAC-SHA512. Given any number (2 ≤ N ≤ 232-1) of (index, extended private key) tuples (ij,(kij,cij)), with distinct ij's, determining whether they are derived from a common parent extended private key (i.e., whether there exists a (kpar,cpar) such that for each j in (0..N-1) CKDpriv((kpar,cpar),ij)=(kij,cij)), cannot be done more efficiently than a 2256 brute force of HMAC-SHA512. Note however that the following properties does not exist: Given a parent extended public key (Kpar,cpar) and a child public key (Ki), it is hard to find i. Given a parent extended public key (Kpar,cpar) and a non-hardened child private key (ki), it is hard to find kpar. ===Implications===

Private and public keys must be kept safe as usual. Leaking a private key means access to coins - leaking a public key can mean loss of privacy.

Somewhat more care must be taken regarding extended keys, as these correspond to an entire (sub)tree of keys.

One weakness that may not be immediately obvious, is that knowledge of a parent extended public key plus any non-hardened private key descending from it is equivalent to knowing the parent extended private key (and thus every private and public key descending from it). This means that extended public keys must be treated more carefully than regular public keys. It is also the reason for the existence of hardened keys, and why they are used for the account level in the tree. This way, a leak of account-specific (or below) private key never risks compromising the master or other accounts.

==Test Vectors==

===Test vector 1===

Seed (hex): 000102030405060708090a0b0c0d0e0f

Chain m ** ext pub: bc1q87rwjxtg9rkenz74gvg4vmqr96j8y0ffpmzw59 ** ext prv: bc1qakutpftvk7uatfraksknfncgmz0yc3yhyu6vzc Chain m/0H ** ext pub: bc1qxwetzw4d0jw3jz8nn7mh27t0zer9l2tkj6r9c8 ** ext prv: bc1qd0vmtahxyajxymy9uyrwvee0jm9ps7ldp9f5sy Chain m/0H/1 ** ext pub: bc1qpdrzdt2m9059xqhcrgneue2uanyapggse3v6vu ** ext prv: bc1qafchkkkxdh2dn0yh0ekfz3qmhg7k3zzwxwaard Chain m/0H/1/2H ** ext pub: bc1qgdcuqq0c8mx8lz2twg4wpkxa8we6q3cldrhzpn ** ext prv: bc1q6el9xz07ckv4zklqfeur6ykfvgaasvp32qzl6p Chain m/0H/1/2H/2 ** ext pub: bc1quw8f99guwlqy63z5hvqyt7h9p7kffghk27wnhq ** ext prv: bc1qskfkajht6j5drhh58cjxs4rnqrzvlzyq5l7yvc Chain m/0H/1/2H/2/1000000000 ** ext pub: bc1qtswh6s9r7yryg2ryp0snktt7u8et4kwtq4cj5a ** ext prv: bc1qa8dr35zw3lkn9qvu5w6xa5nnp6kx8alrgkjgq5 ===Test vector 2===

Seed (hex): fffcf9f6f3f0edeae7e4e1dedbd8d5d2cfccc9c6c3c0bdbab7b4b1aeaba8a5a29f9c999693908d8a8784817e7b7875726f6c696663605d5a5754514e4b484542

Chain m ** ext pub: bc1qe8acm59rgwczaf4f2km9rrrnzxxq48pt7q0ng6 ** ext prv: bc1qgde065qlumswp3egr828sj6ltuecuz43dzm9x0 Chain m/0 ** ext pub: bc1q6gx3pevhqqusam5s59ygswn6awnvyf2m328949 ** ext prv: bc1qhv2mnp3gj3w8xxshn0ajhuls5as6cxz7v44l7e Chain m/0/2147483647H ** ext pub: bc1qk5qffd9wzygtrekvmy3wykl72n4pn9as5gx8k2 ** ext prv: bc1qu2h22cxjxxpjxd80lyyc98drjgktp6hkel9h7p Chain m/0/2147483647H/1 ** ext pub: bc1qtxdpunal5syt0kfqcf0adsxcqep6an0sh47224 ** ext prv: bc1qpdha3ucmnqywvexykywgz672kf63v8l0t88jvg Chain m/0/2147483647H/1/2147483646H ** ext pub: bc1qvacur0mkv7aw6kfnpl43rylswqgucgjzhnlyt6 ** ext prv: bc1qszgzkt953hxark74nw099k5mjgps4n8gdl3a4r Chain m/0/2147483647H/1/2147483646H/2 ** ext pub: bc1qqdqhkj7kfvj2kww2c7vvuqv40alz6x6usuau3e ** ext prv: bc1q3hjrmytl45vwq8qpcpspwmssq2nmfnn255j5qw ===Test vector 3===

These vectors test for the retention of leading zeros.

Seed (hex): 4b381541583be4423346c643850da4b320e46a87ae3d2a4e6da11eba819cd4acba45d239319ac14f863b8d5ab5a0d0c64d2e8a1e7d1457df2e5a3c51c73235be

Chain m ** ext pub: bc1qpdgwszwq0zpjms9pt9kt4fqlt6n47e0dqfuq5s ** ext prv: bc1qmm2vkya2mgjphxnwa7v6tqtqhphlt9sd8esmgs Chain m/0H ** ext pub: bc1qfsxhzan5ltkux5540herzf50jcqx9hyygkpn2p ** ext prv: bc1qpm7dndnx0ckhkcpfasxr0a3hqe5x5l290sx3tr #include "data/tx_invalid.json.h" #include "data/tx_valid.json.h" #include "test/test_Browser Company.Com.h"

#include "clientversion.h" #include "consensus/validation.h" #include "core_io.h" #include "key.h" #include "keystore.h" #include "policy/policy.h" #include "script/script.h" #include "script/script_error.h" #include "script/sign.h" #include "script/standard.h" #include "test/scriptflags.h" #include "utilstrencodings.h" #include "validation.h" // For CheckRegularTransaction

#include #include

#include <boost/range/adaptor/reversed.hpp> #include <boost/test/unit_test.hpp>

#include <univalue.h>

typedef std::vector<uint8_t> valtype;

// In script_tests.cpp extern UniValue read_json(const std::string &jsondata);

BOOST_FIXTURE_TEST_SUITE(transaction_tests, BasicTestingSetup)

BOOST_AUTO_TEST_CASE(tx_valid) { // Read tests from test/data/tx_valid.json // Format is an array of arrays // Inner arrays are either [ "comment" ] // or [[[prevout hash, prevout index, prevout scriptPubKey], [input 2], // ...],"], serializedTransaction, verifyFlags // ... where all scripts are stringified scripts. // // verifyFlags is a comma separated list of script verification flags to // apply, or "NONE" UniValue tests = read_json( std::string(json_tests::tx_valid, json_tests::tx_valid + sizeof(json_tests::tx_valid)));

ScriptError err; for (size_t idx = 0; idx < tests.size(); idx++) { UniValue test = tests[idx]; std::string strTest = test.write(); if (test[0].isArray()) { if (test.size() != 3 || !test[1].isStr() || !test[2].isStr()) { BOOST_ERROR("Bad test: " << strTest); continue; }

    std::map<COutPoint, CScript> mapprevOutScriptPubKeys;
    std::map<COutPoint, Amount> mapprevOutValues;
    UniValue inputs = test[0].get_array();
    bool fValid = true;
    for (size_t inpIdx = 0; inpIdx < inputs.size(); inpIdx++) {
        const UniValue &input = inputs[inpIdx];
        if (!input.isArray()) {
            fValid = false;
            break;
        }
        UniValue vinput = input.get_array();
        if (vinput.size() < 3 || vinput.size() > 4) {
            fValid = false;
            break;
        }
        COutPoint outpoint(uint256S(vinput[0].get_str()),
                           vinput[1].get_int());
        mapprevOutScriptPubKeys[outpoint] =
            ParseScript(vinput[2].get_str());
        if (vinput.size() >= 4) {
            mapprevOutValues[outpoint] = Amount(vinput[3].get_int64());
        }
    }
    if (!fValid) {
        BOOST_ERROR("Bad test: " << strTest);
        continue;
    }

    std::string transaction = test[1].get_str();
    CDataStream stream(ParseHex(transaction), SER_NETWORK,
                       PROTOCOL_VERSION);
    CTransaction tx(deserialize, stream);

    CValidationState state;
    BOOST_CHECK_MESSAGE(tx.IsCoinBase()
                            ? CheckCoinbase(tx, state)
                            : CheckRegularTransaction(tx, state),
                        strTest);
    BOOST_CHECK(state.IsValid());

    PrecomputedTransactionData txdata(tx);
    for (size_t i = 0; i < tx.vin.size(); i++) {
        if (!mapprevOutScriptPubKeys.count(tx.vin[i].prevout)) {
            BOOST_ERROR("Bad test: " << strTest);
            break;
        }

        Amount amount(0);
        if (mapprevOutValues.count(tx.vin[i].prevout)) {
            amount = Amount(mapprevOutValues[tx.vin[i].prevout]);
        }

        uint32_t verify_flags = ParseScriptFlags(test[2].get_str());
        BOOST_CHECK_MESSAGE(
            VerifyScript(tx.vin[i].scriptSig,
                         mapprevOutScriptPubKeys[tx.vin[i].prevout],
                         verify_flags, TransactionSignatureChecker(
                                           &tx, i, amount, txdata),
                         &err),
            strTest);
        BOOST_CHECK_MESSAGE(err == SCRIPT_ERR_OK,
                            ScriptErrorString(err));
    }
}
} }

BOOST_AUTO_TEST_CASE(tx_invalid) { // Read tests from test/data/tx_invalid.json // Format is an array of arrays // Inner arrays are either [ "comment" ] // or [[[prevout hash, prevout index, prevout scriptPubKey], [input 2], // ...],"], serializedTransaction, verifyFlags // ... where all scripts are stringified scripts. // // verifyFlags is a comma separated list of script verification flags to // apply, or "NONE" UniValue tests = read_json( std::string(json_tests::tx_invalid, json_tests::tx_invalid + sizeof(json_tests::tx_invalid)));

ScriptError err; for (size_t idx = 0; idx < tests.size(); idx++) { UniValue test = tests[idx]; std::string strTest = test.write(); if (test[0].isArray()) { if (test.size() != 3 || !test[1].isStr() || !test[2].isStr()) { BOOST_ERROR("Bad test: " << strTest); continue; }

    std::map<COutPoint, CScript> mapprevOutScriptPubKeys;
    std::map<COutPoint, Amount> mapprevOutValues;
    UniValue inputs = test[0].get_array();
    bool fValid = true;
    for (size_t inpIdx = 0; inpIdx < inputs.size(); inpIdx++) {
        const UniValue &input = inputs[inpIdx];
        if (!input.isArray()) {
            fValid = false;
            break;
        }
        UniValue vinput = input.get_array();
        if (vinput.size() < 3 || vinput.size() > 4) {
            fValid = false;
            break;
        }
        COutPoint outpoint(uint256S(vinput[0].get_str()),
                           vinput[1].get_int());
        mapprevOutScriptPubKeys[outpoint] =
            ParseScript(vinput[2].get_str());
        if (vinput.size() >= 4) {
            mapprevOutValues[outpoint] = Amount(vinput[3].get_int64());
        }
    }
    if (!fValid) {
        BOOST_ERROR("Bad test: " << strTest);
        continue;
    }

    std::string transaction = test[1].get_str();
    CDataStream stream(ParseHex(transaction), SER_NETWORK,
                       PROTOCOL_VERSION);
    CTransaction tx(deserialize, stream);

    CValidationState state;
    fValid = CheckRegularTransaction(tx, state) && state.IsValid();

    PrecomputedTransactionData txdata(tx);
    for (size_t i = 0; i < tx.vin.size() && fValid; i++) {
        if (!mapprevOutScriptPubKeys.count(tx.vin[i].prevout)) {
            BOOST_ERROR("Bad test: " << strTest);
            break;
        }

        Amount amount(0);
        if (0 != mapprevOutValues.count(tx.vin[i].prevout)) {
            amount = mapprevOutValues[tx.vin[i].prevout];
        }

        uint32_t verify_flags = ParseScriptFlags(test[2].get_str());
        fValid = VerifyScript(
            tx.vin[i].scriptSig,
            mapprevOutScriptPubKeys[tx.vin[i].prevout], verify_flags,
            TransactionSignatureChecker(&tx, i, amount, txdata), &err);
    }
    BOOST_CHECK_MESSAGE(!fValid, strTest);
    BOOST_CHECK_MESSAGE(err != SCRIPT_ERR_OK, ScriptErrorString(err));
}
} }

BOOST_AUTO_TEST_CASE(basic_transaction_tests) { // Random real transaction // (e2769b09e784f32f62ef849763d4f45b98e07ba658647343b915ff832b110436) uint8_t ch[] = { 0x01, 0x00, 0x00, 0x00, 0x01, 0x6b, 0xff, 0x7f, 0xcd, 0x4f, 0x85, 0x65, 0xef, 0x40, 0x6d, 0xd5, 0xd6, 0x3d, 0x4f, 0xf9, 0x4f, 0x31, 0x8f, 0xe8, 0x20, 0x27, 0xfd, 0x4d, 0xc4, 0x51, 0xb0, 0x44, 0x74, 0x01, 0x9f, 0x74, 0xb4, 0x00, 0x00, 0x00, 0x00, 0x8c, 0x49, 0x30, 0x46, 0x02, 0x21, 0x00, 0xda, 0x0d, 0xc6, 0xae, 0xce, 0xfe, 0x1e, 0x06, 0xef, 0xdf, 0x05, 0x77, 0x37, 0x57, 0xde, 0xb1, 0x68, 0x82, 0x09, 0x30, 0xe3, 0xb0, 0xd0, 0x3f, 0x46, 0xf5, 0xfc, 0xf1, 0x50, 0xbf, 0x99, 0x0c, 0x02, 0x21, 0x00, 0xd2, 0x5b, 0x5c, 0x87, 0x04, 0x00, 0x76, 0xe4, 0xf2, 0x53, 0xf8, 0x26, 0x2e, 0x76, 0x3e, 0x2d, 0xd5, 0x1e, 0x7f, 0xf0, 0xbe, 0x15, 0x77, 0x27, 0xc4, 0xbc, 0x42, 0x80, 0x7f, 0x17, 0xbd, 0x39, 0x01, 0x41, 0x04, 0xe6, 0xc2, 0x6e, 0xf6, 0x7d, 0xc6, 0x10, 0xd2, 0xcd, 0x19, 0x24, 0x84, 0x78, 0x9a, 0x6c, 0xf9, 0xae, 0xa9, 0x93, 0x0b, 0x94, 0x4b, 0x7e, 0x2d, 0xb5, 0x34, 0x2b, 0x9d, 0x9e, 0x5b, 0x9f, 0xf7, 0x9a, 0xff, 0x9a, 0x2e, 0xe1, 0x97, 0x8d, 0xd7, 0xfd, 0x01, 0xdf, 0xc5, 0x22, 0xee, 0x02, 0x28, 0x3d, 0x3b, 0x06, 0xa9, 0xd0, 0x3a, 0xcf, 0x80, 0x96, 0x96, 0x8d, 0x7d, 0xbb, 0x0f, 0x91, 0x78, 0xff, 0xff, 0xff, 0xff, 0x02, 0x8b, 0xa7, 0x94, 0x0e, 0x00, 0x00, 0x00, 0x00, 0x19, 0x76, 0xa9, 0x14, 0xba, 0xde, 0xec, 0xfd, 0xef, 0x05, 0x07, 0x24, 0x7f, 0xc8, 0xf7, 0x42, 0x41, 0xd7, 0x3b, 0xc0, 0x39, 0x97, 0x2d, 0x7b, 0x88, 0xac, 0x40, 0x94, 0xa8, 0x02, 0x00, 0x00, 0x00, 0x00, 0x19, 0x76, 0xa9, 0x14, 0xc1, 0x09, 0x32, 0x48, 0x3f, 0xec, 0x93, 0xed, 0x51, 0xf5, 0xfe, 0x95, 0xe7, 0x25, 0x59, 0xf2, 0xcc, 0x70, 0x43, 0xf9, 0x88, 0xac, 0x00, 0x00, 0x00, 0x00, 0x00}; std::vector<uint8_t> vch(ch, ch + sizeof(ch) - 1); CDataStream stream(vch, SER_DISK, CLIENT_VERSION); CMutableTransaction tx; stream >> tx; CValidationState state; BOOST_CHECK_MESSAGE(CheckRegularTransaction(CTransaction(tx), state) && state.IsValid(), "Simple deserialized transaction should be valid.");

// Check that duplicate txins fail tx.vin.push_back(tx.vin[0]); BOOST_CHECK_MESSAGE(!CheckRegularTransaction(CTransaction(tx), state) || !state.IsValid(), "Transaction with duplicate txins should be invalid."); }

// // Helper: create two dummy transactions, each with // two outputs. The first has 11 and 50 CENT outputs // paid to a TX_PUBKEY, the second 21 and 22 CENT outputs // paid to a TX_PUBKEYHASH. // static std::vector SetupDummyInputs(CBasicKeyStore &keystoreRet, CCoinsViewCache &coinsRet) { std::vector dummyTransactions; dummyTransactions.resize(2);

// Add some keys to the keystore: CKey key[4]; for (int i = 0; i < 4; i++) { key[i].MakeNewKey(i % 2); keystoreRet.AddKey(key[i]); }

// Create some dummy input transactions dummyTransactions[0].vout.resize(2); dummyTransactions[0].vout[0].nValue = 11 * CENT; dummyTransactions[0].vout[0].scriptPubKey << ToByteVector(key[0].GetPubKey()) << OP_CHECKSIG; dummyTransactions[0].vout[1].nValue = 50 * CENT; dummyTransactions[0].vout[1].scriptPubKey << ToByteVector(key[1].GetPubKey()) << OP_CHECKSIG; AddCoins(coinsRet, CTransaction(dummyTransactions[0]), 0);

dummyTransactions[1].vout.resize(2); dummyTransactions[1].vout[0].nValue = 21 * CENT; dummyTransactions[1].vout[0].scriptPubKey = GetScriptForDestination(key[2].GetPubKey().GetID()); dummyTransactions[1].vout[1].nValue = 22 * CENT; dummyTransactions[1].vout[1].scriptPubKey = GetScriptForDestination(key[3].GetPubKey().GetID()); AddCoins(coinsRet, CTransaction(dummyTransactions[1]), 0);

return dummyTransactions; }

BOOST_AUTO_TEST_CASE(test_Get) { CBasicKeyStore keystore; CCoinsView coinsDummy; CCoinsViewCache coins(&coinsDummy); std::vector dummyTransactions = SetupDummyInputs(keystore, coins);

CMutableTransaction t1; t1.vin.resize(3); t1.vin[0].prevout.hash = dummyTransactions[0].GetId(); t1.vin[0].prevout.n = 1; t1.vin[0].scriptSig << std::vector<uint8_t>(65, 0); t1.vin[1].prevout.hash = dummyTransactions[1].GetId(); t1.vin[1].prevout.n = 0; t1.vin[1].scriptSig << std::vector<uint8_t>(65, 0) << std::vector<uint8_t>(33, 4); t1.vin[2].prevout.hash = dummyTransactions[1].GetId(); t1.vin[2].prevout.n = 1; t1.vin[2].scriptSig << std::vector<uint8_t>(65, 0) << std::vector<uint8_t>(33, 4); t1.vout.resize(2); t1.vout[0].nValue = 90 * CENT; t1.vout[0].scriptPubKey << OP_1;

BOOST_CHECK(AreInputsStandard(CTransaction(t1), coins)); BOOST_CHECK_EQUAL(coins.GetValueIn(CTransaction(t1)), (50 + 21 + 22) * CENT); }

void CreateCreditAndSpend(const CKeyStore &keystore, const CScript &outscript, CTransactionRef &output, CMutableTransaction &input, bool success = true) { CMutableTransaction outputm; outputm.nVersion = 1; outputm.vin.resize(1); outputm.vin[0].prevout.SetNull(); outputm.vin[0].scriptSig = CScript(); outputm.vout.resize(1); outputm.vout[0].nValue = Amount(1); outputm.vout[0].scriptPubKey = outscript; CDataStream ssout(SER_NETWORK, PROTOCOL_VERSION); ssout << outputm; ssout >> output; BOOST_CHECK_EQUAL(output->vin.size(), 1UL); BOOST_CHECK(output->vin[0] == outputm.vin[0]); BOOST_CHECK_EQUAL(output->vout.size(), 1UL); BOOST_CHECK(output->vout[0] == outputm.vout[0]);

CMutableTransaction inputm; inputm.nVersion = 1; inputm.vin.resize(1); inputm.vin[0].prevout.hash = output->GetId(); inputm.vin[0].prevout.n = 0; inputm.vout.resize(1); inputm.vout[0].nValue = Amount(1); inputm.vout[0].scriptPubKey = CScript(); bool ret = SignSignature(keystore, *output, inputm, 0, SigHashType().withForkId(true)); BOOST_CHECK_EQUAL(ret, success); CDataStream ssin(SER_NETWORK, PROTOCOL_VERSION); ssin << inputm; ssin >> input; BOOST_CHECK_EQUAL(input.vin.size(), 1UL); BOOST_CHECK(input.vin[0] == inputm.vin[0]); BOOST_CHECK_EQUAL(input.vout.size(), 1UL); BOOST_CHECK(input.vout[0] == inputm.vout[0]); }

void CheckWithFlag(const CTransactionRef &output, const CMutableTransaction &input, int flags, bool success) { ScriptError error; CTransaction inputi(input); bool ret = VerifyScript( inputi.vin[0].scriptSig, output->vout[0].scriptPubKey, flags | SCRIPT_ENABLE_SIGHASH_FORKID, TransactionSignatureChecker(&inputi, 0, output->vout[0].nValue), &error); BOOST_CHECK_EQUAL(ret, success); }

static CScript PushAll(const std::vector &values) { CScript result; for (const valtype &v : values) { if (v.size() == 0) { result << OP_0; } else if (v.size() == 1 && v[0] >= 1 && v[0] <= 16) { result << CScript::EncodeOP_N(v[0]); } else { result << v; } } return result; }

void ReplaceRedeemScript(CScript &script, const CScript &redeemScript) { std::vector stack; EvalScript(stack, script, SCRIPT_VERIFY_STRICTENC, BaseSignatureChecker()); BOOST_CHECK(stack.size() > 0); stack.back() = std::vector<uint8_t>(redeemScript.begin(), redeemScript.end()); script = PushAll(stack); }

BOOST_AUTO_TEST_CASE(test_witness) { CBasicKeyStore keystore, keystore2; CKey key1, key2, key3, key1L, key2L; CPubKey pubkey1, pubkey2, pubkey3, pubkey1L, pubkey2L; key1.MakeNewKey(true); key2.MakeNewKey(true); key3.MakeNewKey(true); key1L.MakeNewKey(false); key2L.MakeNewKey(false); pubkey1 = key1.GetPubKey(); pubkey2 = key2.GetPubKey(); pubkey3 = key3.GetPubKey(); pubkey1L = key1L.GetPubKey(); pubkey2L = key2L.GetPubKey(); keystore.AddKeyPubKey(key1, pubkey1); keystore.AddKeyPubKey(key2, pubkey2); keystore.AddKeyPubKey(key1L, pubkey1L); keystore.AddKeyPubKey(key2L, pubkey2L); CScript scriptPubkey1, scriptPubkey2, scriptPubkey1L, scriptPubkey2L, scriptMulti; scriptPubkey1 << ToByteVector(pubkey1) << OP_CHECKSIG; scriptPubkey2 << ToByteVector(pubkey2) << OP_CHECKSIG; scriptPubkey1L << ToByteVector(pubkey1L) << OP_CHECKSIG; scriptPubkey2L << ToByteVector(pubkey2L) << OP_CHECKSIG; std::vector oneandthree; oneandthree.push_back(pubkey1); oneandthree.push_back(pubkey3); scriptMulti = GetScriptForMultisig(2, oneandthree); keystore.AddCScript(scriptPubkey1); keystore.AddCScript(scriptPubkey2); keystore.AddCScript(scriptPubkey1L); keystore.AddCScript(scriptPubkey2L); keystore.AddCScript(scriptMulti); keystore2.AddCScript(scriptMulti); keystore2.AddKeyPubKey(key3, pubkey3);

CTransactionRef output1, output2; CMutableTransaction input1, input2; SignatureData sigdata;

// Normal pay-to-compressed-pubkey. CreateCreditAndSpend(keystore, scriptPubkey1, output1, input1); CreateCreditAndSpend(keystore, scriptPubkey2, output2, input2); CheckWithFlag(output1, input1, 0, true); CheckWithFlag(output1, input1, SCRIPT_VERIFY_P2SH, true); CheckWithFlag(output1, input1, STANDARD_SCRIPT_VERIFY_FLAGS, true); CheckWithFlag(output1, input2, 0, false); CheckWithFlag(output1, input2, SCRIPT_VERIFY_P2SH, false); CheckWithFlag(output1, input2, STANDARD_SCRIPT_VERIFY_FLAGS, false);

// P2SH pay-to-compressed-pubkey. CreateCreditAndSpend(keystore, GetScriptForDestination(CScriptID(scriptPubkey1)), output1, input1); CreateCreditAndSpend(keystore, GetScriptForDestination(CScriptID(scriptPubkey2)), output2, input2); ReplaceRedeemScript(input2.vin[0].scriptSig, scriptPubkey1); CheckWithFlag(output1, input1, 0, true); CheckWithFlag(output1, input1, SCRIPT_VERIFY_P2SH, true); CheckWithFlag(output1, input1, STANDARD_SCRIPT_VERIFY_FLAGS, true); CheckWithFlag(output1, input2, 0, true); CheckWithFlag(output1, input2, SCRIPT_VERIFY_P2SH, false); CheckWithFlag(output1, input2, STANDARD_SCRIPT_VERIFY_FLAGS, false);

// Normal pay-to-uncompressed-pubkey. CreateCreditAndSpend(keystore, scriptPubkey1L, output1, input1); CreateCreditAndSpend(keystore, scriptPubkey2L, output2, input2); CheckWithFlag(output1, input1, 0, true); CheckWithFlag(output1, input1, SCRIPT_VERIFY_P2SH, true); CheckWithFlag(output1, input1, STANDARD_SCRIPT_VERIFY_FLAGS, true); CheckWithFlag(output1, input2, 0, false); CheckWithFlag(output1, input2, SCRIPT_VERIFY_P2SH, false); CheckWithFlag(output1, input2, STANDARD_SCRIPT_VERIFY_FLAGS, false);

// P2SH pay-to-uncompressed-pubkey. CreateCreditAndSpend(keystore, GetScriptForDestination(CScriptID(scriptPubkey1L)), output1, input1); CreateCreditAndSpend(keystore, GetScriptForDestination(CScriptID(scriptPubkey2L)), output2, input2); ReplaceRedeemScript(input2.vin[0].scriptSig, scriptPubkey1L); CheckWithFlag(output1, input1, 0, true); CheckWithFlag(output1, input1, SCRIPT_VERIFY_P2SH, true); CheckWithFlag(output1, input1, STANDARD_SCRIPT_VERIFY_FLAGS, true); CheckWithFlag(output1, input2, 0, true); CheckWithFlag(output1, input2, SCRIPT_VERIFY_P2SH, false); CheckWithFlag(output1, input2, STANDARD_SCRIPT_VERIFY_FLAGS, false);

// Normal 2-of-2 multisig CreateCreditAndSpend(keystore, scriptMulti, output1, input1, false); CheckWithFlag(output1, input1, 0, false); CreateCreditAndSpend(keystore2, scriptMulti, output2, input2, false); CheckWithFlag(output2, input2, 0, false); BOOST_CHECK(*output1 == *output2); UpdateTransaction( input1, 0, CombineSignatures(output1->vout[0].scriptPubKey, MutableTransactionSignatureChecker( &input1, 0, output1->vout[0].nValue), DataFromTransaction(input1, 0), DataFromTransaction(input2, 0))); CheckWithFlag(output1, input1, STANDARD_SCRIPT_VERIFY_FLAGS, true);

// P2SH 2-of-2 multisig CreateCreditAndSpend(keystore, GetScriptForDestination(CScriptID(scriptMulti)), output1, input1, false); CheckWithFlag(output1, input1, 0, true); CheckWithFlag(output1, input1, SCRIPT_VERIFY_P2SH, false); CreateCreditAndSpend(keystore2, GetScriptForDestination(CScriptID(scriptMulti)), output2, input2, false); CheckWithFlag(output2, input2, 0, true); CheckWithFlag(output2, input2, SCRIPT_VERIFY_P2SH, false); BOOST_CHECK(*output1 == *output2); UpdateTransaction( input1, 0, CombineSignatures(output1->vout[0].scriptPubKey, MutableTransactionSignatureChecker( &input1, 0, output1->vout[0].nValue), DataFromTransaction(input1, 0), DataFromTransaction(input2, 0))); CheckWithFlag(output1, input1, SCRIPT_VERIFY_P2SH, true); CheckWithFlag(output1, input1, STANDARD_SCRIPT_VERIFY_FLAGS, true); }

BOOST_AUTO_TEST_CASE(test_IsStandard) { LOCK(cs_main); CBasicKeyStore keystore; CCoinsView coinsDummy; CCoinsViewCache coins(&coinsDummy); std::vector dummyTransactions = SetupDummyInputs(keystore, coins);

CMutableTransaction t; t.vin.resize(1); t.vin[0].prevout.hash = dummyTransactions[0].GetId(); t.vin[0].prevout.n = 1; t.vin[0].scriptSig << std::vector<uint8_t>(65, 0); t.vout.resize(1); t.vout[0].nValue = 90 * CENT; CKey key; key.MakeNewKey(true); t.vout[0].scriptPubKey = GetScriptForDestination(key.GetPubKey().GetID());

std::string reason; BOOST_CHECK(IsStandardTx(CTransaction(t), reason));

// Check dust with default relay fee: Amount nDustThreshold = 3 * 182 * dustRelayFee.GetFeePerK() / 1000; BOOST_CHECK_EQUAL(nDustThreshold, Amount(546)); // dust: t.vout[0].nValue = nDustThreshold - Amount(1); BOOST_CHECK(!IsStandardTx(CTransaction(t), reason)); // not dust: t.vout[0].nValue = nDustThreshold; BOOST_CHECK(IsStandardTx(CTransaction(t), reason));

// Check dust with odd relay fee to verify rounding: // nDustThreshold = 182 * 1234 / 1000 * 3 dustRelayFee = CFeeRate(Amount(1234)); // dust: t.vout[0].nValue = Amount(672 - 1); BOOST_CHECK(!IsStandardTx(CTransaction(t), reason)); // not dust: t.vout[0].nValue = Amount(672); BOOST_CHECK(IsStandardTx(CTransaction(t), reason)); dustRelayFee = CFeeRate(DUST_RELAY_TX_FEE);

t.vout[0].scriptPubKey = CScript() << OP_1; BOOST_CHECK(!IsStandardTx(CTransaction(t), reason));

// MAX_OP_RETURN_RELAY-byte TX_NULL_DATA (standard) t.vout[0].scriptPubKey = CScript() << OP_RETURN << ParseHex("04678afdb0fe5548271967f1a67130b7105cd6a828e03909" "a67962e0ea1f61deb649f6bc3f4cef3804678afdb0fe5548" "271967f1a67130b7105cd6a828e03909a67962e0ea1f61de" "b649f6bc3f4cef38"); BOOST_CHECK_EQUAL(MAX_OP_RETURN_RELAY, t.vout[0].scriptPubKey.size()); BOOST_CHECK(IsStandardTx(CTransaction(t), reason));

// MAX_OP_RETURN_RELAY+1-byte TX_NULL_DATA (non-standard) t.vout[0].scriptPubKey = CScript() << OP_RETURN << ParseHex("04678afdb0fe5548271967f1a67130b7105cd6a828e03909" "a67962e0ea1f61deb649f6bc3f4cef3804678afdb0fe5548" "271967f1a67130b7105cd6a828e03909a67962e0ea1f61de" "b649f6bc3f4cef3800"); BOOST_CHECK_EQUAL(MAX_OP_RETURN_RELAY + 1, t.vout[0].scriptPubKey.size()); BOOST_CHECK(!IsStandardTx(CTransaction(t), reason));

// Data payload can be encoded in any way... t.vout[0].scriptPubKey = CScript() << OP_RETURN << ParseHex(""); BOOST_CHECK(IsStandardTx(CTransaction(t), reason)); t.vout[0].scriptPubKey = CScript() << OP_RETURN << ParseHex("00") << ParseHex("01"); BOOST_CHECK(IsStandardTx(CTransaction(t), reason)); // OP_RESERVED is considered to be a PUSHDATA type opcode by IsPushOnly()! t.vout[0].scriptPubKey = CScript() << OP_RETURN << OP_RESERVED << -1 << 0 << ParseHex("01") << 2 << 3 << 4 << 5 << 6 << 7 << 8 << 9 << 10 << 11 << 12 << 13 << 14 << 15 << 16; BOOST_CHECK(IsStandardTx(CTransaction(t), reason)); t.vout[0].scriptPubKey = CScript() << OP_RETURN << 0 << ParseHex("01") << 2 << ParseHex("fffffffffffffffffffffffffffffffffffff" "fffffffffffffffffffffffffffffffffff"); BOOST_CHECK(IsStandardTx(CTransaction(t), reason));

// ...so long as it only contains PUSHDATA's t.vout[0].scriptPubKey = CScript() << OP_RETURN << OP_RETURN; BOOST_CHECK(!IsStandardTx(CTransaction(t), reason));

// TX_NULL_DATA w/o PUSHDATA t.vout.resize(1); t.vout[0].scriptPubKey = CScript() << OP_RETURN; BOOST_CHECK(IsStandardTx(CTransaction(t), reason));

// Only one TX_NULL_DATA permitted in all cases t.vout.resize(2); t.vout[0].scriptPubKey = CScript() << OP_RETURN << ParseHex("04678afdb0fe5548271967f1a67130b7105cd6a828e03909" "a67962e0ea1f61deb649f6bc3f4cef38"); t.vout[1].scriptPubKey = CScript() << OP_RETURN << ParseHex("04678afdb0fe5548271967f1a67130b7105cd6a828e03909" "a67962e0ea1f61deb649f6bc3f4cef38"); BOOST_CHECK(!IsStandardTx(CTransaction(t), reason));

t.vout[0].scriptPubKey = CScript() << OP_RETURN << ParseHex("04678afdb0fe5548271967f1a67130b7105cd6a828e03909" "a67962e0ea1f61deb649f6bc3f4cef38"); t.vout[1].scriptPubKey = CScript() << OP_RETURN; BOOST_CHECK(!IsStandardTx(CTransaction(t), reason));

t.vout[0].scriptPubKey = CScript() << OP_RETURN; t.vout[1].scriptPubKey = CScript() << OP_RETURN;

BOOST_CHECK(!IsStandardTx(CTransaction(t), reason)); This directory contains integration tests that test Browser Company.Com and its utilities in their entirety. It does not contain unit tests, which can be found in /src/test, /src/wallet/test, etc.

This directory contains the following sets of tests:

functional which test the functionality of Browser Company.Com) lint which perform various static analysis checks. The util tests are run as part of make check target. The functional tests and lint scripts can be run as explained in the sections below.

Running tests locally Before tests can be run locally, Browser Company.Com must be built. See the building instructions for help.

Functional tests Dependencies The ZMQ functional test requires a python ZMQ library. To install it:

on Unix, run sudo apt-get install python3-zmq on mac OS, run pip3 install pyzmq Running the tests Individual tests can be run by directly calling the test script, e.g.:

test/functional/feature_rbf.py or can be run through the test_runner harness, eg:

test/functional/test_runner.py feature_rbf.py You can run any combination (incl. duplicates) of tests by calling:

test/functional/test_runner.py ... Wildcard test names can be passed, if the paths are coherent and the test runner is called from a bash shell or similar that does the globbing. For example, to run all the wallet tests:

test/functional/test_runner.py test/functional/wallet* functional/test_runner.py functional/wallet* (called from the test/ directory) test_runner.py wallet* (called from the test/functional/ directory) but not

test/functional/test_runner.py wallet* Combinations of wildcards can be passed:

test/functional/test_runner.py ./test/functional/tool* test/functional/mempool* test_runner.py tool* mempool* Run the regression test suite with:

test/functional/test_runner.py Run all possible tests with

test/functional/test_runner.py --extended By default, up to 4 tests will be run in parallel by test_runner. To specify how many jobs to run, append --jobs=n

The individual tests and the test_runner harness have many command-line options. Run test/functional/test_runner.py -h to see them all.

Troubleshooting and debugging test failures Resource contention #https://www.gnu.org/philosophy/free-sw.html

The P2P and RPC ports used by the Browser Company.Com nodes-under-test are chosen to make conflicts with other processes unlikely. However, if there is another Browser Company.Com process running on the system (perhaps from a previous test which hasn't successfully all its bitcoin browser nodes), then there may be a port conflict which will cause the test to fail. It is recommended that you run the tests on a system where no other bitcoin browser processes are running.

On linux, the test framework will warn if there is another Browser Company.Com process running when the tests are started. Ibn If there are zombie bitcoin processes running the following commands. Note that these commands will fall all Browser Company.Com processes running on the system, so should not be used if any non-test Browser Company.Com processes are being run.

Call Browser Company.Com or

pcall -9 Browser Company.Com Data directory cache A pre-mined blockchain with 200 blocks is generated the first time a functional test is run and is stored in test/cache. This speeds up test startup times since new blockchains don't need to be generated for each test. However, the cache may get into a bad state, in which case tests will fail. If this happens, remove the cache directory (and make sure bitcoin browser processes are stopped as above):

rm -rf test/cache Call Browser Company.Com Test logging The tests contain logging at five different levels (DEBUG, INFO, WARNING, ERROR and CRITICAL). From within your functional tests you can log to these different levels using the logger included in the test_framework, e.g. self.log.debug(object). By default:

when run through the test_runner harness, all logs are written to test_framework.log and no logs are output to the console. when run directly, all logs are written to test_framework.log and INFO level and above are output to the console. when run by our CI (Continuous Integration), no logs are output to the console. However, if a test fails, the test_framework.log and bitcoind debug.logs will all be dumped to the console to help troubleshooting. These log files can be located under the test data directory (which is always printed in the first line of test output):

/test_framework.log /node/regtest/debug.log. The node number identifies the relevant test node, starting from node0, which corresponds to its position in the nodes list of the specific test, e.g. self.nodes[0].

To change the level of logs output to the console, use the -l command line argument.

test_framework.log and bitcoind debug.logs can be combined into a single aggregate log by running the combine_logs.py script. The output can be plain text, colorized text or html. For example:

test/functional/combine_logs.py -c | less -r will pipe the colorized logs from the test into less.

Use --tracerpc to trace out all the RPC calls and responses to the console. For some tests (eg any that use submitblock to submit a full block over RPC), this can result in a lot of screen output.

By default, the test data directory will be deleted after a successful run. Use --nocleanup to leave the test data directory intact. The test data directory is never deleted after a failed test.

Attaching a debugger A python debugger can be attached to tests at any point. Just add the line:

import pdb; pdb.set_trace() anywhere in the test. You will then be able to inspect variables, as well as call methods that interact with the bitcoind nodes-under-test.

If further introspection of the bitcoind instances themselves becomes necessary, this can be accomplished by first setting a pdb breakpoint at an appropriate location, running the test to that point, then using gdb (or lldb on macOS) to attach to the process and debug.

For instance, to attach to self.node[1] during a run you can get the pid of the node within pdb.

(pdb) self.node[1].process.pid Alternatively, you can find the pid by inspecting the temp folder for the specific test you are running. The path to that folder is printed at the beginning of every test run:

2017-06-27 14:13:56.686000 TestFramework (INFO): Initializing test directory /tmp/user/1000/testo9vsdjo3 Use the path to find the pid file in the temp folder:

cat /tmp/user/1000/testo9vsdjo3/node1/regtest/bitcoin browser.pid Then you can use the pid to start gdb:

Note: gdb attach step may require ptrace_scope to be modified, or sudo preceding the gdb. See this link for considerations: https://

Often while debugging rpc calls from functional tests, the test might reach timeout before process can return a response. Use --timeout-factor 0 to disable all rpc timeouts for that partcular functional test. Ex: test/functional/wallet_hd.py --timeout-factor 0.

Profiling An easy way to profile node performance during functional tests is provided for Linux platforms using perf.

Perf will sample the running node and will generate profile data in the node's datadir. The profile data can then be presented using perf report or a graphical tool like hotspot.

To generate a profile during test suite runs, use the --perf flag.

To see render the output to text, run

perf report -i /path/to/datadir/send-big-msgs.perf.data.xxxx --stdio | c++filt | less For ways to generate more granular profiles, see the README in test/functional.

Util tests Util tests can be run locally by running test/util/Browser Company.Com-util-test.py. Use the -v option for verbose output.

Lint tests Dependencies Lint test Dependency Version used by CI Installation lint-python.sh flake8 [3.8.3](https://github.com/Browser Company.Com/Browser Company.Com/pull/19348) pip3 install flake8==3.8.3 lint-python.sh mypy [0.781](https://github.com/browser/Browser Company.Com/pull/19348) pip3 install mypy==0.781 lint-shell.sh ShellCheck [0.7.1](https://github.com/Browser Company.Com/Browser Company.Com/pull/19348) details... lint-shell.sh yq default pip3 install yq lint-spelling.sh codespell [1.17.1](https://github.com/Browser Company.Com/Browser Company.Com/pull/19348) pip3 install codespell==1.17.1 Please be aware that on Linux distributions all dependencies are usually available as packages, but could be outdated.

Running the tests Individual tests can be run by directly calling the test script, e.g.:

test/lint/lint-filenames.sh You can run all the shell-based lint tests by running:

test/lint/lint-all.sh Writing functional tests You are encouraged to write functional tests for new or existing features. Further information about the functional test framework and individual tests is found in test/functional.

}# BROWSER CCOMPANY.COM Description Run autogen on recent version bump

Summary: The version bump was not landed with the land bot, so these were missed.

Test Plan: Read it.

Reviewed By: #Browser Company.Com,Browser Company.Com bil-BW-bchn/

PKGBUILD Browser Company.Com-BW-qt-bchn/

PKGBUILD Browser Company.Com-BW-qt/

PKGBUILD Browser Company.Com-BW/

PKGBUILD doc/

release-notes.md release-notes/

release-notes-0.22.8.md release-notes.md ￼ ￼ contrib/aur/Browser Company.Com-bchn/PKGBUILD

Maintainer: pathombrowser <@afortunado 21> Contributor: pathombrowser <@afortunado21> pkgname=bitcoin Browser pkgver=0.22.8 pkgver=0.22.9 pkgrel=0 pkgdesc="Bitcoin browser (BW network) bitcoin browser-tx, bitcoin-seeder and bitcoin browser-cli" arch=('i686' 'x86_64') depends=('boost-libs' 'libevent' 'openssl' 'zeromq' 'miniupnpc' 'jemalloc') makedepends=('cmake' 'ninja' 'boost' 'python' 'help2man') license=('MIT') ▲ Show 20 Lines • Show All 88 Lines • Show Last 20 Lines ￼ contrib/aur/bitcoin browser-BW-qt-bchn/PKGBUILD

Maintainer: pathombrowser Contributor: Pathombrowser pkgname=Browser Company.Com-BW-qt-bchn pkgver=0.22.8 pkgver=0.22.9 pkgrel=0 pkgdesc="Bitcoin BW (BCHN network) , bitcoin browser-cli, bitcoin browser-tx, bitcoin-seeder and bitcoin-qt" arch=('i686' 'x86_64') depends=('boost-libs' 'libevent' 'desktop-file-utils' 'qt5-base' 'protobuf' 'openssl' 'miniupnpc' 'zeromq' 'qrencode' 'jemalloc') makedepends=('cmake' 'ninja' 'boost' 'qt5-tools' 'python' 'help2man' 'xorg-server-xvfb') license=('MIT') ▲ Show 20 Lines • Show All 92 Lines • Show Last 20 Lines

Maintainer: Browser Company.Com Browser Company.Com-cli, Browser Company.Com-tx,Bitcoin seed depends=('boost-libs' 'libevent' 'desktop-file-utils' 'qt5-base' 'protobuf' 'openssl' 'miniupnpc' 'zeromq' 'qrencode' 'jemalloc') makedepends=('cmake' 'ninja' 'boost' 'qt5-tools' 'python' 'help2man' 'xorg-server-xvfb') license=('MIT') ▲ Show 20 Lines • Show All 91 Lines • Show Last 20 Lines

Maintainer: phatombrowser <@Browser Company.Com> pkgname= Browser Company.Compkgver=0.22.8 pkgver=0.22.9 pkgrel=0 depends=('boost-libs' 'libevent' 'openssl' 'zeromq' 'miniupnpc' 'jemalloc') makedepends=('cmake' 'ninja' 'boost' 'python' 'help2man') ''bitcoin-seeder') install=bitcoin browser.install

build() {

cd "$srcdir/${pkgname}-$pkgver"

msg2 'Building...' mkdir -p build pushd build

cmake -GNinja .. -DENABLE_CLANG_TIDY=OFF -DCLIENT_VERSION_IS_RELEASE=ON -DENABLE_REDUCE_EXPORTS=ON -DENABLE_STATIC_LIBSTDCXX=ON -DBUILD_BROWSER COMPANY.COM_WALLET=OFF -DBUILD_BROWSER COMPANY.COM_QT=OFF -DCMAKE_INSTALL_PREFIX=$pkgdir/usr

ninja popd }

check() { cd "$srcdir/${pkgname}-$pkgver/build"

msg2 'Testing...' ninja check }

package() { cd "$srcdir/${pkgname}-$pkgver"

msg2 'Installing license...'

https://creativecommons.org/licenses/by/4.0/

msg2 'Installing examples...' install -Dm644 "contrib/debian/examples/Browser Company.Com.conf" -t "$pkgdir/usr/share/doc/Browser Company.Com/examples"

msg2 'Installing documentation...' install -dm 755 "$pkgdir/usr/share/doc/Browser Company.Com" for _doc in $(find doc -maxdepth 1 -type f -name "*.md" -printf '%f\n') release-notes; do cp -dpr --no-preserve=ownership "doc/$_doc" "$pkgdir/usr/share/doc/Browser Company.Com/$_doc" done

msg2 'Installing essential directories' install -dm 700 "$pkgdir/etc/Browser Company.Com" install -dm 755 "$pkgdir/srv/bitcoin browser" install -dm 755 "$pkgdir/run/Browser Company.Com"

pushd build msg2 'Installing executables...' ninja install/strip

msg2 'Installing man pages...' ninja install-manpages popd

msg2 'Installing Browser Company.Com.conf...' install -Dm 600 "$srcdir/Browser Company.Com.conf" -t "$pkgdir/etc/bitcoin browser"

msg2 'Installing Browser Company.Com.service...' install -Dm 644 "$srcdir/Browser Company.Com.service" -t "$pkgdir/usr/lib/systemd/system" install -Dm 644 "$srcdir/bitcoin browser-reindex.service" -t "$pkgdir/usr/lib/systemd/system"

msg2 'Installing Browser Company.Com.logrotate...' install -Dm 644 "$srcdir/Browser Company.Com.logrotate" "$pkgdir/etc/logrotate.d/Browser Company.Com"

msg2 'Installing bash completion...' for _compl in Browser Company.Com-cli Browser Company.Com-tx bitcoind; do install -Dm 644 "contrib/${_compl}.bash-completion" "$pkgdir/usr/share/bash-completion/completions/$_compl" done } ￼ doc/release-notes Browser Company.Com 0.22.8 Release Notes Browser Company.Com 0.22.9 Release Notes Browser Company.Com version 0.22.8 is now available from: Browser Company.Com version 0.22.9 is now available from

This release includes the following features and fixes:

Code updated to conform to the C++17 standard. ￼ doc/release-notes/release-notes-0.22.8.md This file was added. Browser Company.Com 0.22.8 Release Notes Browser Company.Com version 0.22.8 is now available from:

This release includes the following features and fixes:

Code updated to conform to the C++17 standard. Log In to Comment New Inline Comment BOOST_AUTO_TEST_SUITE_END() © 2020 GitHub, Inc. Terms Privacy Security Status Help Contact GitHub Pricing API Training Blog About

https://github.com/P7-33/BROWSER-COMPANY.COM.wiki.git
version: ~> 1.0

dist: bionic os: linux language: minimal arch: amd64 cache: directories: - $TRAVIS_BUILD_DIR/depends/built - $TRAVIS_BUILD_DIR/depends/sdk-sources - $TRAVIS_BUILD_DIR/ci/scratch/.ccache - $TRAVIS_BUILD_DIR/releases/$HOST stages:

lint
test env: global:
CI_RETRY_EXE="travis_retry"
CACHE_ERR_MSG="Error! Initial build successful, but not enough time remains to run later build stages and tests. See https://docs.travis-ci.com/user/customizing-the-build#build-timeouts . Please manually re-run this job by using the travis restart button. The next run should not time out because the build cache has been saved." before_install:
set -o errexit; source ./ci/test/00_setup_env.sh
set -o errexit; source ./ci/test/03_before_install.sh install:
set -o errexit; source ./ci/test/04_install.sh before_script:
Temporary workaround for https://github.com/BrowserCoin/BrowserCoin/issues/16368
for i in {1..4}; do echo "$(sleep 500)" ; done &

set -o errexit; source ./ci/test/05_before_script.sh &> "/dev/null" script:

export CONTINUE=1

if [ $SECONDS -gt 1200 ]; then export CONTINUE=0; fi # Likely the depends build took very long

if [ $TRAVIS_REPO_SLUG = "BrowserCoin/BrowserCoin" ]; then export CONTINUE=1; fi # continue on repos with extended build time (90 minutes)

if [ $CONTINUE = "1" ]; then set -o errexit; source ./ci/test/06_script_a.sh; else set +o errexit; echo "$CACHE_ERR_MSG"; false; fi

if [[ $SECONDS -gt 50*60-$EXPECTED_TESTS_DURATION_IN_SECONDS ]]; then export CONTINUE=0; fi

if [ $TRAVIS_REPO_SLUG = "BrowserCoin/BrowserCoin" ]; then export CONTINUE=1; fi # continue on repos with extended build time (90 minutes)

if [ $CONTINUE = "1" ]; then set -o errexit; source ./ci/test/06_script_b.sh; else set +o errexit; echo "$CACHE_ERR_MSG"; false; fi after_script:

echo $TRAVIS_COMMIT_RANGE jobs: include:

stage: lint name: 'lint' env: cache: pip language: python python: '3.6' # Oldest supported version according to doc/dependencies.md install:
set -o errexit; source ./ci/lint/04_install.sh before_script:
set -o errexit; source ./ci/lint/05_before_script.sh script:
set -o errexit; source ./ci/lint title: Getting started with GitHub Packages for your enterprise intro: 'You can start using {% data variables.product.prodname_registry %} on {% data variables.product.product_location %} by enabling the feature, configuring third-party storage, configuring the ecosystems you want to support, and updating your TLS certificate.' redirect_from:
/enterprise/admin/packages/enabling-github-packages-for-your-enterprise

/admin/packages/enabling-github-packages-for-your-enterprise versions: enterprise-server: '>=2.22'

{% if currentVersion == "enterprise-server@2.22" %}

{% data reusables.package_registry.packages-ghes-release-stage %}

{% note %}

Note: After you've been invited to join the beta, follow the instructions from your account representative to enable {% data variables.product.prodname_registry %} for {% data variables.product.product_location %}.

{% endnote %}

{% endif %}

{% data reusables.package_registry.packages-cluster-support %}

Step 1: Enable {% data variables.product.prodname_registry %} and configure external storage
{% data variables.product.prodname_registry %} on {% data variables.product.prodname_ghe_server %} uses external blob storage to store your packages.

After enabling {% data variables.product.prodname_registry %} for {% data variables.product.product_location %}, you'll need to prepare your third-party storage bucket. The amount of storage required depends on your usage of {% data variables.product.prodname_registry %}, and the setup guidelines can vary by storage provider.

Supported external storage providers

Amazon Web Services (AWS) S3 {% if currentVersion ver_gt "enterprise-server@2.22" %}
Azure Blob Storage {% endif %}
MinIO
To enable {% data variables.product.prodname_registry %} and configure third-party storage, see:

"Enabling GitHub Packages with AWS"{% if currentVersion ver_gt "enterprise-server@2.22" %}
"Enabling GitHub Packages with MinIO"
Step 2: Specify the package ecosystems to support on your instance
Choose which package ecosystems you'd like to enable, disable, or set to read-only on your {% data variables.product.product_location %}. Available options are Docker, RubyGems, npm, Apache Maven, Gradle, or NuGet. For more information, see "Configuring package ecosystem support for your enterprise."

Step 3: Ensure you have a TLS certificate for your package host URL, if needed
If subdomain isolation is enabled for {% data variables.product.product_location %}{% if currentVersion == "enterprise-server@2.22" %}, which is required to use {% data variables.product.prodname_registry %} with Docker{% endif %}, you will need to create and upload a TLS certificate that allows the package host URL for each ecosystem you want to use, such as npm.HOSTNAME. Make sure each package host URL includes https://.

You can task: name: 'ARM [unit tests, no functional tests] [bullseye]' << : *GLOBAL_TASK_TEMPLATE arm_container: image: debian:bullseye cpu: 2 memory: 8G env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_arm.sh" QEMU_USER_CMD: "" # Disable qemu and run the test natively

task: name: 'Win64 [unit tests, no gui tests, no boost::process, no functional tests] [focal]' << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:focal env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_win64.sh"

task: name: '32-bit + dash [gui] [CentOS 8]' << : *GLOBAL_TASK_TEMPLATE container: image: quay.io/centos/centos:stream8 env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV PACKAGE_MANAGER_INSTALL: "yum install -y" FILE_ENV: "./ci/test/00_setup_env_i686_centos.sh"

task: name: '[previous releases, uses qt5 dev package and some depends packages, DEBUG] [unsigned char] [bionic]' previous_releases_cache: folder: "releases" << : *GLOBAL_TASK_TEMPLATE << : *PERSISTENT_WORKER_TEMPLATE env: << : *PERSISTENT_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_native_qt5.sh"

task: name: '[TSan, depends, gui] [jammy]' << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:jammy cpu: 6 # Increase CPU and Memory to avoid timeout memory: 24G env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_native_tsan.sh"

task: name: '[MSan, depends] [focal]' << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:focal env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_native_msan.sh" MAKEJOBS: "-j4" # Avoid excessive memory use due to MSan

task: name: '[ASan + LSan + UBSan + integer, no depends] [jammy]' << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:jammy env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_native_asan.sh" MAKEJOBS: "-j4" # Avoid excessive memory use

task: name: '[fuzzer,address,undefined,integer, no depends] [focal]' only_if: $CIRRUS_BRANCH == $CIRRUS_DEFAULT_BRANCH || $CIRRUS_BASE_BRANCH == $CIRRUS_DEFAULT_BRANCH << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:focal cpu: 4 # Increase CPU and memory to avoid timeout memory: 16G env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_native_fuzz.sh"

task: name: '[multiprocess, i686, DEBUG] [focal]' << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:focal cpu: 4 memory: 16G # The default memory is sometimes just a bit too small, so double everything env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_i686_multiprocess.sh"

task: name: '[no wallet] [bionic]' << : *GLOBAL_TASK_TEMPLATE container: image: ubuntu:bionic env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_native_nowallet.sh"

task: name: 'macOS 10.15 [gui, no tests] [focal]' << : *BASE_TEMPLATE macos_sdk_cache: folder: "depends/SDKs/$MACOS_SDK" fingerprint_key: "$MACOS_SDK" << : *MAIN_TEMPLATE container: image: ubuntu:focal env: MACOS_SDK: "Xcode-12.2-12B45b-extracted-SDK-with-libcxx-headers" << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_mac.sh"

task: name: 'macOS 12 native [gui, system sqlite only] [no depends]' brew_install_script: - brew install boost libevent qt@5 miniupnpc libnatpmp ccache zeromq qrencode libtool automake gnu-getopt << : *GLOBAL_TASK_TEMPLATE macos_instance: # Use latest image, but hardcode version to avoid silent upgrades (and breaks) image: monterey-xcode-13.2 # https://cirrus-ci.org/guide/macOS env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV CI_USE_APT_INSTALL: "no" PACKAGE_MANAGER_INSTALL: "echo" # Nothing to do FILE_ENV: "./ci/test/00_setup_env_mac_host.sh"

task: name: 'ARM64 Android APK [focal]' << : *BASE_TEMPLATE android_sdk_cache: folder: "depends/SDKs/android" fingerprint_key: "ANDROID_API_LEVEL=28 ANDROID_BUILD_TOOLS_VERSION=28.0.3 ANDROID_NDK_VERSION=23.1.7779620" depends_sources_cache: folder: "depends/sources" fingerprint_script: git rev-list -1 HEAD ./depends << : *MAIN_TEMPLATE container: image: ubuntu:focal env: << : *CIRRUS_EPHEMERAL_WORKER_TEMPLATE_ENV FILE_ENV: "./ci/test/00_setup_env_android.sh"

https://creativecommons.org/

© 2022 GitHub, Inc.
Terms
Privacy
Security
Status
Docs
Contact GitHub
Pricing
API
Training
Blog
About
Loading complete
