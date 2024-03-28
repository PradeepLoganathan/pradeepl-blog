---
title: "Streamlining TLS Certificate Management in Kubernetes with cert-manager"
lastmod: 2024-03-01T09:16:21+10:00
date: 2024-03-01T09:16:21+10:00
draft: true
Author: Pradeep Loganathan
tags: 
  - 
  - 
  - 
categories:
  - 
#slug: kubernetes/introduction-to-open-policy-agent-opa/
description: "meta description"
summary: "summary used in summary pages"
ShowToc: true
TocOpen: true
images:
  - 
cover:
    image: "images/cover.jpg"
    alt: ""
    caption: ""
    relative: true # To use relative path for cover image, used in hugo Page-bundles
 
---

In today's digital ecosystem, securing microservices and applications is not just a necessity but a mandate. As organizations increasingly adopt Kubernetes for orchestrating their containerized applications, the dynamic nature of deploying and scaling microservices introduces complexities in managing TLS certificates. TLS certificates are pivotal in securing data in transit, providing encryption and ensuring the integrity and authenticity of communication between services. Secure communication between microservices and external clients is a fundamental aspect of Kubernetes security. This is where cert-manager shines as an indispensable tool in the Kubernetes landscape. Cert-manager, a Kubernetes operator, offers a powerful way to automate the lifecycle of TLS certificates within your cluster.

# Introduction

cert-manager is an open-source Kubernetes add-on designed specifically to automate the management, issuance, and renewal of TLS certificates. It bridges the gap between Kubernetes' dynamic environment and the need for secure, trustworthy communication channels. By interfacing with various certificate authorities (CAs) like Let's Encrypt, HashiCorp Vault, and Venafi, cert-manager streamlines the process of securing communications for microservices and other Kubernetes-hosted services.

# The Role of TLS certificates in Kubernetes Security

The adoption of microservices and cloud-native technologies has underscored the importance of robust security practices. TLS certificates play a crucial role in this landscape by encrypting data in transit between services. However, the ephemeral nature of containers and the dynamic orchestration of services by Kubernetes necessitate a more automated approach to certificate management. cert-manager not only meets this need but also simplifies the process, allowing teams to focus on development and deployment rather than the intricacies of TLS certificate management.

By ensuring that every service within a Kubernetes cluster can automatically obtain and renew its TLS certificates, cert-manager provides a solid foundation for secure communications. This capability is crucial not only for securing service-to-service communication within the cluster but also for securing communications between the services and their external clients.

## Challenges in a Microservices World

Microservices architectures thrive on the principles of agility, scalability, and autonomy. However, these benefits come with the complexity of managing secure communications across potentially hundreds of services. cert-manager plays a pivotal role in addressing these security challenges by providing a declarative approach to certificate management. This ensures that as services are deployed and scaled within Kubernetes, their communication channels remain secure without manual intervention. Cert-manager proves to be essential under these circumstances as it helps resolve the challenges of

- _Certificate Proliferation_: As the number of microservices increases, so does the number of TLS certificates required to secure them. Each service might need its own certificate, leading to a management burden.
- _Shortened Lifespans_: To enhance security, TLS certificates in microservice environments are often issued with shorter lifetimes. This increases the frequency of certificate renewal.
- _Operational Overhead_: Manually obtaining, installing, and renewing numerous certificates, especially those with short lifespans, significantly increases operational overhead and the potential for human error.

## Securing North-South and East-West Traffic

- North-South Traffic: This refers to communication between services within your Kubernetes cluster and the external world (clients, browsers, other systems). TLS is critical for securing this data in transit, protecting against eavesdropping and tampering.
- East-West Traffic: This encompasses communication between microservices themselves within the cluster. While often overlooked, securing east-west traffic with TLS is crucial for establishing a Zero Trust approach. It prevents attacks that exploit compromised services and limits data exposure should an attacker gain access to your cluster.

## How cert-manager Can Help

Cert-manager simplifies TLS certificate management and integrates directly into the Kubernetes ecosystem, easing the challenges associated with microservices. 

