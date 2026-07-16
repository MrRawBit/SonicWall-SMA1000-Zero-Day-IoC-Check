# SonicWall SMA1000 Zero-Day IoC Check

An unofficial Bash-based log check for selected indicators of compromise associated with the actively exploited SonicWall SMA 1000 Series vulnerabilities **CVE-2026-15409** and **CVE-2026-15410**.

> [!CAUTION]
> **Independent community project:** This repository is not affiliated with, endorsed by, maintained by, or supported by SonicWall or the German Federal Office for Information Security (BSI).

> [!IMPORTANT]
> This script is a limited detection aid. A clean result does **not** prove that an appliance is uncompromised, and a match is not a complete forensic conclusion.

## Security Context

On **14 July 2026**, SonicWall published security advisory **SNWLID-2026-0008** for two zero-day vulnerabilities affecting the SMA 1000 Series. The vendor reported multiple investigated cases indicating exploitation in the wild.

On **15 July 2026**, the BSI published **BITS-H Nr. 2026-271845-1032**, Version 1.0:

> **SonicWall SMA1000 – Zero-Day Schwachstellen aktiv ausgenutzt**  
> Kritikalität 3 / Orange

The BSI recommends that security teams promptly implement protective measures and initiate forensic investigation.

## Affected Products

The advisory covers the following SMA 1000 Series models:

- SonicWall SMA 6210
- SonicWall SMA 7210
- SonicWall SMA 8200v

Always consult the current SonicWall advisory to confirm affected versions and supported remediation.

## Vulnerabilities

### CVE-2026-15409

A critical server-side request forgery vulnerability in the SMA1000 Appliance Work Place interface. A remote unauthenticated attacker may be able to cause the appliance to make requests to unintended locations.

- Weakness: Server-Side Request Forgery
- CWE: CWE-918
- Vendor severity: Critical
- CVSS score: 10.0
- Authentication required: No

### CVE-2026-15410

A code-injection vulnerability in the SMA1000 Appliance Management Console. Under specific conditions, an authenticated administrator may be able to execute arbitrary operating-system commands remotely.

- Weakness: Code Injection
- CWE: CWE-94
- Vendor severity: High
- CVSS score: 7.2
- Authentication required: Administrator access

> [!NOTE]
> Some shortened publications may show `CVE-2026-1541`. The complete identifier is **CVE-2026-15410**.

## Repository Contents

```text
SonicWall-SMA1000-Zero-Day-IoC-Check/
├── README.md
├── NOTICE.md
└── sonicwall-sma1000-ioc-check.sh
```

## What the Script Does

The script searches selected SMA1000 access and control-service logs for predefined patterns that may warrant further investigation.

It:

- scans active and rotated log files;
- supports gzip-compressed logs through `zgrep`;
- checks selected authentication, WebSocket proxy, and hotfix-removal patterns;
- runs locally on the appliance;
- does not modify the appliance or its logs;
- does not intentionally transmit logs or results;
- returns automation-friendly exit codes.

It does **not**:

- install updates or hotfixes;
- determine whether an appliance is vulnerable;
- detect every exploitation or persistence technique;
- replace forensic analysis or current vendor guidance;
- remediate a compromised system.

## Requirements

- A supported SonicWall SMA 1000 Series appliance
- Bash
- `zgrep` / GNU gzip utilities
- Root privileges
- Access to `/var/log/aventail`

## Installation

Clone the repository:

```bash
git clone https://github.com/MrRawBit/SonicWall-SMA1000-Zero-Day-IoC-Check.git
cd SonicWall-SMA1000-Zero-Day-IoC-Check
```

Make the script executable:

```bash
chmod +x sonicwall-sma1000-ioc-check.sh
```

## Usage

Run the script with root privileges:

```bash
sudo ./sonicwall-sma1000-ioc-check.sh
```

When no configured pattern is found:

```text
No configured SMA1000 indicators of compromise were found.
A clean result does not prove that the appliance is uncompromised.
```

When at least one configured pattern is detected:

```text
WARNING: Potential SMA1000 indicators of compromise were detected.
Preserve evidence, isolate the appliance when appropriate, and follow current incident-response and vendor guidance.
```

## Exit Codes

| Code | Meaning |
|---:|---|
| `0` | No configured IoC pattern was detected |
| `1` | At least one configured IoC pattern was detected |
| `2` | A prerequisite or execution error occurred |

