---
title: "How to Generate SSL Wildcard Certificates with ACME Challenges, Let's Encrypt, and Certbot"
lastmod: 2024-07-07T15:47:06+10:00
date: 2024-07-07T15:47:06+10:00
draft: false
author: Pradeep Loganathan
tags: 
  - SSL
  - Let's Encrypt
  - Certbot
  - ACME
categories:
  - Security
  - DevOps
  - Cloud
  - featured
description: "A comprehensive guide on generating SSL wildcard certificates using ACME challenges, Let's Encrypt, and Certbot."
summary: "This blog post guides you through the process of generating SSL wildcard certificates using ACME challenges and Certbot, helping secure your domains with Let's Encrypt."
ShowToc: true
TocOpen: true
images:
  - "images/certbot-letsecnrypt.jpeg"
cover:
    image: "images/certbot-letsecnrypt.jpeg"
    alt: "SSL Wildcard Certificates"
    caption: "Learn how to generate SSL wildcard certificates"
    relative: true # To use relative path for cover image, used in hugo Page-bundles
---

Securing your website with [HTTPS]({{< ref "/blog/https">}}) is essential for protecting user data and ensuring privacy. In this blog post, I'll guide you through the process of generating SSL wildcard certificates using ACME challenges and Certbot, which I recently used to successfully secure my domains. This step-by-step guide will help you easily set up your own certificates.

## What is Let's Encrypt and How Does It Work?

**Let's Encrypt** is a free, automated, and open Certificate Authority (CA) that provides SSL/TLS certificates to enable HTTPS on websites. It is operated by the Internet Security Research Group (ISRG). Let's Encrypt's mission is to create a more secure and privacy-respecting web by making it easier for everyone to use HTTPS.

### Key Roles of Let's Encrypt

1. **Certificate Authority (CA)**: Let's Encrypt acts as a trusted Certificate Authority(CA) that issues digital certificates to verify the ownership of public keys. These certificates contain information about the domain name, organization, and public key. As a CA, Let's Encrypt is trusted by browsers and operating systems to issue digital certificates that verify the ownership of public keys by the named subject of the certificate.
2. **Domain Validation**: Before issuing a certificate, Let's Encrypt verifies domain ownership through automated challenges. Let's Encrypt uses automated processes to verify domain ownership through challenges before issuing a certificate. These automated processes use the ACME challenge protocol to validate domain ownership.
3. **Automated Certificate Issuance**: Let's Encrypt provides a fully automated process to obtain, renew, and manage certificates through the ACME protocol. Let's Encrypt uses the Automated Certificate Management Environment (ACME) protocol to automate the certificate issuance process. ACME is a standardized protocol that enables automated certificate issuance, renewal, and management.
Let's Encrypt's ACME implementation enables users to obtain, renew, and manage certificates without manual intervention.
4. **Root and Intermediate Certificates**: Let's Encrypt operates its own root certificate (`ISRG Root X1`) and uses intermediate certificates (e.g., `R3`) to issue end-entity certificates. These intermediates are signed by the root certificate trusted by browsers. End-entity certificates are issued to domain owners and contain information about the domain name, organization, and public key.

### Why use Let's Encrypt ?

Let's Encrypt offers a range of features, including:

1. **Free certificates:** Let's Encrypt provides free SSL/TLS certificates, making it accessible to everyone.
2. **Automated renewal:** Certificates can be renewed automatically before expiration, ensuring uninterrupted HTTPS.
3. **Multiple domain support:** Let's Encrypt supports issuing certificates for multiple domains and subdomains.
4. **Wildcard certificates:** Let's Encrypt offers wildcard certificates, enabling HTTPS for all subdomains.

## What is an ACME Challenge?

An ACME challenge is a method used by the Automated Certificate Management Environment (ACME) protocol to prove domain ownership before issuing an SSL/TLS certificate. The ACME protocol is defined by the Internet Engineering Task Force (IETF) in RFC 8555 and is used by Let's Encrypt and other certificate authorities to automate the process of domain validation and certificate issuance.

### Types of ACME Challenges

