---
title: "What is a Hash? Hashing algorithms and the secrets they keep."
author: "Pradeep Loganathan"
date: 2017-07-01T15:55:13+10:00
draft: false
Author: Pradeep Loganathan
tags: 
  - 
categories: 
  - "blockchain"
  - "cryptography"

# description: "A hash is a one-way function that maps data of any arbitrary length to an output digest of fixed length."
ShowToc: true
TocOpen: true
---

# Hash

A hash is a one-way function that maps data of any arbitrary length to an output digest of fixed length, where it is computationally infeasible to find the input from the output. The values returned by a hash function are often known as Message digest, hash values, hash codes, hash sums, checksums, or simply hashes. Hash functions are keyless and provide the data integrity service. They are usually built using iterated and dedicated hash function construction techniques. A hash function compresses data to a fixed size, which could be considered a shortened reference to the original data. The hash function should be easy to compute but hard to invert for compression, hash functions usually utilize a one-way function of number theory; hence, they are irreversible. Consequently, it is infeasible to reconstruct specific data when a hash value is known. A hash is a one-way function because it cannot be reversed. We can think of a hash as a digital fingerprint of data that is input into it. These types of hash functions are used in many ways. They can be used for authentication, indexing data into hashed tables, checksums, and digital signatures. An example of an SHA256 hash looks like this, 4UsOw2gKuwzwFpY2UH8cDnfMOqHM7Gv5XZBFxDnV4Ww.

# Hash Functions

Two of the most used cryptographic hash functions are MD5 and SHA. Each algorithm is different from the others in terms of one or more parameters.

## MD5

MD5 was created in 1991 by Ronald Rivest. MD5 uses a 128-bits hash value. At first it was considered secure, but today most experts recommend not using MD5 for authentication, because of the many vulnerabilities found over the years. MD5 works by taking variable length data and converting it into a fixed length hash string of 128-bits.

## SHA

SHA is more secure than MD5. The creators of SHA are Guido Bertoni, Joan Daemen, Michael Peeters, and Gilles Van Assche.The Secure Hash Algorithm, or SHA Hash, is published by the National Institute of Standards and Technology (NIST) as a U.S. Federal Information Processing Standard - FIPS PUB 180-3, which specifies three flavors of the SHA Algorithm:

• **SHA-0:** No longer used.

• **SHA-1:** The most widely used version

• **SHA-2:** Comes in four different variants: SHA-224, SHA-256, SHA-384, and SHA-512

When a message of any length less than 264 bits (SHA-1, SHA-224, and SHA-256) or less than 2128 bits (SHA-384 & SHA-512) is input to a hash algorithm, the result is an output called a _message digest_. The message digests range in length from 160 to 512 bits, depending on the algorithm.  
The five hash algorithms specified in this standard are called secure because, for a given algorithm, it is computationally infeasible to find a message that corresponds to a given message digest, or to find two different messages that produce the same message digest. Any change to a message will, with a high probability, result in a different message digest. This will result in a verification failure when the secure hash algorithm is used with a digital signature algorithm or a keyed-hash message authentication algorithm.

### Types of SHA

#### SHA-1

