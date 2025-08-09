#!/bin/bash

# Post-Release Tasks Script for Terraform Module
# Usage: ./scripts/post-release.sh [version]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARN]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_step() { echo -e "${BLUE}[STEP]${NC} $1"; }

# Function to get latest version
get_latest_version() {
    git tag --list --sort=-version:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' | head -n1 | sed 's/^v//'
}

# Function to check Terraform Registry status
check_registry_status() {
    local version="$1"
    local module_name="${2:-tf-kube-any-compute}"
    
    print_step "Checking Terraform Registry status..."
    
    # Get repository info for registry URL construction
    local repo_url
    if repo_url=$(git config --get remote.origin.url); then
        # Extract owner/repo from URL
        local owner_repo
        if [[ "$repo_url" =~ github\.com[:/]([^/]+/[^/]+) ]]; then
            owner_repo="${BASH_REMATCH[1]}"
            owner_repo="${owner_repo%.git}"
            
            local registry_url="https://registry.terraform.io/modules/${owner_repo}"
            echo
            print_status "📦 Terraform Registry URL: $registry_url"
            print_status "⏳ Note: Registry updates may take 24-48 hours to appear"
            
            # Check if module is already published
            if command -v curl &> /dev/null; then
                local http_status
                http_status=$(curl -s -o /dev/null -w "%{http_code}" "$registry_url" || echo "000")
                
                if [[ "$http_status" == "200" ]]; then
                    print_status "✅ Module is already published in Terraform Registry"
                elif [[ "$http_status" == "404" ]]; then
                    print_warning "⏳ Module not yet available in Registry (first-time publish or propagation delay)"
                    echo "   Manual submission may be required: https://registry.terraform.io/github/create"
                else
                    print_warning "⚠️  Registry status unclear (HTTP $http_status)"
                fi
            fi
        fi
    fi
}

# Function to verify GitHub release
verify_github_release() {
    local version="$1"
    local tag="v$version"
    
    print_step "Verifying GitHub release..."
    
    # Check if gh CLI is available
    if ! command -v gh &> /dev/null; then
        print_warning "GitHub CLI not available, skipping release verification"
        return 0
    fi
    
    # Check if release exists
    if gh release view "$tag" > /dev/null 2>&1; then
        print_status "✅ GitHub release $tag exists"
        
        # Get release URL
        local release_url
        release_url=$(gh release view "$tag" --json url --jq '.url')
        print_status "🔗 Release URL: $release_url"
    else
        print_error "❌ GitHub release $tag not found"
        print_warning "Create manually or re-run: ./scripts/release.sh"
        return 1
    fi
}

