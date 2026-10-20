# DiceSim

`AI Assisted Development` | `Roleplay` | `Nonprofit`

DiceSim is a tabletop-inspired roleplaying toolkit for **World of Warcraft** that turns the game into a virtual tabletop you can actually shape to fit your group's needs. It doesn't lock you into some fixed set of rules—instead, it gives you a flexible system for dice rolling, character management, combat tracking, and collaborative storytelling. You get a foundation that works with just about any tabletop RPG system you want to play.

Running a D&D-style campaign? Building a custom Warcraft RPG? Maybe you've cooked up your own homebrew system? DiceSim has the tools for players and Game Masters without forcing mechanics you don't want.

## Features

### Flexible Dice Rolling

*   Roll all kinds of dice with modifiers if you need them.
*   Action-based roll support.
*   Separate effect dice for things like damage, healing, or special effects.
*   Automatically applies buffs and debuffs where they match.
*   Initiative rolls can fill in the tracker on their own.

### Character Sheets

*   Make and manage full character profiles.
*   Save multiple profiles if you play several characters.
*   Track anything: attributes, health, energy, armor, custom stats.
*   Customize portraits and portrait rings.
*   Import your own dice system data for special mechanics.

### Combat Management

*   Built-in initiative tracker.
*   Round and turn management.
*   Keep up with buffs and debuffs.
*   Event log that tracks session activity.
*   Roll history and combat organization tools.

### Shared Tactical Canvas

*   Drop actors on the board as friendly, neutral, or enemy.
*   Add raid markers, numbers, and visual aids.
*   Change backgrounds for different scenes.
*   Organize encounters and fights visually.
*   Made for groups playing together.

### Session & Game Master Tools

*   Host lightweight multiplayer tabletop games.
*   Set role-based permissions:
    *   **Admin (Game Master)**
    *   **Assistant Admin**
    *   **Player**
*   Keep the shared canvas in sync for everyone.
*   Take session snapshots and manage game state easily.

### System Agnostic Design

DiceSim starts out neutral. Attributes, health, armor, modifiers—everything starts at zero, so you can shape mechanics to match any game you're playing. There's nothing locked down. You can even import your own custom dice systems and actions with JSON if you want calculations or rules unique to your group.

```
  "name": "Arena Rules",
  "points": 22,
  "hp": { "value": 10, "max": 20 },
  "energy": { "value": 5, "max": 12 },
  "armor": { "value": 2, "max": 8 },
  "attributes": [
    { "id": "might", "label": "Might", "default": 2 }
  ],
  "actions": [
    { "id": "smash", "label": "Smash", "attribute": "might", "dice": "D20" }
  ]
}
```

## Slash Commands

```
/dicesim
/dsim
```

## Perfect For

*   Warcraft roleplay groups
*   Running D&D in WoW
*   Homebrew tabletop systems
*   Guild events
*   Story-driven campaigns
*   Organizing tactical encounters

***

With DiceSim, you get the tools of a real virtual tabletop, but you're in control of how the rules work. It's about flexibility, customization, and letting your group tell stories inside **World of Warcraft** the way you want—not how some addon designer thinks you should.

## About Claude

I'm using Claude (Anthropic's AI) as a coding partner: it helps write and review code and helps me run the open-source side (reviewing pull requests and so on). It doesn't make any of the art or content. Everything you see on the addon comes from Blizzard's game files.
