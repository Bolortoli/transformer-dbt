# GitHub Repository Setup Guide

This guide provides step-by-step instructions for setting up the transformer-dbt project on GitHub to enable collaboration with your data engineering team.

## 🚀 Prerequisites

Before starting, ensure you have:
- Git installed on your local machine
- A GitHub account with appropriate permissions
- Command line access to your project directory

## 📋 Step-by-Step Setup

### 1. Initialize Git Repository

Navigate to your transformer-dbt directory and initialize Git:

```bash
cd transformer-dbt
git init
```

### 2. Review Files to be Committed

Check what files will be included (should exclude sensitive files thanks to .gitignore):

```bash
git status
```

**Expected files to be tracked:**
- ✅ `README.md`, `CONTRIBUTING.md`, `GITHUB_SETUP.md`
- ✅ `dbt_project.yml`, `packages.yml`, `requirements.txt`
- ✅ All SQL models in `models/` directory
- ✅ Schema files (`schema.yml`, `sources.yml`)
- ✅ Deployment scripts (`deploy.sh`, `scheduler.sh`, `cloud-deploy.sh`)

**Files that should NOT be tracked (excluded by .gitignore):**
- ❌ `.env` (contains credentials)
- ❌ `profiles.yml` (contains database connections)
- ❌ `target/` directory (build artifacts)
- ❌ `logs/` directory (log files)
- ❌ `.venv/` directory (Python virtual environment)

### 3. Create Initial Commit

Stage all files and create your initial commit:

```bash
git add .
git commit -m "Initial commit: Add dbt transformer project

- Add comprehensive README with setup instructions
- Include all dbt models (staging and marts layers)
- Add deployment and scheduling scripts
- Configure .gitignore for sensitive files
- Add CONTRIBUTING guidelines for collaboration"
```

### 4. Create GitHub Repository

#### Option A: Using GitHub CLI (Recommended)

If you have GitHub CLI installed:

```bash
# Install GitHub CLI if not already installed
# macOS: brew install gh
# Windows: winget install --id GitHub.cli

# Authenticate with GitHub
gh auth login

# Create repository (replace 'your-org' with your GitHub organization)
gh repo create your-org/transformer-dbt --public --description "dbt transformation project for Shoppy data warehouse"

# Push to GitHub
git branch -M main
git remote add origin https://github.com/your-org/transformer-dbt.git
git push -u origin main
```

#### Option B: Using GitHub Web Interface

1. **Go to GitHub.com** and sign in to your account
2. **Click the "+" icon** in the top right corner
3. **Select "New repository"**
4. **Configure the repository:**
   - Repository name: `transformer-dbt`
   - Description: `dbt transformation project for Shoppy data warehouse`
   - Visibility: Choose Public or Private based on your needs
   - **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. **Click "Create repository"**
6. **Follow the "push an existing repository" instructions:**

```bash
git remote add origin https://github.com/your-org/transformer-dbt.git
git branch -M main
git push -u origin main
```

### 5. Configure Repository Settings

#### Branch Protection (Recommended)

Protect your main branch to enforce pull requests:

1. Go to **Settings** > **Branches** in your GitHub repository
2. Click **Add rule**
3. Configure protection for `main` branch:
   - ✅ Require pull request reviews before merging
   - ✅ Require status checks to pass before merging
   - ✅ Require branches to be up to date before merging
   - ✅ Include administrators

#### Repository Topics

Add relevant topics to help discoverability:
- `dbt`
- `data-engineering`
- `bigquery`
- `data-warehouse`
- `etl`
- `analytics`

Go to **Settings** > **General** and add these topics in the "Topics" section.

### 6. Set Up Collaboration

#### Add Team Members

1. Go to **Settings** > **Manage access**
2. Click **Invite a collaborator**
3. Add your data engineering team members with appropriate permissions:
   - **Admin**: Full access (for project leads)
   - **Write**: Can push to repository (for core contributors)
   - **Read**: Can view and clone (for stakeholders)

#### Create Issue Templates

