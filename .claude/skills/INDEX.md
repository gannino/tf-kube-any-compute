# Claudify Skills Library

> 1,734 skills across 31 categories, every one scored by the deterministic /skills-audit rubric.
> Tier counts below are generated at build time from the audit, never hand-typed.

## How Skills Work

Skills load automatically when Claude detects a relevant task. DEEP-tier skills
are additionally user-invocable as slash entries; scaffold-tier skills stay out
of the slash menu and load by model invocation only.

Tier meanings: DEEP = scored 85+ with a binary eval, the deliverable is the
output. STANDARD = 60 to 84. SHALLOW = structured scaffold, labeled as such.
BROKEN = unreachable or invalid, queued for prune. Rerun the numbers yourself
any time with /skills-audit.

## Categories

| Category | Skills | DEEP | STANDARD | SHALLOW | Description |
|----------|--------|------|----------|---------|-------------|
| [Content & Copywriting](./content/) | 88 | 2 | 0 | 82 | Written content creation across all formats, blog posts, whitepapers, landing pages, scripts, and more |
| [Software Development](./development/) | 78 | 3 | 0 | 75 | Code quality, architecture, testing, CI/CD, documentation, debugging, and engineering practices |
| [Marketing & Advertising](./marketing/) | 76 | 3 | 0 | 73 | Campaign strategy, audience research, brand positioning, and advertising across all channels |
| [Social Media](./social-media/) | 69 | 0 | 0 | 69 | Platform-specific content creation, scheduling, engagement, and analytics for all major social platforms |
| [Sales & Revenue](./sales/) | 66 | 2 | 0 | 64 | Sales strategy, prospecting, outreach, negotiation, pipeline management, and revenue operations |
| [Product Management](./product/) | 63 | 2 | 0 | 61 | Product strategy, roadmaps, user research, prioritization, and product operations |
| [Finance & Accounting](./finance/) | 60 | 2 | 0 | 58 | Financial modeling, budgeting, forecasting, pricing, and financial reporting |
| [Operations & Project Management](./operations/) | 60 | 0 | 0 | 60 | Process design, project planning, resource management, and operational excellence |
| [Startup & Entrepreneurship](./startup/) | 60 | 2 | 0 | 58 | Business planning, fundraising, validation, growth, and startup operations |
| [Personal Productivity](./productivity/) | 58 | 0 | 1 | 57 | Time management, goal setting, decision making, communication, and personal effectiveness |
| [Data & Analytics](./data/) | 57 | 1 | 0 | 56 | Data analysis, visualization, reporting, BI dashboards, and data strategy |
| [HR & People](./hr/) | 57 | 1 | 0 | 56 | Hiring, onboarding, performance management, culture, training, and employee experience |
| [SEO & Search](./seo/) | 57 | 1 | 0 | 56 | Search engine optimization, keyword research, on-page, technical, link building, local SEO, and analytics |
| [AI & Automation](./ai-automation/) | 54 | 0 | 0 | 54 | AI implementation, prompt engineering, workflow automation, and AI strategy |
| [Consulting & Strategy](./consulting/) | 54 | 0 | 0 | 54 | Strategy frameworks, market analysis, client engagement, and advisory services |
| [Design & Creative](./design/) | 54 | 0 | 0 | 53 | Design briefs, brand identity, UX/UI, creative direction, and visual design processes |
| [E-commerce](./ecommerce/) | 54 | 0 | 0 | 54 | Online store management, product listings, conversion optimization, and marketplace strategy |
| [Legal & Compliance](./legal/) | 54 | 0 | 0 | 54 | Contracts, policies, compliance frameworks, and legal documentation |
| [Travel & Hospitality](./travel/) | 54 | 0 | 0 | 54 | Trip planning, hospitality operations, guest experience, and travel content |
| [Healthcare](./healthcare/) | 53 | 0 | 12 | 41 | Patient communication, practice management, compliance, wellness programs, and health content |
| [Education & Training](./education/) | 51 | 0 | 0 | 51 | Course creation, curriculum design, assessment, workshops, and learning management |
| [Email Marketing](./email/) | 51 | 1 | 0 | 50 | Email campaigns, automation, sequences, deliverability, and subscriber management |
| [Customer Success & Support](./customer-success/) | 48 | 0 | 0 | 48 | Customer onboarding, retention, support operations, and customer experience |
| [Nonprofit & Social Impact](./nonprofit/) | 48 | 0 | 0 | 48 | Fundraising, grant writing, volunteer management, and nonprofit operations |
| [Agriculture & Farming](./agriculture/) | 45 | 0 | 0 | 45 | Farm planning, crop management, livestock, and agricultural business operations |
| [Energy & Sustainability](./energy/) | 45 | 0 | 0 | 45 | Energy management, sustainability reporting, environmental compliance, and green initiatives |
| [Fitness & Wellness](./fitness-wellness/) | 45 | 0 | 0 | 45 | Program design, client management, wellness coaching, and fitness business operations |
| [Media & Publishing](./media/) | 45 | 0 | 0 | 45 | Content publishing, editorial management, media production, and audience growth |
| [Real Estate](./real-estate/) | 45 | 0 | 0 | 45 | Property listings, market analysis, investment analysis, and real estate operations |
| [Construction & Trades](./construction/) | 42 | 0 | 0 | 42 | Project estimation, safety compliance, client management, and trade operations |
| [Food & Beverage](./food-beverage/) | 42 | 0 | 0 | 42 | Restaurant operations, menu design, food safety, and hospitality management |

## Quick Start

1. Ask Claude to perform the task; matching skills load automatically
2. DEEP-tier skills can also be invoked directly as slash entries
3. Skills read your project context automatically
4. Run /skills-audit for the scored report on your installed library

## Quality Standard

Every skill carries a version field and a generated, audited tier. DEEP-tier
skills ship with worked examples, a real artifact output block, and at least
one binary eval that fails the build if the skill stops producing its artifact.
