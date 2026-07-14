{ pkgs }:
let
  fetchPatch =
    {
      name,
      rev,
      hash,
    }:
    pkgs.fetchpatch2 {
      name = "t3code-${name}.patch";
      url = "https://github.com/khaneliman/t3code/commit/${rev}.patch";
      inherit hash;
    };
in
map fetchPatch [
  {
    name = "fix-agent-interrupt-steer";
    rev = "0961fd7225515fbc9ce3345ac1e855e1f1d744da";
    hash = "sha256-7CPhqbsqKsAmHiRpq7zI3C/RZ5g0lrTS2jO7M75m0pg=";
  }
  {
    name = "perf-lazy-load-terminal-css";
    rev = "904f535940872e21f59f10f12e545ac9e894e713";
    hash = "sha256-D++ggKNE0ZvOAw6IHmeQ67FHD31ELs3FOb1+F0lU1GQ=";
  }
  {
    name = "perf-lazy-load-terminal-drawer";
    rev = "fe4d23ee916229041308d1b8ce6de9abefcb919e";
    hash = "sha256-PfIeQA6Ma08UJegG9Vhx9G0gVxLysVMUK30P6yHwH9o=";
  }
  {
    name = "perf-concurrent-command-resolution";
    rev = "ef44192d8c7d1a58b3197b647f823903a316c176";
    hash = "sha256-Mj8xqESbCEFevkqytSr/BQBwKs1qLEtTET44aVicSd8=";
  }
  {
    name = "perf-desktop-readiness-probe-timeout";
    rev = "8063dd0634ca781725db593f619dda849bbe733b";
    hash = "sha256-mBf/gdIFKoGztmUwlXfAGw7BJ4XqvJk5yhSVY4bfi94=";
  }
  {
    name = "antigravity-provider-settings";
    rev = "7b60a511938e96f3ccc08f51383a467fa174d866";
    hash = "sha256-V1gazdr0zsHCgknA3YS2IbIjItJFbBcc/xjl+9tNZ28=";
  }
  {
    name = "antigravity-provider-driver";
    rev = "f4fa768220ea27af977a3b503c69e36657c753b9";
    hash = "sha256-adOQ7+1hSKDneRV1pGDNeTIw0WNmfuT+37akpyFo0VQ=";
  }
  {
    name = "antigravity-provider-controls";
    rev = "76cc1c6d979d6c0c10533e990edcca84010fcb44";
    hash = "sha256-mXDmNq0VToJMszf5II8OQBj1gXAxfwxfz7j5HGFURxg=";
  }
  {
    name = "antigravity-docs";
    rev = "bc81318c30d5e86236f0854b45a17f9c8e0f4456";
    hash = "sha256-QYV3DEFo1JeMzFlYf5/wxAfAsqP38g0XOoItKiKRr9w=";
  }
  {
    name = "antigravity-cli-only-mode";
    rev = "5826a41110039ef5a1fb77d5cdd832a3b841f490";
    hash = "sha256-PwY+IfZE4JNAXDK5G1yR5H0dHUAE2xVgnY1B1fsVKW0=";
  }
  {
    name = "antigravity-plan-mode";
    rev = "1282c23e9ac83d3169fe33a8c9ac28e76d7f6150";
    hash = "sha256-TVcUZpRUb6/vauKHs4lBHNOVPaarlQJoPIp1v9vbm4I=";
  }
  {
    name = "antigravity-test-stability";
    rev = "05732771522567aa1f961bcab62bfef6ac06e019";
    hash = "sha256-2U3h2yubETQxP52DPSHxCew5rqmZRZRNrMklfUJkFJs=";
  }
  {
    name = "first-message-domain-event-subscription";
    rev = "86d50beaa177ebfcd2866b94db52c13519290606";
    hash = "sha256-5fEarfhLrLS4eWMUU6dZKB8i0LL9C8jQEuWEGIPmE4k=";
  }
  {
    name = "fix-first-message-disappearing";
    rev = "6f0709718c348481263b3e585707b0bddfcb2ba9";
    hash = "sha256-Fi4HoWSRPQldXqaY3fXSe3+Qvd35s5L2sorcC6wU0aM=";
  }
  {
    name = "feat-web-text-scale";
    rev = "f3ba720c046e7953c76d0bba690475de6eb7c86f";
    hash = "sha256-nSNm4UBxJw9XMk6SpRs7jOc4tBdHxTo5j1ZD0+twgfY=";
  }
  {
    name = "fix-codex-session-start-timeout";
    rev = "883b413cd9cfbb428abafc9f2a877ca14a9e6795";
    hash = "sha256-5b5mRry2OF120R0pAAVKXT9TG2nAes+ZQb848nyTrNQ=";
  }
  {
    name = "fix-agent-queue-blocked-on-session-start";
    rev = "2a504ad066bd5ec1413905f0f71e906180e8ee98";
    hash = "sha256-47/DZa5bFipcdro3nxH8+bGgosc2l0006uqLj2v42Dc=";
  }
]
