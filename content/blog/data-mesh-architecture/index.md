---
title: "Data Mesh Architecture"
lastmod: 2023-04-20T16:54:36+05:30
date: 2023-04-20T16:54:36+05:30
draft: false
Author: Pradeep Loganathan
tags: 
  - "data mesh"
  - "data engineering"
  - "data architecture"
  - "data"
categories: 
  - "datamesh"
summary: "Data Mesh architecture is a modern approach to data engineering and data operations that aims to improve the scalability, agility, and innovation of data teams within organizations."
ShowToc: true
TocOpen: false
images:
  - images/datamesh.png
cover:
    image: "images/datamesh.png"
    alt: "Data Mesh Architecture"
    caption: "Data Mesh Architecture"
    relative: true # To use relative path for cover image, used in hugo Page-bundles
editPost:
  URL: "https://github.com/PradeepLoganathan/pradeepl-blog/tree/master/content"
  Text: "Edit this post on github" # edit text
  appendFilePath: true # to append file path to Edit link

mermaid: true

---

## Introduction

Data Mesh architecture is a modern approach to data engineering and data operations that aims to improve the scalability, agility, and innovation of data teams within organizations. It is based on the principles of domain-oriented ownership, product thinking, self-serve data infrastructure, platform thinking, data as a first-class citizen, democratized data access, and a culture of collaboration.

In a Data Mesh architecture, data ownership is distributed among domain-oriented teams who are responsible for the data within their respective domains. These domain teams operate with a product mindset, treating data as a product and using product management practices to define data product roadmaps, iterate on data products, and align them with business needs. The concept of domain-oriented teams in data mesh architecture is based on the idea that data expertise should be distributed across the organization, rather than being concentrated in a central data team. By empowering domain-oriented teams with data ownership and autonomy, organizations can enable faster decision-making, agility, and innovation in their data operations. These teams have access to self-serve data infrastructure, which provides standardized data tools, services, and APIs allowing them to create, manage, and operate their data pipelines, data stores, and data products independently. This promotes agility and reduces dependence on centralized data engineering teams.

By adopting a Data Mesh approach, organizations aim to overcome the limitations of traditional centralized data engineering practices, such as bottlenecks, lack of ownership, and scalability challenges. 

## Traditional Data Architectures

The industry currently uses multiple data architectures each with their pros and cons.

### Centralized Data Warehouse/Data Lake Architecture

In this design, data is ingested, stored, and processed in a central repository such as a data warehouse or data lake. Data is then made available to various data consumers and applications for analysis and insights. This approach provides a unified data repository and central data governance but may face challenges in scalability, flexibility, and agility for domain-specific data operations.

A data warehouse or data lake is a centralized data storage system that is designed for efficient querying and analysis of large volumes of data from various sources. Data warehouses are used by organizations to support decision-making processes, enable data-driven insights, and facilitate business intelligence (BI) and analytics.Traditional data warehouse architectures face several challenges, such as:

1. Scalability: Traditional data warehouses may have limitations in terms of scalability, as they are often built on fixed hardware infrastructure that may not easily accommodate growing data volumes or changing data requirements. Scaling up or out may be time-consuming and expensive.

2. Cost: Traditional data warehouses typically require significant upfront investments in hardware, software, and skilled personnel for setup, maintenance, and ongoing operations. These costs can be prohibitive for smaller organizations or those with limited budgets.

3. Complexity: Traditional data warehouses can be complex to set up, configure, and maintain, as they often involve multiple components such as database servers, ETL processes, data integration, and data modeling. Managing these components and ensuring their interoperability can be challenging.

4. Data Integration: Traditional data warehouses may face challenges in integrating data from diverse sources, as they may require complex ETL processes, data mapping, and data consolidation. Data integration may require significant time and effort, and changes in data sources may require updates to the ETL processes and data models.

5. Latency: Traditional data warehouses have limitations in handling real-time data or near-real-time data, as data may need to go through ETL processes before being loaded into the data warehouse. This can result in data latency, which may not be suitable for organizations that require up-to-date insights from their data. Most organizations generally have a latency of 16 - 24 hours before the data warehouse has the necessary data to be served up.

6. Agility: Traditional data warehouses may lack the agility required to quickly adapt to changing business requirements or data needs. Changes in data sources, data models, or data processing requirements may require significant effort and time to implement in traditional data warehouse architectures.

7. Data Governance: Traditional data warehouses may face challenges in implementing robust data governance practices, such as data lineage, data quality, and data security. Ensuring consistent data governance across the data warehouse may require additional effort and resources.

