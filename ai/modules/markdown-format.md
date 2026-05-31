## Markdown prose — no hard wrapping

Write prose in `.md` documents as one logical line per paragraph. Do NOT hard-wrap paragraphs at a fixed column width — no embedded mid-paragraph line breaks. Hard wrapping corrupts rendering in GitHub issue and PR bodies, breaks screen-reader flow, and produces noisy diffs where editing one word reflows an entire block. Let the editor and renderer soft-wrap. It is not 1999.

Applies to anything you author or post: issue and PR bodies, READMEs, design docs, plans, memory files, and any `.md` meant to be read or rendered. One line per paragraph; one line per list item; a blank line between blocks.

Structural breaks are fine and expected — between list items, between table rows, around headings, and inside fenced code blocks. The rule targets breaks *within* a paragraph or bullet, not breaks *between* blocks.

This governs documents you author from now on. Do not blanket-reflow existing hard-wrapped files; fix them opportunistically when you are already editing them, or on explicit request.
