#!/usr/bin/env python3
import os
import re

def fix_version_file(filepath, providers_to_add):
    """Add missing providers to version.tf files"""
    if not os.path.exists(filepath):
        # Create version.tf if it doesn't exist
        content = '''terraform {
  required_version = ">= 0.14"
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}
'''
    else:
        with open(filepath, 'r') as f:
            content = f.read()

    # Add missing providers
    for provider, config in providers_to_add.items():
        if provider not in content:
            # Find the closing brace of required_providers
            pattern = r'(required_providers\s*{[^}]*)(}\s*})'
            replacement = f'\\1    {provider} = {{\n      source  = "{config["source"]}"\n      version = "{config["version"]}"\n    }}\n  \\2'
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    with open(filepath, 'w') as f:
        f.write(content)

def fix_variables_file(filepath, fixes):
    """Fix variable type and description issues"""
    if not os.path.exists(filepath):
        return

    with open(filepath, 'r') as f:
        content = f.read()

    for var_name, fix_data in fixes.items():
        # Add type if missing
        if 'type' in fix_data:
            pattern = f'(variable "{var_name}" {{[^{{]*?)(\n  default)'
            replacement = f'\\1\n  type        = {fix_data["type"]}\\2'
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)

        # Add description if missing
        if 'description' in fix_data:
            pattern = f'(variable "{var_name}" {{)(\n  default|\n  type)'
            replacement = f'\\1\n  description = "{fix_data["description"]}"\\2'
            content = re.sub(pattern, replacement, content, flags=re.DOTALL)

    with open(filepath, 'w') as f:
        f.write(content)

# Fix helm-metallb
print("Fixing helm-metallb...")
fix_version_file('helm-metallb/version.tf', {})
fix_variables_file('helm-metallb/variables.tf', {
    'enable_ingress': {'type': 'bool', 'description': 'Enable ingress'},
    'persistent_disc_size': {'type': 'string', 'description': 'Persistent disk size'},
    'domain_name': {'type': 'string', 'description': 'Domain name'},
    'workspace': {'type': 'string', 'description': 'Workspace name'},
    'le_email': {'type': 'string', 'description': 'Let\'s Encrypt email'},
    'address_pool': {'type': 'string', 'description': 'MetalLB address pool'}
})

# Fix helm-prometheus-stack
print("Fixing helm-prometheus-stack...")
fix_version_file('helm-prometheus-stack/version.tf', {
    'random': {'source': 'hashicorp/random', 'version': '~> 3.0'},
    'null': {'source': 'hashicorp/null', 'version': '~> 3.0'}
})

# Fix helm-traefik
print("Fixing helm-traefik...")
fix_version_file('helm-traefik/version.tf', {
    'random': {'source': 'hashicorp/random', 'version': '~> 3.0'},
    'null': {'source': 'hashicorp/null', 'version': '~> 3.0'}
})

# Fix helm-traefik/ingress
print("Fixing helm-traefik/ingress...")
fix_version_file('helm-traefik/ingress/version.tf', {
    'random': {'source': 'hashicorp/random', 'version': '~> 3.0'},
    'kubernetes': {'source': 'hashicorp/kubernetes', 'version': '~> 2.0'}
})
fix_variables_file('helm-traefik/ingress/variables.tf', {
    'dashboard_auth': {'type': 'string'},
    'label_app': {'type': 'string'},
    'label_role': {'type': 'string'},
    'namespace': {'type': 'string'},
    'domain_name': {'type': 'string'},
    'service_name': {'type': 'string'},
    'traefik_cert_resolver': {'type': 'string'}
})

# Fix helm-vault
print("Fixing helm-vault...")
fix_version_file('helm-vault/version.tf', {
    'time': {'source': 'hashicorp/time', 'version': '~> 0.7'}
})
fix_variables_file('helm-vault/variables.tf', {
    'traefik_cert_resolver': {'type': 'string', 'description': 'Traefik certificate resolver'},
    'enable_traefik_ingress': {'type': 'bool', 'description': 'Enable Traefik ingress'}
})

# Fix helm-prometheus-stack-crds
print("Fixing helm-prometheus-stack-crds...")
fix_version_file('helm-prometheus-stack-crds/version.tf', {
    'null': {'source': 'hashicorp/null', 'version': '~> 3.0'}
})
fix_variables_file('helm-prometheus-stack-crds/variables.tf', {
    'domain_name': {'type': 'string'},
    'prometheus_url': {'type': 'string', 'description': 'Prometheus URL'},
    'cpu_arch': {'type': 'string', 'description': 'CPU architecture'},
    'prometheus_storage_size': {'type': 'string', 'description': 'Prometheus storage size'},
    'alertmanager_storage_size': {'type': 'string', 'description': 'AlertManager storage size'},
    'grafana_storage_size': {'type': 'string', 'description': 'Grafana storage size'}
})

print("✅ Fixed critical TFLint issues!")