8. Vendor Lock-In: Traditional data warehouses may be tied to specific vendors or technologies, which may result in vendor lock-in and limit the organization's ability to switch to different technologies or vendors in the future.

9. Performance: Traditional data warehouses may face performance challenges in handling large data volumes, complex queries, or high concurrency. Tuning and optimizing performance in traditional data warehouses requires specialized skills and expertise.

10. Data Privacy and Compliance: Traditional data warehouses may face challenges in meeting data privacy and compliance requirements, such as GDPR, HIPAA, or industry-specific regulations. Ensuring compliance and data privacy in traditional data warehouses may require additional efforts in terms of data masking, data encryption, and access controls.

Most of these challenges vary depending on the specific architecture and implementation, as well as the organization's data requirements, size, and industry. However, these challenges are some of the common ones that organizations face when working with the centralized data warehouse/data lake architectures.

A generic high level centralized data warehouse/data lake architecture is below

{{< mermaid >}}
graph TD
  A[Data Source] --> B[Extract]
  A1[Data Source] --> B
  A2[Data Source] --> B
  A3[Data Source] --> B
  B --> C[Transform]
  C --> D[Load]
  D --> E[Data Warehouse]
  E --> F[Data Marts]
  E --> G[Reporting and Analytics]
  E --> H[Data Governance]
  F --> I[Data Mart 1]
  F --> J[Data Mart 2]
  F --> K[Data Mart 3]
  G --> L[Reporting and Analytics Tools]
  H --> M[Data Governance Tools]
{{< /mermaid >}}

### Monolithic Data Architecture

Monolithic Data Architecture typically refers to a broader approach where all data-related tasks and responsibilities are consolidated within a single team or department, covering data engineering, data science, data analytics, data governance, and data operations. In this architecture data governance policies, standards, and practices are enforced centrally by the data team, covering all data-related tasks. In this architecture data is typically ingested from various sources into a centralized data repository, such as a data warehouse or a data lake. Data is processed, transformed, and stored in this centralized repository, and data consumers and applications access the data from this central repository for analysis and insights. Monolithic Data Architecture provides a single point of control and coordination for data initiatives, which can be beneficial in organizations with centralized data management requirements, strict data governance policies, and standardized data processing. However, it may face challenges in agility, autonomy, and scalability, especially in organizations with diverse data needs across different domains or business units.

A generic Monolithic Data architecture is below

{{< mermaid >}}
graph LR


subgraph "Monolithic Data Architecture"

subgraph "Monolithic Data System"

  subgraph "Data Ingestion"
    DI1[Data Ingestion 1]
    DI2[Data Ingestion 2]
    DI3[Data Ingestion 3]
  end

  subgraph "Data Storage & Processing"
    DSP1[Data Storage & Processing 1]
    DSP2[Data Storage & Processing 2]
    DSP3[Data Storage & Processing 3]
  end

  subgraph "Data Analytics"
    DA1[Data Analytics 1]
    DA2[Data Analytics 2]
    DA3[Data Analytics 3]
  end

  subgraph "Data Governance"
    DG1[Data Governance 1]
    DG2[Data Governance 2]
    DG3[Data Governance 3]
  end

  subgraph "Data Operations"
    DO1[Data Operations 1]
    DO2[Data Operations 2]
    DO3[Data Operations 3]
  end
  
end

end

classDef orange fill:#f96,stroke:#333,stroke-width:4px
classDef blue fill:#2986cc,stroke:#333,stroke-width:4px
classDef green fill:#38761d,stroke:#333,stroke-width:4px
class DI1 orange
class DI2 blue
class DI3 green
class DSP1 orange
class DSP2 blue
class DSP3 green
class DA1 orange
class DA2 blue
class DA3 green
class DG1 orange
class DG2 blue
class DG3 green
class DO1 orange
class DO2 blue
class DO3 green

{{< /mermaid >}}

In this architecture, data is ingested from various sources (represented by "Data Ingestion" boxes) into a centralized data storage and processing layer (represented by "Data Storage & Processing" boxes). Data is then analyzed using data analytics tools (represented by "Data Analytics" boxes), and data governance policies and practices are enforced (represented by "Data Governance" boxes). Data operations, such as data integration, transformation, and management, are also performed within the monolithic data architecture (represented by "Data Operations" boxes).

Now that we have seen a couple of examples of traditional data architectures let us understand the key concepts of Data mesh architecture.

## Key concepts of Data Mesh Architecture

