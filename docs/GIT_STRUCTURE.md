# Git Repository Structure

## 📁 Tracked Files (What Gets Pushed)

### Core Configuration
```
.github/workflows/test.yml    # CI/CD workflow
.gitignore                    # Git ignore rules
.gitmodules                   # Submodule configuration
foundry.toml                  # Foundry configuration
```

### Documentation
```
README.md                     # Project overview
PROJECT_PLAN.md              # Development roadmap
PROGRESS.md                  # Development progress tracker
docs/
  ├── ARCHITECTURE.md        # System architecture
  ├── ERC6551.md            # Token-bound accounts guide
  └── GIT_STRUCTURE.md      # This file
```

### Smart Contracts
```
src/
  ├── MemeToken.sol                    # ERC-20 memecoin
  ├── MemeSoulNFT.sol                 # ERC-721 Soul NFT
  ├── ERC6551Registry.sol             # TBA registry
  ├── TokenBoundAccount.sol           # TBA implementation
  └── interfaces/
      ├── IERC6551Account.sol         # TBA interface
      └── IERC6551Registry.sol        # Registry interface
```

### Tests
```
test/
  ├── MemeToken.t.sol         # Memecoin tests (18 tests)
  ├── MemeSoulNFT.t.sol       # Soul NFT tests (16 tests)
  └── ERC6551.t.sol           # ERC-6551 tests (16 tests)
```

### Dependencies (Submodules)
```
lib/
  ├── forge-std/              # Foundry standard library
  └── openzeppelin-contracts/ # OpenZeppelin contracts
```

---

## 🚫 Ignored Files (Not Pushed)

### Compiler Output
```
cache/                        # Foundry cache
out/                          # Compiled contracts
```

### Environment & Secrets
```
.env                          # Environment variables
.env.local                    # Local environment
.env.*.local                  # Environment overrides
```

### IDE & Editor Files
```
.vscode/                      # VS Code settings
.idea/                        # IntelliJ IDEA settings
*.swp, *.swo                  # Vim swap files
*~                            # Backup files
.DS_Store                     # macOS metadata
```

### Node/Frontend (Future)
```
node_modules/                 # NPM dependencies
.next/                        # Next.js build
dist/                         # Distribution files
build/                        # Build output
```

### Logs & Reports
```
*.log                         # All log files
npm-debug.log*                # NPM debug logs
yarn-debug.log*               # Yarn debug logs
coverage/                     # Test coverage
coverage.json                 # Coverage data
*.lcov                        # Coverage reports
```

### Temporary Files
```
*.tmp                         # Temporary files
*.temp                        # Temp files
```

### Broadcast Logs
```
broadcast/*/31337/            # Local Anvil deployments
broadcast/**/dry-run/         # Dry run deployments
```

---

## 📊 Repository Statistics

| Category | Count |
|----------|-------|
| **Smart Contracts** | 6 |
| **Interfaces** | 2 |
| **Test Files** | 3 |
| **Documentation** | 5 |
| **Total Tests** | 50 |
| **Lines of Code** | ~3,640 |

---

## 🔍 Checking Your Repository

### View all tracked files:
```bash
git ls-files
```

### Check repository status:
```bash
git status
```

### See what's ignored:
```bash
git status --ignored
```

### View commit history:
```bash
git log --oneline
```

---

## ✅ Best Practices

### What SHOULD be tracked:
- ✅ Source code (`.sol` files)
- ✅ Tests (`.t.sol` files)
- ✅ Documentation (`.md` files)
- ✅ Configuration files (`foundry.toml`, `.gitignore`)
- ✅ CI/CD workflows (`.github/workflows/`)

### What SHOULD NOT be tracked:
- ❌ Compiled artifacts (`out/`, `cache/`)
- ❌ Environment variables (`.env`)
- ❌ IDE-specific files (`.vscode/`, `.idea/`)
- ❌ Logs and temporary files
- ❌ Node modules (when frontend is added)
- ❌ Local deployment artifacts

---

## 🔄 Submodules

The repository uses Git submodules for dependencies:

```bash
# Initialize submodules (after cloning)
git submodule update --init --recursive

# Update submodules
git submodule update --remote
```

### Current Submodules:
1. **forge-std** - Foundry testing library
2. **openzeppelin-contracts** - OpenZeppelin v5.4.0

---

## 🚀 For New Contributors

### Clone the repository:
```bash
git clone <repo-url>
cd MemeForge
git submodule update --init --recursive
forge build
forge test
```

### Before committing:
```bash
# Check what will be committed
git status

# Review changes
git diff

# Add files
git add <files>

# Commit with conventional commit message
git commit -m "feat: add new feature"
```

---

## 📝 Commit Message Convention

We use [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions/changes
- `chore:` - Maintenance tasks
- `refactor:` - Code refactoring
- `style:` - Code style changes

### Examples:
```
feat: implement ERC-6551 token-bound accounts
fix: resolve tokenId 0 mapping issue
docs: update architecture documentation
test: add comprehensive ERC-6551 tests
chore: update dependencies
```

---

**Last Updated:** October 11, 2025  
**Repository:** MemeForge - AI-Generated Memecoins Platform
