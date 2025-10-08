#!/bin/bash
# Auto-update GitHub repository script

cd /Users/jimbermudez/Documents/PIDS/AWS-Architecture-and-Calculator-2025

# Add all changes
git add .

# Commit with timestamp and message
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
git commit -m "Auto-update: $TIMESTAMP - $1"

# Push to GitHub
git push

echo "✅ Successfully pushed updates to GitHub!"
