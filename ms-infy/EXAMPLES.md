## Examples: create multiple VNets and NSGs ✅

This repo supports creating multiple VNets and multiple NSGs. The key points are:

- `virtual_networks` is a nested map: outer group -> vnet name -> vnet config. The module iterates over vnet names (they are used as `module.vnet["<vnet_name>"]`).
-- `nsg_configs` is a map keyed by a unique logical name (e.g. `nsg_alpha`, `nsg_beta`). Use `create = true` to create an NSG, or `create = false` with `existing_nsg_name` / `existing_nsg_id` to reference an existing NSG.
- `nsg_associations` attaches a single NSG to a single subnet. Each entry contains `vnet_key` (vnet name), `subnet_key` (subnet name), and `nsg_key` (the NSG key that exists in `nsg_configs`). Keys must be unique in each map.

Minimal flow to add more NSGs/VNets:
1. Add another vnet entry under `virtual_networks` (ensure the vnet name is unique).
2. Add another entry into `nsg_configs` with a unique key and `create = true` (or set existing reference fields for an imported NSG and `create = false`).
3. Create an assoc entry in `nsg_associations` pointing the subnet to the NSG.

See `ms-infy/locals.tf` for a working sample of defaults that create two VNets and two NSGs and attach them to subnets. Note that the locals use resource-specific `create` flags for VNets, Subnets, and NSGs to control creation/import behavior; **associations are created when an entry exists in `nsg_associations` — removing the entry will remove the association.**

Note about environment defaults:

- This repo uses `ms-infy/locals.tf` as the source of environment defaults for quick iteration and local testing. CI workflows run without `.tfvars` and rely on the module's locals by default.

If you need to override specific values temporarily, use explicit `-var 'name=value'` on the CLI or set `TF_VAR_*` environment variables in CI.
