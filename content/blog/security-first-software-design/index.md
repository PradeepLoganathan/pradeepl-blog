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
  - images/security-first-software-design-cover.jpg
cover:
  image: "images/security-first-software-design-cover.jpg"
  alt: "Elevating Security in Software Development"
  caption: "Elevating Security in Software Development"
  relative: true
---

On the morning of July 29, 2017, a member of Equifax's internal IT security team finally addressed a long neglected task: renewing an expired SSL certificate for a network traffic monitoring system[^1][^2]. This long pending update lifted a critical blindfold from their monitoring tools. The team could now detect suspicious network activity that had been hidden for months due to the expired certificate. What they saw was alarming—a massive amount of unexplained outbound data transfers[^3]. By updating the certificate, the security team inadvertently uncovered one of the largest data breaches in history, exposing the personal information of 147.9 million people[^4].

Uncovering the suspicious data egress was just the beginning. The unusual traffic wasn't immediately linked to its root cause: a critical vulnerability known as **Apache Struts CVE-2017-5638**[^5][^6] lurking within a key application dependency. Apache Struts is a popular open-source framework used by Java developers to build web applications. This vulnerability had been identified in the core code of Apache Struts, specifically in the Jakarta Multipart parser. The flaw allowed attackers to execute remote code via specially crafted HTTP headers. It is a classic example of a remote code execution (RCE) vulnerability caused by insufficient validation and sanitization. Publicly disclosed in March 2017, this flaw allowed attackers to execute malicious code on Equifax's servers, granting them unfettered access to sensitive data. Despite the availability of a patch, Equifax's development teams failed to prioritize it through multiple iterations[^7] and continued to use a version of Struts that had this vulnerability even after the patch was available for over two months. This oversight was a glaring failure in their development process—a neglect of essential security updates in favor of tasks deemed more immediate.

The reasons were multifaceted: inadequate vulnerability management processes, poor communication between security and development teams, and a lack of urgency in addressing known risks[^8]. Ironically, while Equifax's development team was intensely focused on pushing the boundaries of innovation and striving for market dominance, they neglected the very security measures that would safeguard their achievements. Failing to promptly patch the vulnerability wasn't merely an oversight—it revealed a systemic failure to integrate security into the development lifecycle as a foundational priority. In their relentless pursuit of advancement, they overlooked the foundational necessity of robust security, ultimately undoing their ambitious efforts.

To comprehend the full extent of the damage, Equifax enlisted cybersecurity firm Mandiant[^9]. Their investigation revealed a devastating truth: hackers had exploited the unpatched vulnerability for three to four months, siphoning off sensitive data—including names, Social Security numbers, birth dates, and addresses—without detection[^10][^11]. The fallout was swift and severe. Public outrage erupted as news of the breach spread, leading to lawsuits and regulatory investigations[^12]. Equifax faced immense pressure to compensate affected individuals and overhaul its security infrastructure. The company's reputation was irreparably tarnished, and its growth trajectory faltered[^13].This chain of events underscores how prioritizing security only after a breach occurs is a fundamentally flawed approach.

{{< figure src="images/equifax-stock-price.png" alt="Equifax stock price impact after breach" caption="Consequences of the breach reflected in stock price" >}}

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

1. **[Threat Modeling]({{< ref "/blog/threat-modeling" >}})**: Identifying risks during the design phase ensures that systems are built to mitigate potential attacks.
2. **Secure Coding Practices**: Training developers and enforcing coding standards reduces the likelihood of vulnerabilities entering the codebase. Even better, integrating security tooling right within the IDE to enable secure coding practices makes it seamless.
3. **Automated Validation**: Integrating automated security checks into source control & CI/CD pipelines ensures continuous monitoring and testing throughout development.

When security becomes a guiding principle, the development process becomes not just faster, but also more resilient.

## Security as a First-Class Citizen

To truly prioritize security in software design, it's essential to integrate security into every stage of the development lifecycle. This means considering security requirements during planning, designing with security in mind, implementing secure coding practices, and continuously testing and validating security.

### What Does This Look Like in Practice?

So what does it mean to prioritize security as a first-class citizen in software design? Here are a few examples:

- **Integrating security into the development lifecycle:** At the planning stage, security requirements are gathered and incorporated into the project plan. During the design stage, security is considered as a key aspect of the system architecture. In the implementation stage, secure coding practices are followed, and security testing is integrated into the continuous integration/continuous deployment (CI/CD) pipeline.
- **Making security-informed design decisions:** When designing a new feature, the development team considers the potential security implications and designs the feature with security in mind. For example, when designing a login feature, the team might decide to implement multi-factor authentication to reduce the risk of password-based attacks.
- **Prioritizing security-focused testing and validation:** The development team prioritizes security testing and validation, using techniques like penetration testing, fuzz testing, and static analysis to identify vulnerabilities. Security testing is integrated into the CI/CD pipeline, ensuring that security vulnerabilities are caught and addressed early in the development process.
- **Implementing continuous security monitoring and improvement:** The development team implements continuous security monitoring, using tools like intrusion detection systems and security information and event management (SIEM) systems to detect and respond to security incidents. The team also prioritizes ongoing security improvement, staying up-to-date with the latest security threats and vulnerabilities, and continuously evaluating and improving the security posture of the system.