- Automated Certificate Lifecycle Management: cert-manager automates the provisioning, renewal, and management of TLS certificates, ensuring that certificates are always up-to-date without manual intervention.
- Enhanced Security for Microservices: In a microservices architecture, securing each service is crucial. cert-manager facilitates this by enabling automated, secure TLS certificate issuance for each service, regardless of its scale or complexity.
- Flexibility and Compatibility: It supports a variety of issuers, including ACME (Automated Certificate Management Environment) for Let's Encrypt, allowing users to choose the best solution for their security requirements.
- Ease of Use and Integration: As a Kubernetes-native solution, cert-manager is designed to fit seamlessly into the Kubernetes ecosystem, utilizing Custom Resource Definitions (CRDs) to extend Kubernetes functionalities in a familiar way.

# Digital Certificates & Certificate Authorities (CAs) - A quick primer

Digital certificates are electronic documents that use public key cryptography to establish the ownership of a public key. They contain information about the key, the identity of its owner, and the digital signature of an entity that has verified the certificate's contents, known as the issuer. Certificates are a fundamental component of TLS/SSL protocols, providing the means to secure communications over the internet.

Certificate Authorities (CAs) are trusted organizations that issue digital certificates. They act like a digital notary, verifying the identity of a website or service and binding that identity to a cryptographic key pair. Popular public CAs, like Let's Encrypt, DigiCert, and others, issue certificates for websites and services accessible over the public internet. They verify the information provided by the entity requesting the certificate (such as a website owner) and then sign the certificate with their private key. This process establishes a chain of trust: if you trust the CA, and the CA trusts the entity, then you can trust the entity's certificate.Organizations with strict security requirements or private networks often operate their own internal CAs. These CAs issue certificates exclusively to services and systems within their controlled environment.

# Installing Cert Manager

## Prerequisites

Before diving into the setup, ensure you have the following prerequisites covered:

- A Kubernetes cluster
- Azure CLI installed
- kubectl installed
- Access to an Azure account with permissions to manage DNS zones

## Helm based installation

Ensure you have Helm installed on your system. You can find Helm [installation instructions here](https://helm.sh/docs/intro/install/).  Check the cert-manager documentation for the minimum supported Kubernetes version, as this may change over time. The installation steps are 

1. Add the Jetstack Helm Repository: Use the command `helm repo add jetstack https://charts.jetstack.io` to add the Jetstack repository, the official source for cert-manager's Helm chart.

2. Update the Helm Chart Repository:  Use the command `helm repo update` to ensure you have the latest cert-manager chart information.

3. Install cert-manager: Use the command `helm install cert-manager jetstack/cert-manager \
     --namespace cert-manager \
     --create-namespace \
     --version vX.Y.Z  # Replace vX.Y.Z with the desired cert-manager version` to install cert-manager using the Helm chart into a dedicated namespace called 'cert-manager'. The `--create-namespace` tells Helm to create the namespace if it doesn't exist.

4. To verify you check the pods are running fine by executing `kubectl get pods --namespace cert-manager`.

## Kubectl based installation

1. Install it in your Kubernetes cluster by applying the YAML files provided in the cert-manager documentation using the command `kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml`

2. Check if cert-manager is running fine in your cluster using the command `kubectl get pods --namespace cert-manager`. Ensure the cert-manager, cert-manager-cainjector, and cert-manager-webhook pods are in a Running state.

Now that we have installed cert-manager, let us understand external and internal issuers.

# Internal and External Issuers in cert-manager

## External Issuers

External Issuers in cert-manager configure how to interact with public Certificate Authorities (CAs) like Let's Encrypt, ZeroSSL, DigiCert, etc. They are used to obtain TLS certificates for services and websites that will be accessible over the public internet. These public CAs verify your identity (often via DNS-01 or HTTP-01 challenges), then issue certificates that are trusted by web browsers. External issuers, also called as ClusterIssuers, operate at the cluster level and are often used to interact with certificate authorities that support the Automated Certificate Management Environment (ACME) protocol. The ACME (Automatic Certificate Management Environment) protocol standardizes interactions between CAs and servers. Cert-manager leverages ACME to obtain certificates from providers like Let's Encrypt. To verify domain ownership, ACME supports different types of challenges, with DNS-01 and HTTP-01 being the most common.

- DNS-01 Challenge: This involves creating a specific DNS record to prove control over a domain. It's particularly useful for issuing wildcard certificates that cover all subdomains of a given domain.
- HTTP-01 Challenge: This requires placing a special file in a well-known location on your web server. It's straightforward but cannot be used for issuing wildcard certificates.