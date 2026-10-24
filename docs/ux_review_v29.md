# BandMaster UX review — v2.9

Code-based heuristic review, not a substitute for observed player sessions or device screenshots.

## Pass 1: First-time band founder (mobile, 375px)
- **Problem:** next objective appeared after a large location grid, pushing the first useful action below the fold.
- **Change:** move *Your Next Move* ahead of *Your World*, shorten hero and tile imagery at compact widths.
- **Acceptance:** player sees a meaningful next action without passing the world grid.

## Pass 2: Returning manager (desktop, 1280px)
- **Problem:** generic ACTIONS/SCENE labels do not describe what changed through songwriting and releases.
- **Change:** STUDIO and CAREER labels in navigation, retaining internal tab ids and all save routing.
- **Acceptance:** navigation is understandable without knowing the game's implementation names.

## Pass 3: Touch/keyboard accessibility (320–560px)
- **Problem:** oversized art competes with choices, and two-column destination tiles become crowded on narrow devices.
- **Change:** responsive hero sizing, one-column destinations under 380px, navigational tooltips and explicit focus mode.
- **Acceptance:** both navigation and content insets remain valid at 320/375/390/430/560/768/1280 widths.

## Open visual gates
- Live desktop, 320/375/430px mobile screenshots and actual touch interaction review.
- Keyboard focus order and contrast verification.
- Long names, translation/large-font accessibility and panel overflow.
- Real-user usability sessions (personas here were *heuristic* simulations only).

No economy, career saves or deterministic gameplay mechanics changed.