1. **HTTP-01 Challenge**: Places a specific file on your web server, which the CA accesses via HTTP.
2. **DNS-01 Challenge**: Creates a DNS TXT record with a specific value for your domain.
3. **TLS-ALPN-01 Challenge**: Serves a specific certificate during a TLS handshake on port 443 using the ALPN extension.

## What is Certbot and How Does It Help?

**Certbot** is the official client software for Let's Encrypt. It simplifies the process of obtaining, installing, and renewing certificates through the ACME protocol. It automates many of the tasks involved in certificate management, making it accessible to users who may not be familiar with the technical details.

### Key Features of Certbot

* **Automated Domain Validation**: Certbot can handle various ACME challenges, including HTTP-01, DNS-01, and TLS-ALPN-01.
* **Web Server Integration**: It can automatically configure your web server (e.g., Apache or Nginx) to use the newly issued certificate.
* **Certificate Renewal**: Certbot can be scheduled to automatically renew your certificates before they expire, ensuring uninterrupted HTTPS protection for your website.
* **Multiple Plugins**:  Certbot supports plugins for different web servers, DNS providers, and other functionalities.

## What is Azure DNS and Why Use It?

Azure DNS is Microsoft's cloud-based Domain Name System (DNS) service. It offers a highly available and scalable solution for managing domain names.

Reasons to use Azure DNS for wildcard certificates:

* **Reliability and Scalability:** Ensures high availability and performance for your DNS records.
* **Integration with Azure Services:** Seamlessly integrates with other Azure services.
* **DNS Challenge Support:** Allows you to create TXT records needed for the DNS-01 challenge.

I am using Azure DNS for this but you can use and other DNS such as AWS Route53, Google Cloud DNS, Cloudflare DNS and others. The process is very similar since all these DNS providers allow you to add txt records for the DNS you own.

The complete process of using certbot, letsencrypt and azure dns to generate the wildcard ssl certificate is below. There are many ways of doing it and i am using the simple DNS challenge of updating txt records to validate domain ownership.

{{< figure src="images/generate-wildcard-ssl-certbot-letsencrypt.png" alt="ACME DNS challenge with Certbot and Azure DNS" caption="ACME DNS challenge flow using Certbot and Azure DNS" >}}

## Step-by-Step Guide to Getting Wildcard SSL Certificates

### Prerequisites

* **Domain Name:** You need a registered domain name that you control.
* **Azure DNS Zone:** I am using a domain hosted in an Azure DNS zone but you can use any domain hosted in a DNS provider of your choice.
* **Certbot Installed:** Install Certbot following the instructions for your operating system. For ubuntu i am using the below steps to install certbot

```bash
sudo apt update
sudo apt install certbot
````

### Steps

1. **Initiate Certificate Request:** Run the Certbot certonly command to initiate the process of starting the ACME challenge to verify domain ownership.

```bash
sudo certbot certonly --manual --preferred-challenges=dns --email <<email@youremail.com>>
```

Certbot will ask you for the domain names that which need to be validated to issue certificates. For each domain specified, Certbot will give you a TXT record to create in your Azure DNS zone.

{{< figure src="images/intiate-request.png" alt="Initiating Certbot DNS challenge" caption="Initiating Certbot DNS challenge" >}}

2. **Create TXT Record in Azure DNS:** Go to your Azure Portal, navigate to your DNS zone, and add a new TXT record using the details from Certbot.

3. **Verify the Challenge:** After the DNS record propagates, return to Certbot and confirm. Certbot will check your DNS for the TXT record.

{{< figure src="images/verify-challenge.png" alt="Verifying ACME DNS challenge in Certbot" caption="Verifying ACME DNS challenge in Certbot" >}}

4. **Certificate Installation:** Now that we have successfully generated the certificate files, you Configure your web server to use these certificates.

## Conclusion

Let's Encrypt plays a crucial role in making the web more secure by providing free and automated SSL/TLS certificates. By following these steps, you can easily obtain and install SSL wildcard certificates for your domains using Certbot and ACME challenges. This ensures secure and encrypted communications for all your subdomains, enhancing the security and privacy of your website.

For a foundational understanding of HTTPS and its importance, you can also read my [blog post on HTTPS]({{< ref "/blog/https">}})

If you have any questions or run into issues, feel free to leave a comment below.
