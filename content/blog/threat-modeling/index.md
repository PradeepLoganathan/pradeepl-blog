---
title: "Threat Modeling"
date: "2017-08-21"
categories: 
  - "Security"
tags:
  - "Threat Modeling"
  - "DevSecOps"
  - "Cloud-Native"
  - "Supply Chain Security"
  - "Zero-Trust"
ShowToc: true
TocOpen: true
images:
  - images/Stride-classification.png
  - images/Dread-classification.png
math: katex 
---

In a world increasingly reliant on digital infrastructure, security is no longer a static state but a continuous process. Reactive security is a gamble no organization can afford. Proactive defense is paramount, and threat modeling stands as a crucial first line of defense. Threat modeling provides a structured approach to proactively identify and mitigate security risks. It's about stepping into the mindset of an attacker, systematically examining your systems—whether a complex application, a sprawling network, or a cloud deployment—to pinpoint potential weaknesses. Threat modeling uncovers potential vulnerabilities, maps likely attack paths, and empowers teams to fortify their defenses preemptively. This process involves visualizing attack vectors, assessing potential impact, and prioritizing mitigation efforts. More than a mere checklist, it's a dynamic process that blends analytical rigor with creative foresight, enabling you to anticipate and mitigate threats before they materialize.

Threat modeling is an effective tool used to understand the threat landscape within an enterprise network. Threat modeling is a security practice for the team to identify threats, attacks, and risks based on the existing architecture design, and to mitigate these potential security risks. It is the process of looking at all the significant and likely potential threats to a scoped scenario, ranking their potential damage in a given time period, and figuring cost‐effective mitigations to defeat the highest‐priority threats. The threat modeling exercise enables organizations to get a better understanding of the threats targeting them. It enables them to be better prepared to prioritize strategies for reducing their attack surface. Threat modeling is very commonly used as a part of the software development life cycle. It enables all participants in the software development process to efficiently create and deliver secure software with a greater degree of confidence that all security flaws are understood and accounted for.

## Why Threat Modeling Matters
Consider the complexity of modern enterprise architectures: interconnected APIs, microservices spanning multiple clouds, countless endpoints, and an ever-growing list of libraries and frameworks. Add to this the speed at which organizations are deploying features—continuous integration and continuous delivery (CI/CD) pipelines, DevOps mindsets, and agile sprints. In this environment, understanding where and how attackers could leverage vulnerabilities is no small feat.

Threat modeling is not about security as an afterthought. It’s about injecting security awareness right at the design stage, where the cost of fixing issues is lower and the impact on your architecture is more controlled. By systematically identifying threats and attacks early, you effectively “shift left” on the security timeline, reducing the risk of costly breaches down the road.

This process empowers developers, architects, and security professionals to communicate more effectively, prioritize what matters, and approach product development with confidence rather than fear. Instead of reacting to an exploit in the wild, your team is prepared with mitigation strategies well before malicious actors even take notice.

## Frameworks: Guiding Your Threat Modeling Journey
The threat modeling discipline is supported by a number of established frameworks that help break down and categorize potential risks. Among them are:

- STRIDE
- PASTA
- VAST
- TRIKE
- OCTAVE

All share a common goal: guide the team toward understanding residual risk and deciding how much of it the organization can tolerate. Each framework has its unique flavor—some focus on specific industries, others on particular methodologies or compliance standards. The key is to select one that resonates with your team’s context, complexity, and organizational culture.

## Threats: More Than Just Hackers With Hoodies
The term “threat” often conjures images of a shadowy hacker hunched over a keyboard, but the reality is much broader. A threat can be any intentional or accidental action that adversely impacts your people, processes, or technology. Think of everything from cybercriminals and malicious insiders to technical failures, natural disasters, and supply chain vulnerabilities.

Common Threat Types Include:

- Physical Damage: Fire, flood, or environmental hazards that disrupt physical infrastructure.
- Service Impact: Power outages, telecommunication failures, and sudden service downtimes.
- Information Compromise: Eavesdropping, data theft, media tampering, or unintentional exposure of sensitive data.
- Technical Failures: Software defects, configuration mishaps, performance degradations.
- Operational Compromise: Abuse of access rights, denial-of-service attacks, or insider threats.
 
Realizing that threats extend beyond the “cyber” realm allows organizations to build resilience into their designs. The better you understand your adversaries—be they humans, acts of nature, or system malfunctions—the better you can secure your environment against them.

### STRIDE