Exit code `2` includes missing root privileges, a missing `zgrep` command, a missing log directory, or no supported log files.

Example for automated workflows:

```bash
sudo ./sonicwall-sma1000-ioc-check.sh
result=$?

case "$result" in
  0)
    echo "No configured indicators detected."
    ;;
  1)
    echo "Potential compromise detected. Begin incident-response procedures."
    ;;
  2)
    echo "The check could not be completed. Review the error output."
    ;;
esac
```

## Detection Patterns

The script currently searches for patterns involving:

- successful requests to selected authentication API endpoints;
- suspicious WebSocket proxy connections to wildcard or loopback hosts;
- path-traversal-like strings associated with hotfix-removal activity.

The following files are checked:

```text
/var/log/aventail/extraweb_access.log*
/var/log/aventail/ctrl-service.log*
```

Both plain-text and gzip-compressed rotated logs are included. The exact regular expressions are visible in [`sonicwall-sma1000-ioc-check.sh`](./sonicwall-sma1000-ioc-check.sh).

## Fixed Versions

The SonicWall advisory identifies the following fixed platform-hotfix versions:

- `12.4.3-03453` or later
- `12.5.0-02835` or later

Verify these versions against the current vendor advisory before making operational decisions.

## Recommended Response

When the script reports a possible indicator:

1. Preserve relevant logs and system evidence.
2. Contact your internal security or incident-response team.
3. Isolate the appliance when operationally appropriate.
4. Follow the current SonicWall PSIRT instructions.
5. Review surrounding log entries and related network activity.
6. Validate the match to rule out a false positive.

Where compromise is suspected or confirmed, follow the vendor's current guidance. This may include re-imaging physical appliances or redeploying virtual appliances, changing user and administrator passwords, and resetting TOTP tokens.

Do not rely on patching alone when compromise is suspected.

## Limitations

- Only a small, predefined set of patterns is checked.
- A clean result is not proof of system integrity.
- Missing, deleted, expired, inaccessible, or manipulated logs can cause incomplete results.
- Log paths and formats may differ between software releases.
- Attackers may alter their techniques and avoid the configured patterns.
- False positives and false negatives are possible.
- The script does not display matching log lines or full forensic context.
- This is not a vulnerability scanner, malware scanner, or forensic suite.

## References

- [SonicWall PSIRT Advisory SNWLID-2026-0008](https://psirt.global.sonicwall.com/vuln-detail/SNWLID-2026-0008)
- [CVE-2026-15409 record](https://www.cve.org/CVERecord?id=CVE-2026-15409)
- [CVE-2026-15410 record](https://www.cve.org/CVERecord?id=CVE-2026-15410)
- [BSI / Allianz für Cyber-Sicherheit: BITS-H Nr. 2026-271845-1032, Version 1.0](https://www.allianz-fuer-cybersicherheit.de/SharedDocs/Cybersicherheitswarnungen/DE/2026/2026-271845-1032.pdf?__blob=publicationFile&v=3)

External references and vendor guidance can change. Treat the current SonicWall advisory as the authoritative source for affected versions, remediation, and updated indicators.

## Contributing

Contributions are welcome, particularly for:

- additional verified IoC patterns with supporting references;
- improved reporting of matching files and lines;
- support for alternative log paths or software versions;
- tests using sanitized sample logs;
- documentation corrections.

Do not submit credentials, session tokens, customer information, unredacted production logs, internal hostnames, sensitive IP addresses, or unrelated exploit code.

## Responsible Use

Use this project only on systems that you own or are explicitly authorized to administer. Preserve evidence and follow applicable organizational, legal, contractual, and regulatory requirements during an investigation.

## Trademark Disclaimer

SonicWall, SMA, and related names may be trademarks of their respective owners. Their use in this repository is solely descriptive and does not imply affiliation, sponsorship, endorsement, or support.

The BSI publication is referenced for defensive-security context. This repository is not an official BSI publication or tool.

## License and Attribution

Review [`NOTICE.md`](./NOTICE.md) before publishing or redistributing this project.

Do not add an open-source license until you have confirmed that you hold the necessary rights to redistribute the original script and detection logic. Renaming the script or changing its comments does not remove third-party copyright, attribution, or licensing obligations.

## Disclaimer

The software is provided without warranty of any kind. Use it at your own risk. All findings should be validated by qualified security personnel and compared with current official vendor guidance.