The original specification of the algorithm was published in 1993 in FIPS PUB 180-1. This is the most widely used of the existing SHA hash functions and is employed in several widely used security applications and protocols, such as transport layer security (TLS), secure socket layer (SSL), pretty good privacy (PGP), Secure Shell (SSH), Secure/Multipurpose Internet Mail Extensions (S/MIME), and Internet Protocol Security (IPSEC). SHA-1 hashing is also used in distributed revision control systems such as Arch, Mercurial, Monotone, and BitKeeper to identify revisions and detect data corruption or tampering. And, yes, even when you’re at home enjoying some guilty pleasure of killing a complete stranger over the Internet through your Nintendo or trying to stay fit using your Wii, the SHA-1 hash is being used for signature verification during your boot process. [SHA-1 was broken in 2005](https://www.schneier.com/blog/archives/2005/02/sha1_broken.html).

#### SHA-2

In August 2001, NIST published FIPS PUB 180-2, introducing SHA-2 to the general populace. SHA-2 includes a significant number of changes from its predecessor, SHA-1. SHA-2 is a family of four similar hash functions with differing digest lengths, known as SHA-224, SHA-384, SHA-256, and SHA-512. These algorithms are collectively known as SHA-2. The same vulnerabilities found in SHA-1 in 2005, these same attacks have not been extended to SHA-2 or its variants. Like its predecessor, the SHA-2 hash function has been implemented in TLS and SSL, PGP, SSH, S/MIME, and IPsec.  Currently, SHA-256 is used for authentication on certain Linux packages; SHA-512 is also a part of an authentication system for archival video from the International Criminal Tribunal of the Rwandan genocide. UNIX and Linux vendors are pushing for use of the SHA-256 and SHA-512 for secure password hashing.

The newest version of SHA is SHA-3. It was released in 2015.

The length of the hash digest doesn't depend on the input length. Whatever the input length, the hash length will be the same. This is a matter of time and the available processing power and resources. The following table contains some of the famous hash functions with their digest length:

<table><tbody><tr><td><p class="table">ALGORITHM</p></td><td><p class="tablec">MESSAGE SIZE, &nbsp;(BITS)</p></td><td><p class="tablec">BLOCK SIZE, &nbsp;(BITS)</p></td><td><p class="tablec">WORD SIZE, (BITS)</p></td><td><p class="tablec">MESSAGE DIGEST SIZE, (BITS)</p></td></tr><tr><td><p class="table">SHA-1</p></td><td><p class="tablec">&lt;2<sup>64</sup></p></td><td><p class="tablec">512</p></td><td><p class="tablec">32</p></td><td><p class="tablec">160</p></td></tr><tr><td><p class="table">SHA-224</p></td><td><p class="tablec">&lt;2<sup>64</sup></p></td><td><p class="tablec">512</p></td><td><p class="tablec">32</p></td><td><p class="tablec">224</p></td></tr><tr><td><p class="table">SHA-256</p></td><td><p class="tablec">&lt;2<sup>64</sup></p></td><td><p class="tablec">512</p></td><td><p class="tablec">32</p></td><td><p class="tablec">256</p></td></tr><tr><td><p class="table">SHA-384</p></td><td><p class="tablec">&lt;2<sup>128</sup></p></td><td><p class="tablec">1024</p></td><td><p class="tablec">64</p></td><td><p class="tablec">384</p></td></tr><tr><td><p class="table">SHA-512</p></td><td><p class="tablec">&lt;2<sup>128</sup></p></td><td><p class="tablec">1024</p></td><td><p class="tablec">64</p></td><td><p class="tablec">512</p></td></tr><tr><td><p class="table">SHA-512/224</p></td><td><p class="tablec">&lt;2<sup>128</sup></p></td><td><p class="tablec">1024</p></td><td><p class="tablec">64</p></td><td><p class="tablec">224</p></td></tr><tr><td><p class="table">SHA-512/256</p></td><td><p class="tablec">&lt;2<sup>128</sup></p></td><td><p class="tablec">1024</p></td><td><p class="tablec">64</p></td><td><p class="tablec">256</p></td></tr></tbody></table>

Hash functions and their digest length

## HMAC

When signing messages, you should use a dedicated Message Authentication Code (MAC), such as a Hash-based MAC (HMAC), which avoids vulnerabilities in a single pass of the hashing function. HMAC can be used with any approved cryptographic hash function in combination with a shared secret key. The cryptographic strength of a HMAC depends on the properties of the underlying hash function. Basically a SHA-1 based HMAC(HMAC-SHA-1-96) is running SHA-1 on the message twice. This automatically means that your hash is better but still is not authenticated. However, in HMAC the secret key is added to the message so that the HMAC then becomes an authenticatable digest. You know that the sender of your HMAC is the actual sender because the secret key that is passed is automatically verified as authentic when you compare the digest of the HMAC. This is structured independently so that regardless of the messages you’ve encountered, and the secret keys that are passed, you will not be able to determine information for the secrets that are yet to come. This provides the extra level of assurance, as mentioned above, that your message has not been altered.

## Password hashing

Password hashing is a special case and general purpose hashing algorithms are not suitable for it as they are too fast. In fact dictionary attacks are blazing fast these days, thanks to the massive parallelism that you can get from the GPU in your graphics card.Algorithms specifically designed for password hashing should be slow and adaptive. Some of the best algorithms for password hashing are Password-Based Key Derivation Function 2 (PBKDF2), [BCrypt](https://en.wikipedia.org/wiki/Bcrypt) and [SCrypt](https://en.wikipedia.org/wiki/Scrypt).

## PBKDF2

[PBKDF2](https://en.wikipedia.org/wiki/PBKDF2) is the second version of Password-Based Key Derivation Function, which is part of the Password-Based Cryptographic standard. A powerful quality of PBKDF2 is that it generates hashes of hashes, thousands of times over. Iterating over the hash multiple times strengthens the encryption, exponentially increasing the number of possible outcomes resulting from an initial value to the extent that the hardware required to generate or store all possible hashes becomes infeasible.  
The pbkdf2 method requires four components: the desired password, a salt value, the desired amount of iterations, and a specified length of the resulting hash.  
When PBKDF2 was standardized, the recommended iteration count was 1,000. However, we need more iteration to account for technology advancements and reductions in the cost of equipment.

The PBKDF2 algorithm is implemented in the Rfc2898DeriveBytes class in .NET Core and can be used to generate password hashes as below.

```csharp
private void button1_Click(object sender, EventArgs e)
{
    byte[] digest;
    string base64digest;

    MD5 md5 = new MD5CryptoServiceProvider();
    digest = md5.ComputeHash(Encoding.UTF8.GetBytes(textBox1.Text));
    base64digest = Convert.ToBase64String(digest, 0, digest.Length);
    textBox3.Text = base64digest;

    SHA256 sha256 = SHA256.Create();
    digest = sha256.ComputeHash(Encoding.UTF8.GetBytes(textBox1.Text));
    base64digest = Convert.ToBase64String(digest, 0, digest.Length); 
    textBox2.Text = base64digest;

}
```

A complete working sample using PBKDF2 for generating salted user passwords and validating the same is available at [this github repo.](https://github.com/PradeepLoganathan/Hashing)

## Rainbow tables

Rainbow tables are precomputed tables used to look up passwords using stolen hashes. They are special dictionary tables that use hash values instead of standard dictionary passwords to achieve the attack.  
There are rainbow tables that exist today that can discover almost every possible password up to fourteen characters. Rainbow tables significantly reduce the time it takes to find the hash of a password, at the cost of memory, but with terabyte hard drives and gigabytes of RAM, it’s a trade-off that is easily made.  
Dictionary attacks are the type of attack we are trying to accomplish with these tools. A dictionary attack uses a precomputed dictionary file such as a Rainbow table to try and guess the password. Tools such as OphCrack and Rainbowcrack use rainbow tables to crack password hashes.

## .NET Core hash creation

In .NET core the System.Security.Cryptography provides the primary functionality to create hashes. It has types which can be used to create both MD5 and SHA hashes. A small sample to create both an MD5 and a SHA256 hash is below

<script src="https://gist.github.com/PradeepLoganathan/0988ecae3a4a073ba4420fb15244fd4c.js.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/0988ecae3a4a073ba4420fb15244fd4c.js">View this gist on GitHub</a>

## Hash collision

Hash collision occurs when two different inputs create the same hash when applied to the same hash function.

## Hashing Vs Encryption

Most people confuse encryption with hashes. It is important to understand that hashes are digests not encryption. A digest is used by a hash to summarize a compiled stream of data. Hashes are also a one-way function. Encryption converts plaintext data into ciphertext then converts it back to plaintext when the correct keys are given. This is a two-way function unlike hashes, which cannot be reversed. This is an important distinction to make.

## Hashing and Blockchain

Hashing plays a key role in the Blockchain technical ecosystem. Each block within the blockchain is identified by a hash, generated using the SHA256 cryptographic hash algorithm on the header of the block.

Each block also references a previous block, known as the parent block, through the “previous block hash” field in the block header. In other words, each block contains the hash of its parent inside its own header. The sequence of hashes linking each block to its parent creates a chain going back all the way to the first block ever created, known as the genesis block.
