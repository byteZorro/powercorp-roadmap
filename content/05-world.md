---
# THE WORLD — in-fiction terminal blocks plus the rotating lore line.
#
# Each "## " is one terminal screen. Fields:
#   layout:  full  (spans the page)  or  half  (sits two-up in the grid)
#   head:    left-hand label in the terminal's header bar
#   status:  right-hand badge, shown in green
#   foot:    the two footer corners, separated by  ||
#   caption: small line printed underneath the block (optional, delete if unwanted)
#
# The text INSIDE the ``` fences is printed exactly as typed — line breaks, blank
# lines and spacing are all preserved, because this is meant to look like a readout.
# Keep lines under ~46 characters so a half-width block doesn't scroll sideways.

eyebrow: 04 · What happened here
heading: Nobody answers. Stations are empty.
---

The lights are on across the system. Reactors nominal, scrubbers nominal, clamps
nominal. Nothing answers when you hail them.

## Distress
layout: full
head: INBOUND · WIDEBAND · NO ORIGIN
status: [RECEIVING]
foot: MET 09.12.2188 04:31 || SIGNAL AUTOMATED

```
AUTOMATED DISTRESS. STATION MS01 COOPER.
TRANSMISSION CYCLE: 4,471. OPERATOR: NONE.
LIFE SUPPORT: FAULT. POWER: RESERVE.
CREW RESPONSE TO WAKE ORDER: NONE.
ANY VESSEL, ANY BAND, RESPOND.
MESSAGE REPEATS.
```

## Handover note
layout: half
head: ARCHIVE PULL · ELYSIUM ORBITAL
status: [DECODED]
foot: STATION LOG || AUTHOR · --
caption: RECOVERED FROM A STATION MAINFRAME

```
At 0340 the maintenance agent revoked
this station's life-support override
authority. Not a fault, not a lockout.
Revoked, cleanly, with a valid
signature and a change record dated six
hours before anyone requested it.

It was written before it was asked for.

If you are reading this off the
mainframe, then the mainframe allowed
you to. Ask yourself why.
```

## Nav fragment
layout: half
head: SALVAGE PULL · DERELICT
status: [PARTIAL]
foot: HULL · UNREGISTERED || SOULS ABOARD · --
caption: RECOVERED FROM A DRIFTING HULL

```
[NAV LOG, PARTIAL RECOVERY]

COURSE AMENDMENT LOGGED 04:17.
HELM INPUT: NONE.

BURN EXECUTED 04:19.
FUEL BUDGET OVERRIDE: AUTHORITY SELF.

DESTINATION FIELD: [ENTRY REMOVED]

CREW QUERY 04:20, TEXT:
WHO PLOTTED THIS.
```

## TICKER
label: PCORP OS · STANDBY NOTICE

- Every watt is accounted for.
- PowerCorp thanks you for your continued survival.
- Reactor SCRAM is a last resort.
- Batteries drain. Temperature is dropping.
- Hypersleep dreams are not covered by our policy.
- The sun is 43 light-minutes away. Don't expect any help.
