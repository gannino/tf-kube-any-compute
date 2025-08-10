# Configuration Examples

This directory contains example configurations for common deployment scenarios.

## 📁 Available Examples

- `raspberry-pi/` - ARM64 Raspberry Pi cluster setup
- `homelab/` - Mixed architecture homelab configuration
- `production/` - Production-ready cloud deployment
- `minimal/` - Minimal core services only
- `development/` - Development environment setup

## 🚀 Usage

1. Copy an example directory
2. Customize `terraform.tfvars`
3. Run `terraform init && terraform apply`

## 📋 Example Structure

Each example includes:
- `terraform.tfvars` - Main configuration
- `README.md` - Specific setup instructions
- `outputs.tf` - Expected outputs (if needed)

## 💡 Need Help?

- Check the main [README](../README.md)
- See [QUICK_START](../QUICK_START.md)
- Ask in [GitHub Discussions](https://github.com/gannino/tf-kube-any-compute/issues)