By prioritizing security as a first-class citizen in software design, development teams can ensure that security is integrated into every stage of the development lifecycle, from planning to deployment. This approach helps to identify and address security vulnerabilities early on, reducing the risk of security breaches and cyber attacks.

## Operationalize Security-First Development

Shifting security left is more than a mindset—it requires practical steps to embed security into every phase of the software development lifecycle (SDLC). Organizations must adopt processes and tools that make security an integral part of their workflows, enabling teams to move quickly without sacrificing safety.

### Turning Philosophy into Practice

To operationalize security-first development, teams need to focus on three key areas:

1. **Proactive Risk Identification**:
   - Incorporate **threat modeling({{< ref "/blog/threat-modeling" >}})** during the design phase to identify and address vulnerabilities early.
   - Establish clear security acceptance criteria for each feature to ensure risks are managed upfront.

2. **Continuous Validation**:
   - Automate testing at every stage of the pipeline to catch vulnerabilities before they escalate.
   - Introduce security checks alongside functional tests in CI/CD pipelines, ensuring that every build meets security standards.

3. **Collaborative Security**:
   - Foster collaboration between development, QA, and security teams by creating shared workflows.
   - Provide teams with real-time visibility into vulnerabilities, risks, and remediation priorities to enable informed decision-making.

These practices lay the foundation for a resilient development process. However, scaling these efforts across modern, fast-paced development cycles requires more than just process changes—it requires the right tools.

### The Role of Application Security Testing (AST)

To operationalize this vision, organizations need tools and processes that make security practical and scalable. This is where **Application Security Testing (AST)** comes in. AST enables teams to:

- **Detect Vulnerabilities Early**: Tools like Static Application Security Testing (SAST) allow developers to identify and address issues during the coding phase, long before deployment.
- **Assess Real-World Risks**: Dynamic Application Security Testing (DAST) simulates attacks on running applications to uncover vulnerabilities that might otherwise go unnoticed.
- **Embed Security in Workflows**: By integrating into CI/CD pipelines, AST tools ensure that security checks happen automatically and continuously, fostering collaboration between development and security teams.
- **Foster Collaboration**: AST tools provide actionable insights to both development and security teams, bridging the gap between speed and safety.

### A Practical Path Forward

Operationalizing security-first development doesn’t have to be overwhelming. By combining cultural shifts with practical tools like AST, organizations can:

1. **Shift Security Left**: Detect vulnerabilities earlier in the SDLC, reducing remediation costs and risks.
2. **Automate Repetitive Tasks**: Free up development and security teams to focus on critical issues by automating routine checks.
3. **Measure Impact**: Use metrics like time-to-fix vulnerabilities and pre-vs-post-deployment issue detection to evaluate the effectiveness of your security practices.

AST doesn’t just complement a security-first philosophy—it amplifies it, making secure development scalable and practical for organizations of all sizes.

## Weighing the Outcomes: Do the Benefits Justify the Shift?

Placing security at the core of your development process does more than strengthen your defenses—it creates a ripple effect of positive change throughout your organization. First, you achieve an unparalleled security posture, minimizing vulnerabilities and drastically reducing the risk of breaches. This not only protects your assets but also establishes a solid foundation upon which you can confidently and rapidly build new features, fostering innovation without compromising security.

This enhanced security translates into a powerful competitive advantage. In a world where consumers are increasingly concerned about data privacy, your commitment to security becomes a key differentiator. Building trust with your customers fosters loyalty and strengthens your brand. Furthermore, you gain access to security-sensitive markets, like finance and healthcare, where stringent regulations often act as barriers to entry.

Tools like Application Security Testing (AST) play a crucial role in enabling this transformation, providing the automation, visibility, and actionable insights needed to make secure development practical and scalable. While embracing AST requires an initial investment, it ultimately leads to long-term efficiency and cost savings. By preventing costly security incidents, you protect your financial resources and avoid the disruption and reputational damage that breaches cause. Moreover, integrating AST streamlines development workflows, eliminates redundant tasks, and fosters a proactive approach to security, optimizing your entire software development lifecycle.

---

## Conclusion

The time has come to flip the script on how we approach software design and development. Flipping the script is about recognizing that security is not a constraint but the very foundation upon which innovation thrives. Security is no longer a luxury or an afterthought—it is the foundation upon which innovation and trust are built. By embedding security at the core of our development processes, we don’t just protect our applications from breaches; we safeguard the very ambitions that drive our organizations forward.

This is not a call to sacrifice speed or innovation for safety—it is a call to redefine success. True innovation is sustainable only when it is secure. Security-first development ensures that every feature, every update, and every interaction rests on a bedrock of resilience.

Tools like Application Security Testing (AST) are not just enablers—they are catalysts for this transformation. They empower teams to move fast and stay secure, bridging the gap between vision and execution. But AST alone isn’t the solution. The real transformation happens when security becomes a shared responsibility, embedded deeply into the culture and workflows of development teams.

The question isn’t whether organizations can afford to prioritize security—it’s whether they can afford not to. The risks of neglecting security are clear, and the rewards of embracing it are even clearer: customer trust, competitive advantage, and the freedom to innovate without fear.

As we look to the future, one thing is certain: the next wave of innovation will belong to those who make security the pinnacle of their design. Will you rise to the challenge and lead the way?

---

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
