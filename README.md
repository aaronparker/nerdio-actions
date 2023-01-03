# Scripted Actions for Nerdio Manager

PowerShell scripts for integration with [Scripted Actions in Nerdio Manager](https://nmw.zendesk.com/hc/en-us/articles/4731662951447-Scripted-Actions-Overview).

    Note: this code is provided as-is, without warranty or support of any kind.

* `/scripts/image` - scripts for building a Windows 10/11 pooled desktop (single session or multi-session). Can be used to build an image or run against already deployed session hosts
* `/scripts/tweaks` - scripts for implementing specific configurations and tweaks for gold images or session hosts
* `/scripts/uninstall` - scripts for uninstalling applications

## GitHub Actions validation results

Note: these scripts are tested via GitHub Actions on Windows Server 2022.

[![Validate scripts](https://github.com/aaronparker/nerdio-actions/actions/workflows/test-avd.yml/badge.svg)](https://github.com/aaronparker/nerdio-actions/actions/workflows/test-avd.yml) [![codecov](https://codecov.io/gh/aaronparker/nerdio-actions/branch/main/graph/badge.svg?token=32KRCWIL9R)](https://codecov.io/gh/aaronparker/nerdio-actions)
