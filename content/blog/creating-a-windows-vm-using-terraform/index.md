---
title: "Creating a Windows VM using Terraform"
date: "2020-05-18"
categories: 
  - "iac"
  - "terraform"
tags: 
  - "devops"
  - "iac"
  - "terraform"
---

This post is a follow up on the [Terraform](https://pradeeploganathan.com/cloud/terraform-getting-started) 101 session for the Sunshine Coast dotnet user group. The slides and the code from the session are below.

## Slides

<iframe src="//www.slideshare.net/slideshow/embed_code/key/hpSI3Kh84vIIu6" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen></iframe>

**[Terraform 101](//www.slideshare.net/pradeep_loganathan/terraform-101-234192420 "Terraform 101")** from **[Pradeep Loganathan](https://www.slideshare.net/pradeep_loganathan)**

  

## Creating a Windows Virtual Machine

<script src="https://gist.github.com/PradeepLoganathan/711b4f4a1da9a54f0b96902c1b184975.js"></script>

<a href="https://gist.github.com/PradeepLoganathan/711b4f4a1da9a54f0b96902c1b184975">View this gist on GitHub</a>

The above code is not at all production ready and was used as part of a live coding exercise to use Terraform to create a Windows VM. The above code creates the VM password as plain text which is not ideal. The password can be generated and printed as an output if necessary.

> Photo by [Wengang Zhai](https://unsplash.com/@wgzhai?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText) on [Unsplash](https://unsplash.com/?utm_source=unsplash&utm_medium=referral&utm_content=creditCopyText)
