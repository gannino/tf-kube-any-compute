# 🤖 AI Contribution Prompts for tf-kube-any-compute

This directory contains specialized AI prompts designed to help contributors work effectively with the `tf-kube-any-compute` project using different AI models.

## 📋 **Available Prompts**

### 🧠 **[GPT-4 Contribution Prompt](GPT4-CONTRIBUTION-PROMPT.md)**

**Best for**: Structured development, analytical problem-solving, and systematic implementation

**When to use**:

- Complex Terraform module development
- Architecture analysis and optimization
- Systematic testing and validation
- Technical documentation and best practices

**Strengths**:

- Methodical approach to infrastructure design
- Pattern recognition and consistency
- Comprehensive testing frameworks
- Technical excellence and documentation

---

### 📘 **[Claude Sonnet 4 Contribution Prompt](CLAUDE-CONTRIBUTION-PROMPT.md)**

**Best for**: Comprehensive analysis, systematic execution, and quality assurance

**When to use**:

- Deep codebase analysis and refactoring
- Step-by-step development methodology
- Quality gates and validation procedures
- Community collaboration and documentation

**Strengths**:

- Thorough understanding of existing patterns
- Systematic and methodical development
- Rigorous testing and validation
- Excellence in documentation and guides

---

### 🎨 **[Gemini Contribution Prompt](GEMINI-CONTRIBUTION-PROMPT.md)**

**Best for**: Creative innovation, multi-perspective thinking, and community-driven development

**When to use**:

- Innovative infrastructure solutions
- Creative problem-solving approaches
- Community engagement and education
- Multi-perspective analysis (homelab, enterprise, learning)

**Strengths**:

- Creative and innovative approaches
- Multi-perspective thinking and analysis
- Visual learning and community focus
- Educational content and user experience

---

### 🏠 **[Ollama Contribution Prompt](OLLAMA-CONTRIBUTION-PROMPT.md)**

**Best for**: Local development, privacy-focused solutions, and resource optimization

**When to use**:

- ARM64/Raspberry Pi optimization and debugging
- Offline development and air-gapped environments
- Privacy-conscious infrastructure solutions
- Resource-constrained optimization

**Strengths**:

- Local, offline-first development approach
- Deep understanding of homelab constraints
- Privacy and security-focused solutions
- Resource efficiency and ARM64 optimization

---

### 🔍 **[DeepSeek Contribution Prompt](DEEPSEEK-CONTRIBUTION-PROMPT.md)**

**Best for**: Advanced analysis, mathematical optimization, and complex problem-solving

**When to use**:

- Complex architecture analysis and optimization
- Mathematical resource allocation modeling
- Advanced performance tuning and benchmarking
- Sophisticated debugging and troubleshooting

**Strengths**:

- Deep mathematical and systems analysis
- Advanced optimization algorithms
- Complex problem decomposition
- Performance modeling and prediction

## 🚀 **How to Use These Prompts**

### **1. Choose Your AI Model**

Select the prompt that matches your preferred AI assistant:

- **GPT-4/ChatGPT**: Use `GPT4-CONTRIBUTION-PROMPT.md`
- **Claude (Anthropic)**: Use `CLAUDE-CONTRIBUTION-PROMPT.md`
- **Gemini (Google)**: Use `GEMINI-CONTRIBUTION-PROMPT.md`
- **Ollama (Local AI)**: Use `OLLAMA-CONTRIBUTION-PROMPT.md`
- **DeepSeek**: Use `DEEPSEEK-CONTRIBUTION-PROMPT.md`

### **2. Copy the Entire Prompt**

Copy the complete content of your chosen prompt file and paste it into your AI chat session.

### **3. Provide Context**

After loading the prompt, provide specific context about what you want to work on:

```
I want to [your specific task]:
- Add support for ArgoCD deployment
- Optimize resource usage for Raspberry Pi clusters  
- Implement new storage backend integration
- Fix architecture detection logic
- Improve documentation for mixed clusters
```

### **4. Follow the AI's Guidance**

Each prompt includes:

- **Project understanding** and context
- **Quality standards** and requirements
- **Testing procedures** and validation steps
- **Contribution workflow** and best practices

## 🎯 **Contribution Scenarios**

### **🔧 Technical Development**

```
"I need to add support for a new Helm chart service while maintaining 
compatibility with ARM64 Raspberry Pi clusters and AMD64 cloud environments."

Recommended: GPT-4 or Claude Sonnet 4 prompts
```

### **🏗️ Architecture Enhancement**

```
"I want to improve the mixed-cluster architecture detection and service 
placement logic to better handle edge cases."

Recommended: Claude Sonnet 4 or GPT-4 prompts
```

### **🎨 Creative Solutions**

```
"I need innovative approaches to optimize resource usage and improve 
the homelab user experience with better monitoring dashboards."

Recommended: Gemini prompt
```

### **📚 Documentation & Community**

```
"I want to create comprehensive guides for different deployment scenarios 
and improve the onboarding experience for new contributors."

Recommended: Gemini or Claude Sonnet 4 prompts
```

## 🧪 **Testing Integration**

All prompts emphasize the importance of testing. After implementing changes, always run:

```bash
# Quick validation
make test-safe              # Lint + validate + unit + scenarios

# Comprehensive testing  
make test-all              # Complete test suite including integration

# Specific test types
make test-unit             # Configuration logic testing
make test-scenarios        # Architecture and deployment testing
make test-integration      # Live infrastructure validation
```

## 📖 **Prompt Structure**

Each prompt includes:

1. **🎯 System Role & Context**: Project overview and AI assistant role
2. **🏗️ Architecture & Philosophy**: Design principles and target environments
3. **📋 Current Status**: Completed features and ongoing development
4. **🛠️ Contribution Standards**: Code quality, testing, and workflow requirements
5. **🚀 Development Process**: Step-by-step contribution methodology
6. **🎯 Focus Areas**: Current priorities and improvement opportunities

## 🤝 **Community Collaboration**

These prompts are designed to:

- **Maintain consistency** across different AI-assisted contributions
- **Ensure quality** through standardized testing and validation
- **Facilitate learning** by providing comprehensive project context
- **Support different working styles** through model-specific optimizations

## 💡 **Tips for Effective Use**

### **Start with Project Understanding**

Always begin by asking the AI to analyze the current codebase and understand existing patterns before making changes.

### **Test Incrementally**

Make small, testable changes rather than large modifications. Use the testing framework to validate each step.

### **Follow Established Patterns**

Maintain consistency with existing configuration patterns, naming conventions, and architectural decisions.

### **Document Everything**

Update README files, variable descriptions, and example configurations for any new features or changes.

### **Consider All Environments**

Test changes across Raspberry Pi (ARM64), cloud (AMD64), and mixed architecture scenarios.

## 🔄 **Continuous Improvement**

These prompts are living documents that evolve with the project. If you find ways to improve them:

1. **Open an issue** to discuss potential improvements
2. **Submit a pull request** with enhanced prompt content
3. **Share feedback** on effectiveness and usability
4. **Suggest new scenarios** or use cases

## 📞 **Support**

If you have questions about using these prompts or need help with your contributions:

- **📋 Issues**: [Project Issues](https://github.com/gannino/tf-kube-any-compute/issues)
- **💭 Discussions**: [Project Discussions](https://github.com/gannino/tf-kube-any-compute/discussions)
- **📚 Main Documentation**: [Project README](../README.md)

---

**Happy Contributing! 🚀**

*These prompts help ensure that AI-assisted contributions maintain the high quality and standards expected in the tf-kube-any-compute project.*
