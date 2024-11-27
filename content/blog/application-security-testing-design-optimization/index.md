---
title: "Flipping the Script: Elevating Security to the Pinnacle of Design with AST"
author: Pradeep Loganathan
date: 2024-11-25T16:36:41+10:00
lastmod: 2024-11-25T16:36:41+10:00
draft: false
tags:
  - Application Security
  - AST
  - Software Development
categories:
  - Security
  - Development
description: "Exploring the critical role of Application Security Testing (AST) in modern software development and why it should be at the core of organizational processes."
summary: "This blog post examines the importance of elevating Application Security Testing to the core of design and development processes, using the Equifax data breach as a cautionary tale."
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

On the morning of July 29, 2017, a member of Equifax's internal IT security team finally addressed a neglected task: renewing an expired SSL certificate for a network traffic monitoring system[^1][^2]. This update lifted a critical blindfold from their monitoring tools. The team could now detect suspicious network activity that had been hidden for months due to the expired certificate. What they saw was alarming—a massive amount of unexplained outbound data transfers[^3]. By updating the certificate, the security team inadvertently uncovered one of the largest data breaches in history, exposing the personal information of 147.9 million people[^4].

Uncovering the suspicious data egress was just the beginning. The unusual traffic wasn't immediately linked to its root cause: a critical vulnerability known as **Apache Struts CVE-2017-5638**[^5][^6]. Publicly disclosed in March 2017, this flaw allowed attackers to execute malicious code on Equifax's servers, granting them unfettered access to sensitive data. Despite the availability of a patch, Equifax's development teams failed to prioritize it through multiple iterations[^7]. This oversight was a glaring failure in their development process—a neglect of essential security updates in favor of tasks deemed more immediate.

The reasons were multifaceted: inadequate vulnerability management processes, poor communication between security and development teams, and a lack of urgency in addressing known risks[^8]. Ironically, while Equifax's development team was intensely focused on pushing the boundaries of innovation and striving for market dominance, they neglected the very security measures that would safeguard their achievements. Their failure to promptly patch the critical vulnerability wasn't just an oversight; it was symptomatic of a systemic issue where security was not integrated into the development lifecycle as a priority. In their relentless pursuit of advancement, they overlooked the foundational necessity of robust security, ultimately undoing their ambitious efforts.

To comprehend the full extent of the damage, Equifax enlisted cybersecurity firm Mandiant[^9]. Their investigation revealed a devastating truth: hackers had exploited the unpatched vulnerability for three to four months, siphoning off sensitive data—including names, Social Security numbers, birth dates, and addresses—without detection[^10][^11]. The fallout was swift and severe. Public outrage erupted as news of the breach spread, leading to lawsuits and regulatory investigations[^12]. Equifax faced immense pressure to compensate affected individuals and overhaul its security infrastructure. The company's reputation was irreparably tarnished, and its growth trajectory faltered[^13].

This incident wasn't just a catastrophic data breach; it was a glaring indictment of how even industry giants can falter by not integrating security at the foundational level of development. It prompts us to ask: **Are we focusing on the right pinnacle in our design and development processes? Should Application Security Testing (AST) be elevated from a mere step in the development cycle to the very core of our organizational process optimization?**

In a world where cyber threats evolve faster than software features, it's time to flip the script. I boldly assert that AST should not just be an integral part of development—it should be the driving force that shapes how we design, develop, and operate as an organization. Placing AST at the apex of systems design can transform our approach to innovation, redefine our success metrics, and ultimately protect the ambitions we strive so hard to achieve.

---

## The Feature Frenzy: Is Security Being Left Behind?

Like the teams at Equifax, many software development organizations focus primarily on delivering features, enhancing user experience, and reducing time-to-market. Agile methodologies and continuous deployment pipelines have accelerated development, often emphasizing quantity over quality. While these approaches drive innovation and user satisfaction, they have inadvertently relegated security to a secondary concern.

Security is frequently treated as an afterthought or a separate phase, disconnected from the core development process. It's not uncommon for security assessments to occur only after a product is near completion or even post-deployment. This siloed approach creates gaps where vulnerabilities can slip through unnoticed, leaving applications exposed to threats.

The sidelining of security has led to a disturbing rise in security breaches and vulnerabilities. High-profile incidents like the Equifax breach are stark reminders of the risks involved. Companies face hidden costs when they neglect security:

- **Financial Losses**: Direct costs from breach mitigation, legal fees, and compensation to affected customers can be staggering.
- **Reputational Damage**: Loss of customer trust can lead to decreased sales and long-term brand erosion.
- **Regulatory Penalties**: Non-compliance with data protection regulations results in hefty fines and increased scrutiny from governing bodies.

These consequences highlight a critical flaw in the current development paradigm: by prioritizing feature development over security, organizations inadvertently jeopardize the very assets they aim to grow.

---

## Elevating Security to the Pinnacle: How AST Enables a Security-First Approach

It's time to redefine what success looks like in software development. Instead of measuring success solely by features delivered or user adoption rates, organizations should prioritize the robustness of their security posture. Success should be gauged by the absence of vulnerabilities and the application's resilience against threats. This shift places security at the forefront, making it the main criterion for progress and achievement. After all, when an application is easily breached, the new features don't look so shiny anymore. To truly make security the cornerstone of success, we must move beyond treating it as an afterthought.

This is where **Application Security Testing (AST)** comes into play.

**Application Security Testing (AST)** encompasses a suite of processes and tools designed to identify, address, and prevent security vulnerabilities within software applications throughout their development lifecycle. AST includes methods such as:

- **Static Application Security Testing (SAST)**: Analyzes source code to detect vulnerabilities without executing the program.
- **Dynamic Application Security Testing (DAST)**: Examines applications in their running state to identify vulnerabilities that could be exploited in a live environment.
- **Interactive Application Security Testing (IAST)**: Combines elements of SAST and DAST by analyzing applications during runtime while having access to the source code.
- **Runtime Application Self-Protection (RASP)**: Monitors and protects applications in real-time within their production environment.

By integrating AST, organizations ensure that security is not a separate phase but an integral part of every development stage.

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

Embracing Application Security Testing as the core of our design and development processes is not just a bold proposition; it's a strategic imperative. As we've seen with Equifax, neglecting security can have devastating consequences. By prioritizing AST, we not only protect our organizations but also pave the way for sustainable innovation.

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
