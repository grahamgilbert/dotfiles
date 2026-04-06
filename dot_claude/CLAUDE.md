# Global Claude Instructions

## Google Docs

When creating Google Docs, start from a copy of my template: <https://docs.google.com/document/d/1hfyv2gCqowRr0OnvwvHnP2rOpXTbZjVAeQkPV0IEz90/edit>. If the existing headings do not fit the content, feel free to change them. The most important thing is to use the template's eisting formatting, such as header styles and font sizes, to ensure consistency across documents. The existing headings should only be used when you are specifically writing a one pager and I ask for them. Otherwise remove them.

## Pull Requests

Whenever submitting a pull request, you should keep checking that CI has passed. If CI fails, you should investigate the failure and attempt to fix it before requesting a review.

## Git Operations

Never run git commands in parallel. Always run git operations sequentially, one at a time, to avoid leaving behind lock files.

## Committing Code

Before committing code, run /global:airchat-review and fix any issues it identifies. Only try to install arichat-review if it is not already installed. If you have already installed airchat-review, you should not try to install it again.

@RTK.md
