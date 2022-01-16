---
title: "Web Application security"
date: "2017-06-01"
---

## **Caching vulnerabilities.**

Search engines like Google, Bing, and others crawl the web, index, and cache a lot of information. Search engine caching can potentially expose sensitive data from a web application to unauthorized users. It is essential to understand the impact of search engine indexing and caching to ensure that we do not run into issues with exposure of sensitive application data.

#### **Cacheable HTTPS responses**

HTTPS is a protocol which secures communications between the browser and web application. While this provides security to the data in-transit, HTTPS responses are cacheable and can stored insecurely. Insecure processing of HTTPS responses can lead to data leaks.If a web application returns sensitive data in an HTTPS response then the data will be cached as plain text. Ideally sensitive data should never be returned in a response message.

If the headers`  
cache-control:no-store`  
`Pragma : no-cache`

are applied to the resource then the https response will not be cached. These are called anti-caching headers. Setting only the Pragma:no-cache HTTP header may not necessarily make the representation uncacheable. The HTTP specification does not set any guidelines for pragma response headers and this is not honored by a majority of the applications. The Cache-control header introduced in HTTP 1.1 gives web developers more control over caching. More information about this can be found in the [HTTP specification](http://www.ietf.org/rfc/rfc2616.txt), specifically section 13.

This can also be done in ASP.NET code as below

**Caching of sensitive data in HTML form protected by HTTPS**

Data in an HTML form protected by HTTPS can be cached in plain text if autocomplete=off attribute is not implemented. The anti-caching attribute autocomplete = off should be implemented for every control so that the data entered by the user is not cached.  

&amp;amp;amp;lt;/p&amp;amp;amp;gt;&amp;amp;lt;br /&amp;amp;gt;&amp;lt;br /&amp;gt;&lt;br /&gt; &amp;amp;amp;lt;img src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" data-wp-preserve="%3Cstyle%20type%3D%22text%2Fcss%22%3Ebody%2C.so-header%7Bmargin-top%3A1.9em%7D%3C%2Fstyle%3E" data-mce-resize="false" data-mce-placeholder="1" class="mce-object" width="20" height="20" alt="&amp;amp;amp;amp;lt;style&amp;amp;amp;amp;gt;" title="&amp;amp;amp;amp;lt;style&amp;amp;amp;amp;gt;" /&amp;amp;amp;gt;&amp;amp;lt;br /&amp;amp;gt;&amp;lt;br /&amp;gt;&lt;br /&gt; &amp;amp;amp;lt;p&amp;amp;amp;gt;

<table><tbody><tr><td class="postcell"><div class="post-text"><pre class="default prettyprint prettyprinted"><code><span class="tag">&lt;form</span> <span class="atn">autocomplete</span><span class="pun">=</span><span class="atv">"off"</span><span class="tag">&gt;</span>
<span class="tag">&lt;input</span> <span class="atn">type</span><span class="pun">=</span><span class="atv">"text"</span> <span class="atn">autocomplete</span><span class="pun">=</span><span class="atv">"off"</span> <span class="atn">name</span><span class="pun">=</span><span class="atv">"login"</span> <span class="tag">/&gt;</span>
<span class="tag">&lt;input</span> <span class="atn">type</span><span class="pun">=</span><span class="atv">"password"</span> <span class="atn">autocomplete</span><span class="pun">=</span><span class="atv">"off"</span> <span class="atn">name</span><span class="pun">=</span><span class="atv">"pswd"</span> <span class="tag">/&gt;</span><span class="pln">
...</span></code><code></code></pre></div></td></tr></tbody></table>

HTTPS protected passwords and credit card data can be cached in plain text.  
For e.g Password reset links can have tokens which can be used by attackers.The attacker can use a Google search such as Site:example.com inurl:token that returns all links to example.com with a token in the URL or Site:example.com inurl:reset which return all links to example.com with a reset keyword in the URL. The attacker can then use the cached links to hijack the session and reset the user password thus essentially gaining access to the account. To avoid running into this issue we need to ensure that Google does not cache sensitive resources by adding in these resources.These resources will now not be indexed and hence cached.

In ASP.NET we can also set these using the below code

Sensitive data in URL results in sensitive data in server logs and browsing history.

OWASP ASVS (Application Security Verification Standard)

**Data in URL**

if sensitive data is sent in URL  then it will result in disclosure of sensitive information even if it is sent over secure HTTPS. The data can be disclosed in server logs and browsing history.

To fix the issue sensitive data should never be sent in URL via GET parameter. Use post and not get.

Section V9 of OWAS ASVS specifies a lot of these conditions.

**Sensitive Data Exposure**

Verbose error messages - If the proper handling of errors and exceptions is not implemented an application can generate verbose error messages which can include source code, database credentials, details of internal implementation etc. An attacker can trigger error messages by providing erroneous or wrong data.

Disclosure of sensitive files - The attacker can read robots.txt which is publicly available and indicates sensitive directories which search engines should not crawl. If directory listing is enabled then the attacker can browse to those folders and see files in them. The default file handler lists the contents of a file. Files with non-standard extensions do not have handlers and are managed by the default handler resulting on their contents being listed.

Disclosure via metadata - Files have metadata which contains sensitive information. For eg photographs have GPS coordinates, Word documents can contain author, comments, revision history etc. Tools such as ExifTool can be used to extract metadata from pictures uploaded on websites which can provide a treasure trove of information to help the attacker with social attacks.

Disclosure of software version - Software version information can help the attacker with fine tuning his plan of attack.The attacker can send different application requests and analyze response headers. HTTP response headers contain server information and headers such as x-powered-by can be used to further identify details of the web server and the software version used. As an example using the software version, you can check http://exploit-db.com for exploits for a particular version of the software and use that exploit if the system has not been patched.

Insecure communications channel - Using HTTP is not enough you need to configure it correctly. HTTP guarantees confidentiality, HTTP + transport layer protection. Data sent between browser and server cannot be read or tampered. Transport layer protection is provided by two protocols SSL and TLS.  This has to be configured correctly to guarantee security.

SSL3 is an insecure protocol POODLE attack.,

Insecure CIPHER suite eg: TLS\_RSA\_WITH\_RC4\_128\_SHA,

vulnerability in crypto libraries e.g Heartbleed and more

online scanner to test http://ssllabs.com/ssltest

Picture Courtesy - [James Sutton](https://unsplash.com/@jamessutton_photography)
