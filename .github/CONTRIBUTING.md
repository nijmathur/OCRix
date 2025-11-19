# Contributing to OCRix

## Branch Protection Rules

The `main` branch is protected with the following rules:

### Required Pull Requests
- ✅ **All changes to `main` must go through a Pull Request**
- ✅ **At least 1 approval required** before merging
- ✅ **Stale reviews are automatically dismissed** when new commits are pushed

### Restrictions
- ❌ **No direct pushes to `main`** - All changes must be via PR
- ❌ **No force pushes** to `main`
- ❌ **No branch deletion** of `main`

## Development Workflow

1. **Create a feature branch** from `main`:
   ```bash
   git checkout main
   git pull origin main
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and commit:
   ```bash
   git add .
   git commit -m "feat: Your feature description"
   ```

3. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Create a Pull Request** on GitHub:
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your feature branch to merge into `main`
   - Add a description of your changes
   - Request review if needed

5. **Wait for approval** (at least 1 reviewer required)

6. **Merge the PR** once approved

## Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting, etc.)
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `test:` - Adding or updating tests
- `chore:` - Maintenance tasks

Example:
```
feat: Add thumbnail generation for document images
fix: Resolve memory leak in image processing
docs: Update API documentation
```

## Code Review Process

- All PRs require at least 1 approval
- Reviewers should check:
  - Code quality and style
  - Test coverage
  - Documentation updates
  - Performance implications
  - Security considerations

## Questions?

If you have questions about the contribution process, please open an issue on GitHub.

