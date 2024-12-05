---
title: "Flipping the Script: Elevating Security to the Core of Application Design"
author: Pradeep Loganathan
date: 2024-11-25T16:36:41+10:00
lastmod: 2024-11-25T16:36:41+10:00
draft: false
tags:
  - Security
  - Shifting Left
  - Application Security
  - AST
  - Software Development
categories:
  - Security
  - Development
description: "Challenging traditional priorities in software design by making security the cornerstone of the development lifecycle."
summary: "This blog examines how prioritizing security from the outset transforms design and development practices, using real-world lessons like the Equifax breach."
ShowToc: true
TocOpen: true
images:
  - images/speedandsafety.jpg
cover:
  image: "images/speedandsafety.jpg"
  alt: "Application Security Testing"
  caption: "Elevating AST in Software Development"
  relative: true
---

On the morning of July 29, 2017, a member of Equifax's internal IT security team finally addressed a long neglected task: renewing an expired SSL certificate for a network traffic monitoring system[^1][^2]. This long pending update lifted a critical blindfold from their monitoring tools. The team could now detect suspicious network activity that had been hidden for months due to the expired certificate. What they saw was alarming—a massive amount of unexplained outbound data transfers[^3]. By updating the certificate, the security team inadvertently uncovered one of the largest data breaches in history, exposing the personal information of 147.9 million people[^4].

Uncovering the suspicious data egress was just the beginning. The unusual traffic wasn't immediately linked to its root cause: a critical vulnerability known as **Apache Struts CVE-2017-5638**[^5][^6] lurking within a key application dependency. This vulnerability had been identified in the core code of Apache Struts, specifically in the Jakarta Multipart parser. The flaw allowed attackers to execute remote code via specially crafted HTTP headers. It is a classic example of a remote code execution (RCE) vulnerability caused by insufficient validation and sanitization. Publicly disclosed in March 2017, this flaw allowed attackers to execute malicious code on Equifax's servers, granting them unfettered access to sensitive data. Despite the availability of a patch, Equifax's development teams failed to prioritize it through multiple iterations[^7] and continued to use a version of Struts that had this vulnerability even after the patch was available. This oversight was a glaring failure in their development process—a neglect of essential security updates in favor of tasks deemed more immediate.

The reasons were multifaceted: inadequate vulnerability management processes, poor communication between security and development teams, and a lack of urgency in addressing known risks[^8]. Ironically, while Equifax's development team was intensely focused on pushing the boundaries of innovation and striving for market dominance, they neglected the very security measures that would safeguard their achievements. Failing to promptly patch the vulnerability wasn't merely an oversight—it revealed a systemic failure to integrate security into the development lifecycle as a foundational priority. In their relentless pursuit of advancement, they overlooked the foundational necessity of robust security, ultimately undoing their ambitious efforts.

To comprehend the full extent of the damage, Equifax enlisted cybersecurity firm Mandiant[^9]. Their investigation revealed a devastating truth: hackers had exploited the unpatched vulnerability for three to four months, siphoning off sensitive data—including names, Social Security numbers, birth dates, and addresses—without detection[^10][^11]. The fallout was swift and severe. Public outrage erupted as news of the breach spread, leading to lawsuits and regulatory investigations[^12]. Equifax faced immense pressure to compensate affected individuals and overhaul its security infrastructure. The company's reputation was irreparably tarnished, and its growth trajectory faltered[^13].This chain of events underscores how prioritizing security only after a breach occurs is a fundamentally flawed approach.

![alt text](images/equifax-stock-price.png)

The Equifax breach wasn't just a technological failure—it was a failure of priorities. When security is sidelined, even minor oversights can cascade into catastrophic breaches. This was a glaring indictment of how even industry giants can falter by not prioritizing security at the foundational level of development. It prompts me to ask: **Are we building our software on the right foundation? Are we focusing on the right pinnacle in our application design/architecture and development processes?**

In a world where cyber threats evolve faster than software features, it's time to flip the script. I boldly assert that security should be the driving force that shapes how we design, develop, and operate as an organization. Security should no longer be an afterthought—it must become the core principle guiding application design and development. By placing security at the apex of systems design, we can transform our approach to innovation, redefine our success metrics, and ultimately protect the ambitions we strive so hard to achieve.

---

## The Feature Frenzy: Is Security Being Left Behind?