# Function to generate community announcement
generate_community_announcement() {
    local version="$1"
    local announcement_file="$PROJECT_ROOT/release-announcement-v${version}.md"
    
    print_step "Generating community announcement..."
    
    cat > "$announcement_file" << EOF
# 🎉 Release Announcement: tf-kube-any-compute v${version}

## 🚀 New Release Available!

We're excited to announce the release of **tf-kube-any-compute v${version}**!

### 📦 Installation

\`\`\`hcl
module "k8s_infrastructure" {
  source  = "gannino/tf-kube-any-compute//[provider]"
  version = "${version}"
  
  # Your configuration here
}
\`\`\`

### 🔗 Links

- **📚 Documentation**: [README.md](./README.md)
- **📋 Changelog**: [CHANGELOG.md](./CHANGELOG.md)
- **🐙 GitHub Release**: [v${version}](https://github.com/gannino/tf-kube-any-compute/releases/tag/v${version})
- **📦 Terraform Registry**: [Registry Link](https://registry.terraform.io/modules/[your-module])

### 🤝 Contributing

We welcome contributions! See our [Contributing Guide](./CONTRIBUTING.md) for details.

### 📢 Share the News

- ⭐ Star the repository
- 🐦 Share on Twitter/LinkedIn
- 💬 Join discussions in Issues
- 🔄 Share with your team

---

**Thank you to all contributors who made this release possible!** 🙏

EOF

    print_status "✅ Community announcement created: $announcement_file"
    
    # Show the announcement
    echo
    print_step "Preview of community announcement:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    cat "$announcement_file"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Function to create LinkedIn post
generate_linkedin_post() {
    local version="$1"
    local linkedin_file="$PROJECT_ROOT/linkedin-post-v${version}.md"
    
    print_step "Generating LinkedIn post..."
    
    cat > "$linkedin_file" << EOF
🎉 **New Release Alert!** 🎉

Just shipped **tf-kube-any-compute v${version}** - making enterprise-grade Kubernetes infrastructure accessible to everyone! 🚀

🔥 **What's New in v${version}:**
• [Highlight key features from CHANGELOG]
• [Performance improvements]
• [Bug fixes and stability enhancements]

💡 **Why This Matters:**
From Raspberry Pi homelabs to enterprise cloud deployments, this Terraform module provides production-ready infrastructure with zero-destroy deployments and intelligent architecture detection.

🎯 **Perfect For:**
• DevOps Engineers building multi-cloud infrastructure
• Homelab enthusiasts wanting professional setups
• Teams needing rapid Kubernetes environment provisioning
• Anyone learning modern infrastructure patterns

📦 **Get Started:**
\`\`\`bash
git clone https://github.com/gannino/tf-kube-any-compute.git
terraform apply
\`\`\`

🤝 **Community:**
• 🌟 Star: https://github.com/gannino/tf-kube-any-compute
• 📚 Docs: Comprehensive guides included
• 💬 Contribute: We welcome all skill levels!

#DevOps #Kubernetes #Terraform #Infrastructure #CloudNative #Homelab #OpenSource

**What's your favorite Kubernetes deployment challenge? Let's solve it together!** 💭

EOF

    print_status "✅ LinkedIn post created: $linkedin_file"
}

# Function to generate Twitter thread
generate_twitter_thread() {
    local version="$1"
    local twitter_file="$PROJECT_ROOT/twitter-thread-v${version}.md"
    
    print_step "Generating Twitter thread..."
    
    cat > "$twitter_file" << EOF
# Twitter Thread for v${version} Release

## Tweet 1/5 (Main announcement)
🚀 Just released tf-kube-any-compute v${version}! 

Production-grade #Kubernetes infrastructure from Raspberry Pi to Enterprise Cloud with a single Terraform module.

✅ Zero-destroy deployments
✅ ARM64/AMD64 intelligent placement  
✅ 14 integrated services
✅ Enterprise security

🧵 Thread 👇

## Tweet 2/5 (Technical highlights)
What makes v${version} special:

🔧 Smart architecture detection
🛡️ Auto-generated secure passwords
📊 Complete monitoring stack (Prometheus/Grafana)
🔐 Service mesh ready (Consul/Vault)
🌐 Production ingress (Traefik + Let's Encrypt)

Perfect for both learning and production!

## Tweet 3/5 (Use cases)
Real-world use cases:

🏠 Homelab heroes: Turn your Pi cluster into enterprise infrastructure
☁️ Cloud engineers: Consistent deployments across AWS/GCP/Azure
🎓 Students: Learn modern DevOps with working examples
🏢 Teams: Rapid environment provisioning

## Tweet 4/5 (Community)
Built by the community, for the community! 🤝

🌟 Star the repo: https://github.com/gannino/tf-kube-any-compute
📚 Full documentation included
🐛 Issues welcome
💡 Feature requests encouraged
🚀 Contributors get recognition

#OpenSource #DevOps #Terraform

## Tweet 5/5 (Call to action)
Ready to revolutionize your infrastructure game?

📦 Get started: https://github.com/gannino/tf-kube-any-compute
📖 Read the docs
🧪 Try the examples
💬 Join the discussion

What infrastructure challenge should we solve next? Drop your ideas below! 👇

#Kubernetes #Infrastructure #HomeLab #CloudNative

EOF

    print_status "✅ Twitter thread created: $twitter_file"
}

# Function to update documentation links
update_documentation_links() {
    local version="$1"
    
    print_step "Checking documentation links..."
    
    # Check if README mentions version-specific information that needs updating
    if grep -q "version.*=" "$PROJECT_ROOT/README.md"; then
        print_warning "README.md may contain version references to update"
        print_warning "Please review and update any version-specific examples"
    fi
    
    # Check terraform.tfvars.example for version references
    if [[ -f "$PROJECT_ROOT/terraform.tfvars.example" ]]; then
        if grep -q "version.*=" "$PROJECT_ROOT/terraform.tfvars.example"; then
            print_warning "terraform.tfvars.example may need version updates"
        fi
    fi
}

# Function to schedule follow-up tasks
schedule_follow_up_tasks() {
    local version="$1"
    local follow_up_file="$PROJECT_ROOT/follow-up-tasks-v${version}.md"
    
    print_step "Creating follow-up task list..."
    
    cat > "$follow_up_file" << EOF
# Follow-up Tasks for v${version} Release

## Immediate Tasks (Next 24 hours)
- [ ] Verify Terraform Registry publication
- [ ] Post community announcement on GitHub Discussions
- [ ] Share LinkedIn post
- [ ] Post Twitter thread
- [ ] Update any external documentation references

## Short-term Tasks (Next week)
- [ ] Monitor GitHub issues for v${version} reports
- [ ] Update any tutorial content with new version
- [ ] Respond to community feedback
- [ ] Plan next release based on feedback

## Medium-term Tasks (Next month)
- [ ] Analyze v${version} adoption metrics
- [ ] Gather feature requests for next release
- [ ] Review and update roadmap
- [ ] Plan community engagement activities

## Registry and Distribution
- [ ] Confirm Terraform Registry shows v${version}
- [ ] Verify module examples work with new version
- [ ] Update any partner/integration documentation
- [ ] Check automated dependency update PRs

## Community Engagement
- [ ] Highlight notable community contributions
- [ ] Plan contributor recognition
- [ ] Schedule community calls if needed
- [ ] Update contributor documentation

## Metrics to Track
- [ ] Download/usage statistics
- [ ] GitHub stars/forks growth
- [ ] Community issue resolution time
- [ ] New contributor onboarding success

---

**Generated on**: $(date)
**Version**: v${version}
**Next Review**: $(date -d '+1 week' 2>/dev/null || date -v+1w 2>/dev/null || echo 'In 1 week')

EOF

    print_status "✅ Follow-up tasks created: $follow_up_file"
}

# Function to run comprehensive post-release tasks
run_post_release_tasks() {
    local version="$1"
    
    print_status "Running post-release tasks for v$version..."
    echo
    
    # Verify release exists
    verify_github_release "$version"
    
    # Check registry status
    check_registry_status "$version"
    
    # Generate community content
    generate_community_announcement "$version"
    generate_linkedin_post "$version"
    generate_twitter_thread "$version"
    
    # Update documentation
    update_documentation_links "$version"
    
    # Schedule follow-up
    schedule_follow_up_tasks "$version"
    
    echo
    print_status "🎉 Post-release tasks completed for v$version!"
    
    # Show summary
    cat << EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 **Next Steps Summary**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🔗 **Verification Links**:
   • GitHub Release: https://github.com/gannino/tf-kube-any-compute/releases/tag/v${version}
   • Terraform Registry: https://registry.terraform.io/modules/[your-module]

📢 **Content Created**:
   • Community announcement: release-announcement-v${version}.md
   • LinkedIn post: linkedin-post-v${version}.md  
   • Twitter thread: twitter-thread-v${version}.md
   • Follow-up tasks: follow-up-tasks-v${version}.md

⏰ **Timeline**:
   • Now: Share announcement content
   • 24h: Verify registry publication
   • 1 week: Monitor community feedback
   • 1 month: Plan next release

🤝 **Community Engagement**:
   • Post announcements on social media
   • Respond to GitHub issues/discussions
   • Monitor for adoption and feedback
   • Plan contributor recognition

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

EOF
}

# Function to show usage
show_usage() {
    cat << EOF
Post-Release Tasks for Terraform Module

Usage: $0 [version]

Arguments:
  version       Version to process (optional, auto-detects latest)

Examples:
  $0           # Process latest released version
  $0 2.0.1     # Process specific version

This script:
  ✓ Verifies GitHub release exists
  ✓ Checks Terraform Registry status
  ✓ Generates community announcements
  ✓ Creates social media content
  ✓ Updates documentation links
  ✓ Schedules follow-up tasks

EOF
}

# Main function
main() {
    local version="${1:-}"
    
    if [[ "$version" == "--help" || "$version" == "-h" ]]; then
        show_usage
        exit 0
    fi
    
    # Check if we're in a git repository
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        print_error "Not in a git repository"
        exit 1
    fi
    
    # Auto-detect version if not provided
    if [[ -z "$version" ]]; then
        version=$(get_latest_version)
        if [[ -z "$version" ]]; then
            print_error "No released versions found and no version specified"
            exit 1
        fi
        print_status "Auto-detected latest version: v$version"
    fi
    
    # Run post-release tasks
    run_post_release_tasks "$version"
}

# Run main function
main "$@"
