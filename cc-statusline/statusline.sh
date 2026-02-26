#!/bin/bash
# Wrapper to invoke TypeScript statusline script
# For Claude Code Router support, use ccr-statusline.ts instead
exec npx tsx "$(dirname "$0")/ccr-statusline.ts"