The Equifax breach isn't an isolated case. Across industries, development teams face relentless pressure to prioritize features, user experience, and faster releases. Agile methodologies and continuous deployment pipelines promise innovation at breakneck speeds, but too often, these advancements come at a cost: sidelining security.

Why does this happen? The reasons are as varied as they are pervasive:

- **Lack of Visibility**: Development and security teams often lack the necessary visibility into the application's security posture, existing vulnerabilities, and the associated risks. Without this critical information, teams struggle to assess and prioritize remediation work effectively. This blind spot leads to delays in addressing issues and leaves applications exposed to threats.
- **Cultural Bias**: Many teams view security as a blocker to progress, something that slows down releases rather than enabling safer innovation.
- **Siloed Practices**: Security is frequently treated as a separate phase or a standalone team, disconnected from the development process. This disconnect leads to vulnerabilities slipping through unnoticed.
- **Misaligned Metrics**: Organizations measure success by features delivered, user adoption rates, or time-to-market. Rarely are security metrics part of the equation, leaving vulnerabilities invisible until it's too late.

This focus on features over safety is creating a growing risk for organizations. High-profile incidents like Equifax underscore the hidden costs of neglecting security:

- **Financial Losses**: Direct costs from breach mitigation, legal fees, and compensation to affected customers can be staggering.
- **Reputational Damage**: Loss of customer trust can lead to decreased sales and long-term brand erosion.
- **Regulatory Penalties**: Non-compliance with data protection regulations results in hefty fines and increased scrutiny from governing bodies.

These consequences highlight a critical flaw in the current development paradigm: by prioritizing feature development over security, organizations inadvertently jeopardize the very assets they aim to grow.

To overcome these challenges, it's time to rethink how we approach security. Shifting security left—embedding it into every phase of the software lifecycle—ensures that innovation and safety go hand in hand. This mindset doesn't just protect against breaches; it creates a culture where security is a catalyst for innovation, not an afterthought.

---

## Elevating Security to the Pinnacle: Designing for Resilience

What does success in software development look like? For many organizations, it’s measured in features delivered, deadlines met, and user adoption rates achieved. But this approach often neglects the single most important pillar of sustainable success: security.

### Why Security Should Lead Design

Security is not just another consideration; it is the foundation upon which innovation, scalability, and trust are built. A security-first approach ensures that:

- **Innovation Is Protected**: The most groundbreaking features mean little if they can be exploited or compromised.
- **Costs Are Minimized**: Breaches are far more expensive to address post-deployment than during design or development.
- **Compliance Is Simplified**: Building security into the foundation of your application reduces the complexity of meeting regulatory requirements later.

By placing security at the center of design, organizations can prevent vulnerabilities from becoming embedded in their systems, where they are exponentially harder—and more expensive—to fix.

### From Reactive to Proactive

Today, many organizations approach security reactively. Vulnerabilities are identified late in the software lifecycle, during testing or post-deployment, when remediation is costly and disruptive. This approach not only increases risk but also creates tension between development and security teams.

A proactive, security-first approach flips this dynamic. It embeds security into every phase of the development lifecycle:

1. **Threat Modeling**: Identifying risks during the design phase ensures that systems are built to mitigate potential attacks.
2. **Secure Coding Practices**: Training developers and enforcing coding standards reduces the likelihood of vulnerabilities entering the codebase.
3. **Automated Validation**: Integrating automated security checks into CI/CD pipelines ensures continuous monitoring and testing throughout development.

When security becomes a guiding principle, the development process becomes not just faster, but also more resilient.

### How AST Supports Security-First Development

To operationalize this vision, organizations need tools and processes that make security practical and scalable. This is where **Application Security Testing (AST)** comes in. AST enables teams to:

- **Detect Vulnerabilities Early**: Tools like Static Application Security Testing (SAST) allow developers to identify and address issues during the coding phase, long before deployment.
- **Assess Real-World Risks**: Dynamic Application Security Testing (DAST) simulates attacks on running applications to uncover vulnerabilities that might otherwise go unnoticed.
- **Embed Security in Workflows**: By integrating into CI/CD pipelines, AST tools ensure that security checks happen automatically and continuously, fostering collaboration between development and security teams.

AST doesn't replace a security-first mindset—it amplifies it. By providing visibility, automation, and actionable insights, AST ensures that security becomes a seamless part of development rather than a roadblock.

