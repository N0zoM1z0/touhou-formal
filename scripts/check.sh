#!/usr/bin/env bash
set -euo pipefail

lake build
lake exe check
