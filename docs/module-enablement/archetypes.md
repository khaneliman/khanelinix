# Archetypes

Archetypes map high-level system profiles to suites.

## NixOS Archetypes

| Archetype   | Common | Desktop | Development | Games | VM | Wlroots | Special Services  |
| ----------- | ------ | ------- | ----------- | ----- | -- | ------- | ----------------- |
| workstation | ✅     | ✅      | ✅          | ❌    | ❌ | ❌      | -                 |
| personal    | ✅     | ❌      | ❌          | ❌    | ❌ | ❌      | tailscale         |
| gaming      | ✅     | ✅      | ❌          | ✅    | ❌ | ❌      | -                 |
| server      | ✅     | ❌      | ❌          | ❌    | ❌ | ❌      | -                 |
| vm          | ✅     | ✅      | ✅          | ❌    | ✅ | ❌      | -                 |
| wsl         | ❌     | ❌      | ❌          | ❌    | ❌ | ❌      | Custom WSL config |

## Darwin Archetypes

| Archetype   | Business | Common | Desktop | Development | Art | Music | Photo | Social | Video | VM |
| ----------- | -------- | ------ | ------- | ----------- | --- | ----- | ----- | ------ | ----- | -- |
| workstation | ✅       | ✅     | ✅      | ✅          | ❌  | ❌    | ❌    | ❌     | ❌    | ❌ |
| personal    | ❌       | ✅     | ❌      | ❌          | ✅  | ✅    | ✅    | ✅     | ✅    | ❌ |
| vm          | ❌       | ✅     | ✅      | ✅          | ❌  | ❌    | ❌    | ❌     | ❌    | ✅ |

## Usage Patterns

| Archetype       | Purpose                                    | Best For                      |
| --------------- | ------------------------------------------ | ----------------------------- |
| **Workstation** | Full development + desktop                 | Professional development work |
| **Personal**    | Basic system (NixOS) / multimedia (Darwin) | Home use, media consumption   |
| **Gaming**      | Desktop + gaming optimization              | Gaming systems                |
| **Server**      | Minimal system only                        | Headless servers              |
| **VM**          | Desktop + development + VM services        | Virtual machine guests        |
| **WSL**         | Windows subsystem optimization             | Windows development           |