### Reimagining Success

Success in software development must be redefined. It is no longer about how fast we can deliver or how many features we can pack into a release. True success lies in delivering applications that are secure, resilient, and trusted by users. A security-first design philosophy, supported by tools like AST, creates a new paradigm where innovation and safety go hand in hand.


**Integrating AST into the development process ensures a continuous focus on security.** It embeds security considerations into every aspect of development, fostering a culture where security and innovation coexist harmoniously.

By making AST a central component, organizations can transform their methodologies and outcomes:

- **Security-First Design Philosophy**: Systems should be designed with security constraints as foundational elements. Functionality and user experience are built upon this secure base, ensuring that innovation does not come at the expense of safety.
- **AST-Centric Methodologies**: Incorporating AST into Agile and DevOps practices reshapes them into DevSecOps models. Security checks become continuous, automated, and integral rather than periodic or manual. This integration ensures that security is not a gatekeeper but a constant companion throughout development.

---

## AST at the Core: Transformation or Turmoil?

Embracing AST as a central component raises important questions. Will this shift lead to a positive transformation in our development practices, or could it introduce new complexities and disruptions? Let's explore the potential impacts.

Integrating AST fundamentally changes how teams operate. It requires restructuring processes, retraining staff, and potentially slowing down development cycles to accommodate thorough security testing. Some may fear that this focus on security could stifle innovation or delay product releases.

However, the alternative—continuing to sideline security—poses far greater risks. The potential for devastating breaches, loss of customer trust, and regulatory penalties outweighs the challenges of integrating AST. The key lies in finding a balance that allows for both robust security and ongoing innovation.

---

## Weighing the Outcomes: Do the Benefits Justify the Shift?

Placing AST at the core of your development process does more than bolster your defenses—it creates a ripple effect of positive change throughout your organization. First, you achieve an unparalleled security posture, minimizing vulnerabilities and drastically reducing the risk of breaches. This not only protects your assets but also establishes a solid foundation upon which you can confidently and rapidly build new features, fostering innovation without compromising security.

This enhanced security translates into a powerful competitive advantage. In a world where consumers are increasingly concerned about data privacy, your commitment to security becomes a key differentiator. Building trust with your customers fosters loyalty and strengthens your brand. Furthermore, you gain access to security-sensitive markets, like finance and healthcare, where stringent regulations often act as barriers to entry.

While embracing AST requires an initial investment, it ultimately leads to long-term efficiency and cost savings. By preventing costly security incidents, you protect your financial resources and avoid the disruption and reputational damage that breaches cause. Moreover, integrating AST streamlines development workflows, eliminates redundant tasks, and fosters a proactive approach to security, optimizing your entire software development lifecycle.

---

## Conclusion

Embracing security as the core of our design and development processes is not just a bold proposition; it's a strategic imperative. Tools like Application Security Testing enable us to operationalize this vision, ensuring that security is woven into the fabric of our development efforts. As we've seen with Equifax, neglecting security can have devastating consequences. By prioritizing security and leveraging tools such as AST, we not only protect our organizations but also pave the way for sustainable innovation.

This post serves as an introduction to the critical role of AST in modern software development. In upcoming posts, we'll delve deeper into practical strategies for integrating AST, overcoming common challenges, and exploring how organizations can successfully make this transformative shift.

---

**Stay tuned as we explore how to flip the script and make security the driving force behind innovation. Together, we can build a safer digital world—one application at a time.**


## References

[^1]: Perez, E. (2017, September 14). **Equifax breach caused by lone employee's error, former CEO says**. CNN Money. Retrieved from [https://money.cnn.com/2017/10/03/technology/equifax-ceo-congress/index.html](https://money.cnn.com/2017/10/03/technology/equifax-ceo-congress/index.html)