Microsoft’s STRIDE model remains a cornerstone in threat modeling, offering a memorable mnemonic and structured approach.  This approach to threat modeling was defined by [Loren Kohnfelder](https://medium.com/@lorenkohnfelder) and Praerit Garg. They published this as part of an initiative taken by Microsoft in 1999 to harden its products against security vulnerabilities. This document can be found [here](https://adam.shostack.org/microsoft/The-Threats-To-Our-Products.docx). The STRIDE threat model defines threats in six categories. This framework and mnemonic were designed to help identify the types of attacks that software tends to experience. STRIDE helps architects and engineers think about:

- **S**poofing - Spoofing is the unauthorized use of identity markers, such as a username and password, to gain access to assets. Threats in the spoofing category also include an adversary creating and exploiting confusion about the identity of someone or something. Other examples of spoofing identity are forging an email address or the modification of header information in a request with the purpose of gaining unauthorized access to a software system.
- **T**ampering - Tampering involves an adversary making modifications to data in storage or in transit. Examples of tampering with data include modifying persisted data in a database, changing data as it travels over a network, and modifying data in files.
- **R**epudiation - Repudiation is the explicit denial of performing actions where proof cannot be otherwise obtained. It involves an adversary performing a certain action and then later denying having performed the action. Examples are executing unauthorized actions against asset. Nonrepudiation is the mitigating control where a record of actions is maintained. Strong authentication, accurate and thorough logging, and the use of digital certificates can be used to counter repudiation threats.
- **I**nformation disclosure - Information disclosure threats involve an adversary gaining unauthorized access to confidential information. The information obtained by the attacker could potentially be used for other types of attack. For example, an attacker can obtain system information (server OS version, application framework version etc.) to further craft a highly specialized attack vector.
- **D**enial of service (DOS) - A denial of service threat involves denying legitimate users' access to systems or components. An attacker can flood servers with packets to the point that the servers become unavailable or unusable. They can then be overloaded to a point such that they cannot fulfill legitimate requests.
- **E**levation of privilege - An elevation of privilege threat involves a user or a component being able to access data or programs for which they are not authorized. An attacker can gain elevated authorization for operations beyond what was originally granted. For example, an attacker can execute kernel-mode commands or run processes with additional permissions by elevating privileges.

!["STRIDE classification"](images/Stride-classification.png)

Rather than viewing threats as random incidents, STRIDE urges teams to consider each category and ask, “What if?” This structured thinking ensures that no common class of attack is overlooked. Pair STRIDE with established threat libraries like CAPEC, ATT&CK, or CWE for added clarity and actionable insights.

### From Identification to Prioritization: The DREAD Methodology

Spotting a vulnerability is only half the battle. Once you’ve listed out potential threats, how do you decide which ones deserve immediate attention? This is where the DREAD risk assessment methodology comes in. DREAD stands for:

- **D**amage Potential - Damage potential measures how much injury can result from a risk.
- **R**eproducibility - Reproducibility can be measured by how likely it is to happen and how frequently it will occur.
- **E**xploitability - Exploitability focuses on the skills and hacker tooling that are needed to exploit the risk. It is an assessment of the effort, monetary investment, and expertise required to launch the exploit.
- **A**ffected users - The number of users that could be potentially affected by an attack.
- **D**iscoverability - The likelihood that a vulnerability can be taken advantage of. It is an assessment if the knowledge of the vulnerability requires inside knowledge of the system or can it be easily guessed.

The DREAD model for assessing risk works by assigning a number against each of the categories above. Then we can apply the formula

{{< math >}}
  \[
    \text{Risk value} = \frac{\text{Damage Potential} \times \text{Reproducibility} \times \text{Exploitability} \times \text{Affected Users} \times \text{Discoverability}}{5}
  \]
{{< /math >}}
using the numbers assigned to come up with a measure of the risk value. Threats can then be quantified, compared, and prioritized based on their risk value. Thus STRIDE and DREAD can be used in conjunction to produce an effective and actionable threat model.

!["DREAD Classification"](images/Dread-classification.png)

## Beyond the Enterprise: The Value of Sharing Threat Intelligence

Threat modeling, when combined with community sharing, provides an enterprise with holistic and near real-time view of the threat landscape. This allows for better mitigation strategies as well as faster time for the detection of security breach. This also strengthens the enterprise’s knowledge when performing threat forecasting.

There are a lot of commonalities in how threats are structured, how they work and their impact. There are various frameworks to categorize and classify threats so that they can be broadly shared with a bigger community. STIX and TAXII help to solve the problem of threat intelligence sharing by providing a platform that uses a common format to store and retrieve intelligence. They are protocols that were developed to allow for the communication of threat information so that secondary systems could anticipate a new attack vector. STIX is a structured language for cyber threat intelligence. It is a machine-readable format that allows organizations to share threat intelligence across various commercial and freeware threat intelligence aggregation platforms. Taxii is a transport mechanism for sharing cyber threat intelligence. TAXII is most commonly used as a transport mechanism for threat intelligence data including STIX as well as other similar projects. Infact, TAXII is the way that STIX is shared between entities or organizations.

## Putting It All Together: Threat Modeling as a Cultural Shift
Threat modeling is not just another box to check. It represents a mindset shift, transforming how teams think about risk, resilience, and security strategy:

- Early Integration: Incorporate threat modeling from the design phase, not as a post-development chore.
- Continuous Process: Treat threat modeling as a living practice. Applications evolve, threat landscapes change, and so must your models.
- Inclusive Collaboration: Involve stakeholders from architecture, development, operations, and security. Different perspectives highlight different vulnerabilities.
- Informed Prioritization: Leverage frameworks like STRIDE and DREAD to turn broad risk concepts into actionable plans.

In a world where attacks grow more sophisticated daily, organizations that invest in understanding their threats are the ones that thrive. Threat modeling doesn’t eliminate risk—but it gives you the blueprint for managing it intelligently, systematically, and confidently.