Create `.github/ISSUE_TEMPLATE/` directory with templates:

```bash
mkdir -p .github/ISSUE_TEMPLATE
```

**Bug Report Template** (`.github/ISSUE_TEMPLATE/bug_report.md`):
```markdown
---
name: Bug Report
about: Create a report to help us improve
title: '[BUG] '
labels: bug
assignees: ''
---

## Describe the Bug
A clear description of what the bug is.

## dbt Model
Which dbt model is affected?

## Expected Behavior
What you expected to happen.

## Actual Behavior
What actually happened.

## Error Message
```
Paste error message here
```

## Steps to Reproduce
1. Run command...
2. See error...

## Environment
- dbt version:
- BigQuery dataset:
- Environment (dev/prod):
```

**Feature Request Template** (`.github/ISSUE_TEMPLATE/feature_request.md`):
```markdown
---
name: Feature Request
about: Suggest a new feature or model
title: '[FEATURE] '
labels: enhancement
assignees: ''
---

## Feature Description
Clear description of the new feature or model needed.

## Business Justification
Why is this feature needed? What business problem does it solve?

## Proposed Implementation
How should this be implemented?

## Success Criteria
How will we know this feature is complete and working correctly?

## Additional Context
Any other context, mockups, or examples.
```

#### Set Up Pull Request Template

Create `.github/PULL_REQUEST_TEMPLATE.md`:
```markdown
## Description
Brief description of changes made.

## Type of Change
- [ ] New dbt model
- [ ] Bug fix
- [ ] Performance improvement
- [ ] Documentation update
- [ ] Configuration change

## Models Changed
List the models that were added, modified, or removed:
- `model_name`: Description of changes

## Testing Checklist
- [ ] `dbt run` passes locally
- [ ] `dbt test` passes locally
- [ ] New models have appropriate tests
- [ ] Documentation updated
- [ ] Schema changes documented

## Review Checklist
- [ ] Code follows style guidelines
- [ ] Performance impact considered
- [ ] Breaking changes documented
- [ ] Backward compatibility maintained

## Additional Notes
Any additional information for reviewers.
```

### 7. Configure Automated Workflows (Optional)

Create GitHub Actions for automated testing:

`.github/workflows/dbt-ci.yml`:
```yaml
name: dbt CI

on:
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Python
      uses: actions/setup-python@v4
      with:
        python-version: '3.9'
        
    - name: Install dependencies
      run: |
        pip install -r requirements.txt
        
    - name: Run dbt deps
      run: dbt deps
      
    - name: Run dbt compile
      run: dbt compile
      
    - name: Run dbt test
      run: dbt test
```

### 8. Final Steps

#### Commit Additional Configuration

```bash
git add .github/
git commit -m "Add GitHub configuration templates and workflows

- Add issue templates for bugs and features
- Add pull request template
- Add GitHub Actions for automated testing"

git push origin main
```

#### Update README with Repository URL

Update the clone command in your README.md:

```bash
git clone https://github.com/your-org/transformer-dbt.git
```

## 🎉 Repository Ready for Collaboration!

Your dbt transformer project is now ready for collaboration. Team members can:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-org/transformer-dbt.git
   ```

2. **Follow setup instructions** in README.md

3. **Create feature branches** and submit pull requests

4. **Use issue templates** to report bugs or request features

## 📞 Next Steps

1. **Share the repository URL** with your data engineering team
2. **Conduct a walkthrough** of the project structure and setup process
3. **Schedule regular code reviews** and collaboration sessions
4. **Set up monitoring** for the automated scheduler
5. **Plan your first collaborative sprint** with clear deliverables

## 🔧 Maintenance

Regular maintenance tasks:
- Review and merge pull requests
- Update documentation as the project evolves
- Monitor GitHub Actions and fix any CI issues
- Update dependencies and dbt version as needed
- Archive old branches and clean up repository

---

**Congratulations!** Your transformer-dbt project is now a collaborative GitHub repository ready for your data engineering team! 🚀