[^2]: United States Government Publishing Office. (2018). **The Equifax Data Breach**. Hearing before the Subcommittee on Digital Commerce and Consumer Protection of the Committee on Energy and Commerce House of Representatives. Retrieved from [https://www.govinfo.gov/content/pkg/CHRG-115hhrg26918/html/CHRG-115hhrg26918.htm](https://www.govinfo.gov/content/pkg/CHRG-115hhrg26918/html/CHRG-115hhrg26918.htm)

[^3]: Reuters Staff. (2017, September 14). **Equifax failed to patch security flaw before data breach: former CEO**. Reuters. Retrieved from [https://www.reuters.com/article/us-equifax-cyber-ceo/equifax-failed-to-patch-security-flaw-before-data-breach-former-ceo-idUSKCN1C81I7](https://www.reuters.com/article/us-equifax-cyber-ceo/equifax-failed-to-patch-security-flaw-before-data-breach-former-ceo-idUSKCN1C81I7)

[^4]: Federal Trade Commission. (2019, July 29). **Equifax to pay $575 million as part of settlement with FTC, CFPB, and states related to 2017 data breach**. Retrieved from [https://www.ftc.gov/news-events/press-releases/2019/07/equifax-pay-575-million-part-settlement-ftc-cfpb-states-related](https://www.ftc.gov/news-events/press-releases/2019/07/equifax-pay-575-million-part-settlement-ftc-cfpb-states-related)

[^5]: The Apache Software Foundation. (2017, March 10). **Apache Struts Statement on Equifax Security Breach**. Retrieved from [https://blogs.apache.org/foundation/entry/apache-struts-statement-on-equifax](https://blogs.apache.org/foundation/entry/apache-struts-statement-on-equifax)

[^6]: National Vulnerability Database. (2017). **CVE-2017-5638 Detail**. NIST. Retrieved from [https://nvd.nist.gov/vuln/detail/CVE-2017-5638](https://nvd.nist.gov/vuln/detail/CVE-2017-5638)

[^7]: U.S. House of Representatives Committee on Oversight and Government Reform. (2018). **The Equifax Data Breach**. Retrieved from [https://republicans-oversight.house.gov/wp-content/uploads/2018/12/Equifax-Report.pdf](https://republicans-oversight.house.gov/wp-content/uploads/2018/12/Equifax-Report.pdf)

[^8]: Smith, R. (2017). **Testimony of Richard F. Smith Former Chairman and CEO, Equifax Inc.** Before the U.S. House of Representatives Committee on Energy and Commerce Subcommittee on Digital Commerce and Consumer Protection. Retrieved from [https://docs.house.gov/meetings/IF/IF17/20171003/106433/HHRG-115-IF17-Wstate-SmithR-20171003.pdf](https://docs.house.gov/meetings/IF/IF17/20171003/106433/HHRG-115-IF17-Wstate-SmithR-20171003.pdf)

[^9]: Equifax Inc. (2017, September 15). **Equifax Announces Cybersecurity Firm Has Concluded Forensic Investigation of Cybersecurity Incident**. Retrieved from [https://investor.equifax.com/news-and-events/news/2017/09-15-2017-224018832](https://investor.equifax.com/news-and-events/news/2017/09-15-2017-224018832)

[^10]: Krebs, B. (2017, September 18). **Equifax Breach Fallout: Your Salary History**. Krebs on Security. Retrieved from [https://krebsonsecurity.com/2017/09/equifax-breach-fallout-your-salary-history/](https://krebsonsecurity.com/2017/09/equifax-breach-fallout-your-salary-history/)

[^11]: Vaas, L. (2017, October 3). **Equifax ex-CEO pins breach on single employee, takes no personal responsibility**. Naked Security by Sophos. Retrieved from [https://nakedsecurity.sophos.com/2017/10/03/equifax-ex-ceo-pins-breach-on-single-employee-takes-no-personal-responsibility/](https://nakedsecurity.sophos.com/2017/10/03/equifax-ex-ceo-pins-breach-on-single-employee-takes-no-personal-responsibility/)

[^12]: McCoy, K. (2017, September 8). **Equifax breach: 30 state attorneys general launch probe**. USA Today. Retrieved from [https://www.usatoday.com/story/money/2017/09/08/equifax-breach-30-state-attorneys-general-launch-probe/646757001/](https://www.usatoday.com/story/money/2017/09/08/equifax-breach-30-state-attorneys-general-launch-probe/646757001/)

[^13]: Sweet, K. (2017, September 14). **Equifax faces mounting criticism over massive data breach**. PBS NewsHour. Retrieved from [https://www.pbs.org/newshour/economy/equifax-faces-mounting-criticism-massive-data-breach](https://www.pbs.org/newshour/economy/equifax-faces-mounting-criticism-massive-data-breach)


Photo by Pixabay: https://www.pexels.com/photo/two-motorcycle-racers-turning-at-corner-163291/