In a Data mesh architecture data is treated as a first-class citizen, with proper data governance, quality, and security measures in place. Democratized data access is enabled, providing self-service data access tools and technologies that empower business users, data scientists, and other stakeholders to access and analyze data without relying on data teams for every data request.

Data teams collaborate closely with domain teams, business stakeholders, and other data teams to ensure alignment, knowledge sharing, and cross-domain learning. This promotes a culture of collaboration, innovation, and continuous improvement in the organization. Data teams are groups of individuals within an organization who are responsible for various aspects of data-related tasks, such as data engineering, data science, data analytics, data governance, and data operations. These teams work collaboratively to manage and leverage data assets to support the organization's objectives and goals.This team typically consist of professionals with diverse skills and expertise, including data engineers who design and implement data pipelines and data infrastructure, data scientists who develop models and algorithms to extract insights from data, data analysts who analyze data and generate actionable insights, and data governance professionals who ensure data quality, security, and compliance.

Data Mesh also emphasizes the use of modern data practices such as event-driven architecture, dataOps, and data meshOps, which align with the principles of DevOps and Agile methodologies. Additionally, Data Mesh encourages the use of data mesh patterns, such as data product thinking, data discovery, and data infrastructure as code, to enable efficient and effective data operations.

Overall, Data Mesh architecture aims to decentralize data ownership, promote product thinking, enable self-serve data infrastructure, treat data as a first-class citizen, democratize data access, and foster a culture of collaboration. By adhering to these principles, organizations can improve their data operations and drive data-driven agility and innovation.

### Principles of Data Mesh Architecture

Data Mesh architecture is based on a set of key principles that provide a foundation for its design and implementation. These principles include:

1. Domain-oriented ownership: Data is owned by domain-oriented teams who are responsible for the data within their respective domains. This promotes data autonomy and accountability, allowing domain teams to make decisions on data models, data pipelines, and data products that are aligned with their specific domain needs.

2. Product thinking: Data is treated as a product, and data teams operate with a product mindset. This includes applying product management practices such as understanding customer needs, defining data product roadmaps, and iterating on data products based on feedback and data-driven insights.

3. Self-serve data infrastructure: Data teams have access to self-serve data infrastructure that allows them to create, manage, and operate their data pipelines, data stores, and data products independently. This promotes agility and reduces dependence on centralized data engineering teams for day-to-day data operations.

4. Platform thinking: Data infrastructure is treated as a platform that provides standardized data tools, services, and APIs that can be leveraged by domain teams to build and operate their data products. This promotes consistency, reusability, and scalability across different domains.

5. Data as a first-class citizen: Data is treated as a first-class citizen in the organization, with proper governance, quality, and security measures in place. This includes establishing data standards, data lineage, data quality checks, and data security protocols to ensure data integrity and compliance.

6. Democratized data access: Data is democratized and made accessible to various stakeholders across the organization. This includes providing self-service data access tools and technologies that empower business users, data scientists, and other stakeholders to access and analyze data without relying on data teams for every data request.

7. Culture of collaboration: Data teams collaborate closely with domain teams, business stakeholders, and other data teams to ensure alignment, knowledge sharing, and cross-domain learning. This promotes a culture of collaboration, innovation, and continuous improvement in the organization.

These key principles of Data Mesh architecture emphasize domain-centric ownership, product thinking, self-serve data infrastructure, platform thinking, data governance, democratized data access, and a culture of collaboration. By adhering to these principles, organizations can unlock the benefits of Data Mesh architecture and enable data-driven agility and innovation in their data operations. Let us now look at a generic implementation of Data mesh architecture

{{< mermaid >}}

graph TD
  A[Domain 1] --> B[Domain 2]
  B --> C[Domain 3]
  C --> D[Domain 4]
  D --> E[Domain 5]
  F[Data Ingestion]
  G[Data Quality]
  H[Data Mapping]
  I[Data Consolidation]
  J[Data Serving API]
  K[Data Lineage]
  L[Data Storage]
  M[Data Liveliness]
  N[Data Governance]
  
  F --> A
  F --> B
  F --> C
  F --> D
  F --> E
  G --> A
  G --> B
  G --> C
  G --> D
  G --> E
  H --> A
  H --> B
  H --> C
  H --> D
  H --> E
  I --> A
  I --> B
  I --> C
  I --> D
  I --> E
  J --> A
  J --> B
  J --> C
  J --> D
  J --> E
  K --> A
  K --> B
  K --> C
  K --> D
  K --> E
  J --> L
  L --> M
  N --> A
  N --> B
  N --> C
  N --> D
  N --> E

{{< /mermaid >}}

This is a generic architecture for a data mesh implementation.