
Report Summary

┌────────────────────────────────────┬──────────┬─────────────────┬─────────┐
│               Target               │   Type   │ Vulnerabilities │ Secrets │
├────────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ postgres:16-alpine (alpine 3.22.2) │  alpine  │        0        │    -    │
├────────────────────────────────────┼──────────┼─────────────────┼─────────┤
│ usr/local/bin/gosu                 │ gobinary │       10        │    -    │
└────────────────────────────────────┴──────────┴─────────────────┴─────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)


usr/local/bin/gosu (gobinary)
=============================
Total: 10 (UNKNOWN: 0, LOW: 0, MEDIUM: 6, HIGH: 4, CRITICAL: 0)

┌─────────┬────────────────┬──────────┬────────┬───────────────────┬────────────────┬──────────────────────────────────────────────────────────────┐
│ Library │ Vulnerability  │ Severity │ Status │ Installed Version │ Fixed Version  │                            Title                             │
├─────────┼────────────────┼──────────┼────────┼───────────────────┼────────────────┼──────────────────────────────────────────────────────────────┤
│ stdlib  │ CVE-2025-58183 │ HIGH     │ fixed  │ v1.24.6           │ 1.24.8, 1.25.2 │ golang: archive/tar: Unbounded allocation when parsing GNU   │
│         │                │          │        │                   │                │ sparse map                                                   │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-58183                   │
│         ├────────────────┤          │        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-58186 │          │        │                   │                │ Despite HTTP headers having a default limit of 1MB, the      │
│         │                │          │        │                   │                │ number of...                                                 │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-58186                   │
│         ├────────────────┤          │        │                   ├────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-58187 │          │        │                   │ 1.24.9, 1.25.3 │ Due to the design of the name constraint checking algorithm, │
│         │                │          │        │                   │                │ the proce...                                                 │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-58187                   │
│         ├────────────────┤          │        │                   ├────────────────┼──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-58188 │          │        │                   │ 1.24.8, 1.25.2 │ Validating certificate chains which contain DSA public keys  │
│         │                │          │        │                   │                │ can cause ......                                             │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-58188                   │
│         ├────────────────┼──────────┤        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-47912 │ MEDIUM   │        │                   │                │ net/url: Insufficient validation of bracketed IPv6 hostnames │
│         │                │          │        │                   │                │ in net/url                                                   │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-47912                   │
│         ├────────────────┤          │        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-58185 │          │        │                   │                │ encoding/asn1: Parsing DER payload can cause memory          │
│         │                │          │        │                   │                │ exhaustion in encoding/asn1                                  │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-58185                   │
│         ├────────────────┤          │        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-58189 │          │        │                   │                │ crypto/tls: go crypto/tls ALPN negotiation error contains    │
│         │                │          │        │                   │                │ attacker controlled information                              │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-58189                   │
│         ├────────────────┤          │        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-61723 │          │        │                   │                │ encoding/pem: Quadratic complexity when parsing some invalid │
│         │                │          │        │                   │                │ inputs in encoding/pem                                       │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-61723                   │
│         ├────────────────┤          │        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-61724 │          │        │                   │                │ net/textproto: Excessive CPU consumption in                  │
│         │                │          │        │                   │                │ Reader.ReadResponse in net/textproto                         │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-61724                   │
│         ├────────────────┤          │        │                   │                ├──────────────────────────────────────────────────────────────┤
│         │ CVE-2025-61725 │          │        │                   │                │ net/mail: Excessive CPU consumption in ParseAddress in       │
│         │                │          │        │                   │                │ net/mail                                                     │
│         │                │          │        │                   │                │ https://avd.aquasec.com/nvd/cve-2025-61725                   │
└─────────┴────────────────┴──────────┴────────┴───────────────────┴────────────────┴──────────────────────────────────────────────────────────────┘
