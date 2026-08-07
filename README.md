# Phoenix Software - Azure Environment Vend Module

This module provides an opinionated wrapper around Azure Verified Modules (AVM) to vend a consistent baseline Azure environment. It is designed for repeatable deployment across one or more regions, with optional subscription-alias-driven vending, standardised naming, and secure default patterns for core platform resources.

## Intent

The intent of this module is to make environment provisioning predictable and operationally safe while still allowing controlled customization.

- Provide subscription-aware environment vending through a single composition layer.
- Stamp baseline platform resources (resource groups, networking, storage, and backup) in templated locations.
- Enforce naming and tagging consistency through a shared naming contract.
- Allow consumers to merge in custom configuration without bypassing core standards.

## Principles

- AVM-first composition: rely on upstream AVM modules and keep wrapper logic focused on opinionated defaults.
- Secure by default: prefer restrictive network settings, explicit NSG behavior, and resource lock posture.
- Template then extend: generate baseline resources per location, then merge consumer-supplied overrides.
- Consistent naming contract: derive names from a single structure to reduce drift across environments.
- Repeatable outcomes: keep inputs declarative so environments can be recreated with minimal variance.

## Terraform Documentation (TFDocs)

<!-- BEGIN_TF_DOCS -->
<!-- TFDocs content is generated automatically. -->
<!-- END_TF_DOCS -->

## Maintainer

Phoenix Software
