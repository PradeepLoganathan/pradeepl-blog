---
title: "Public Key Cryptography"
date: "2017-07-06"
categories: 
  - "blockchain"
  - "cryptography"
---

The concept of public-key cryptography was invented by Whitfield Diffie and Martin Hellman, and independently by Ralph Merkle.Their contribution to cryptography was the notion that keys could come in pairs—an encryption key and a decryption key—and that it could be infeasible to generate one key from the other. Diffie and Hellman first presented this concept at the 1976 National Computer Conference ; a few months later, their seminal paper “[New Directions in Cryptography](https://www-ee.stanford.edu/~hellman/publications/24.pdf)” was published.

Public key cryptography is asymmetric, meaning that encryption and decryption use different keys. Public key cryptography was developed as a response to an important weakness of symmetric encryption - key distribution. When two people use symmetric encryption, they must ensure beforehand that they both share the same symmetric key and must interchange the keys through a secure channel before using the symmetric encryption system.

Unlike symmetric encryption, where any arbitrary series of bytes of appropriate length can serve as a key, asymmetric cryptography requires specially crafted key pairs. Cypher text created with one of these keys can only be decrypted with the other key and vice versa. In this key pair, the keys are sufficiently different that knowing one does not allow derivation or computation of the other .When utilizing asymmetric cryptography in real life, these keys are typically called the public key and private key in order to highlight their role. With public key cryptography, one of the keys in the key pair is published and available to anyone who wants to use it (the public key). The other key in the key pair is the private key, which is known only to the entity that owns the public-private key pair.

The private key needs to be protected and no unauthorized access should be granted to that key; otherwise, the whole scheme of public key cryptography will be jeopardized as this is the key that is used to decrypt messages.  
A public key is available publicly and published by the private key owner. Anyone who would then like to send the publisher of the public key an encrypted message can do so by encrypting the message using the published public key and sending it to the holder of the private key. No one else would be able to decrypt the message because the corresponding private key is held securely by the intended recipient. Once the public key encrypted message is received, the recipient can decrypt the message using the private key.

An example of when a public-private key pair is used is visiting a secure website. In the background, the public-private key pair of the server is being used for the security of the session. Your PC has access to the public key, and the server is the only one that knows its private key.

There are two classical use cases of public and private keys.

1. Asymmetric encryption solves the problem of having to share without secure communication by enabling communicating parties to share their public keys and, using complex math, encrypt data such that an eavesdropper cannot decipher the message. Therefore, everyone can publicly share their public key so that others can communicate with them. Best practice behaviour says you only encrypt data using the receiving party’s public key, and you do not encrypt messages with your private key.
2. Asymmetric encryption also enabled the concept of digital signatures. If, instead of using a private key for encryption it is instead used for message authentication, one can sign a message. To sign a message one first hashes (hashes are described [here](http://pradeeploganathan.com/2017/07/01/hashing/)) a message and then encrypts the hash. This encrypted hash is transmitted with the message. A receiver can verify the hash by decrypting it using the signer’s public key and then compare the decrypted value to a computed hash of the message. If the values are equal, then the message is valid and came from the signer (assuming that the private key wasn’t stolen of course).

Public key algorithms are slower in computation as compared to symmetric key algorithms. Therefore, they are not commonly used in the encryption of large files or the actual data that needs encryption. They are usually used to exchange keys for symmetric algorithms and once the keys are established securely, symmetric key algorithms can be used to encrypt the data.

There are three main families of asymmetric algorithms

- Integer factorization - These schemes are based on the fact that large integers are very hard to factor. RSA is the prime example of this type of algorithm and is named for the three people who first publicized it: Ron Rivest, Adi Shamir, and Leonard Adleman.
- Discrete logarithm - This is based on a problem in modular arithmetic that it is easy to calculate the result of modulo function but it is computationally infeasible to find the exponent of the generator. In other words, it is extremely difficult to find the input from the result. This is a one-way function.
- Elliptic curves - This is based on the discrete logarithm problem discussed earlier, but in the context of elliptic curves.Mostly prominently used cryptosystems based on elliptic curves are Elliptic Curve Digital Signatures Algorithm (ECDSA) and Elliptic Curve Diffie-Hellman (ECDH) key exchange.

For example, consider the following equation:

> 32 mod 10 = 9

Now given 9 finding 2, the exponent of the generator 3 is very hard. This hard problem is commonly used in Diffie-Hellman key exchange and digital signature algorithms.

## DIGITAL SIGNATURES

Digital signatures are a key application of public key cryptography.The goal of digital signatures is similar to that of handwritten signatures - they ensure that a message was generated by the signer, has not been tampered with and the signature is non-repudiable.Bitcoin addresses are basically public keys

A digital signature protocol is the combination of a public-key algorithm with a digital signature scheme. The public-key algorithm provides the underlying asymmetric mathematical algorithm. The digital signature scheme proposes a way to use this asymmetric algorithm to arrive at a workable digital signature.

The RSA signature scheme based on the RSA algorithm is the most widely used digital signature scheme.

## Asymmetric Cryptography in Blockchain

The blockchain uses asymmetric cryptography in order to achieve two goals:

- Identifying accounts
    
- Authorizing transactions
    

Picture courtesy - [Bogdan Dada](https://unsplash.com/@bogs)
