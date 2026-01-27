# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the PushFire SDK.

## Workflows

### CI (`ci.yml`)
Runs on every push and pull request to `main` and `develop` branches:
- **Analyze**: Runs `flutter analyze` and checks code formatting
- **Test**: Runs `flutter test` to execute all tests
- **Dry Run**: Performs a dry-run publish to verify the package is ready

### Release (`release.yml`)
Runs automatically when a git tag matching `v[0-9]+.[0-9]+.[0-9]+*` is pushed (e.g., `v0.1.4`):

**Job 1: build-and-release**
- Extracts version from tag (removes `v` prefix)
- Updates `pubspec.yaml` with the version from tag
- Updates `CHANGELOG.md` if version entry doesn't exist
- Commits version updates back to the repository
- Runs Flutter analysis and tests
- Performs dry-run publish verification
- Creates a GitHub Release with release notes

**Job 2: publish**
- Publishes the package to pub.dev using OIDC authentication
- Uses the official `dart-lang/setup-dart` workflow

## Setup for pub.dev Publishing

To enable automatic publishing to pub.dev, you need to:

1. **Enable OIDC in pub.dev**:
   - Go to [pub.dev](https://pub.dev)
   - Sign in with your Google account
   - Navigate to your account settings
   - Enable OIDC authentication for GitHub Actions

2. **Link your GitHub repository**:
   - In pub.dev, go to your package settings
   - Add your GitHub repository URL
   - Authorize pub.dev to access your repository

3. **Verify workflow permissions**:
   - The workflow requires `id-token: write` permission for OIDC
   - This is already configured in the workflow

## Usage

To release a new version:

1. Update `CHANGELOG.md` with your changes
2. Update `pubspec.yaml` version (optional - will be updated from tag)
3. Create and push a git tag:
   ```bash
   git tag v0.1.4
   git push origin v0.1.4
   ```

The workflow will automatically:
- Extract the version from the tag
- Update version files
- Run tests and analysis
- Create a GitHub release
- Publish to pub.dev

## Tag Format

Tags must follow semantic versioning format:
- `v0.1.4` ✅
- `v1.0.0` ✅
- `v2.0.0-beta.1` ✅
- `0.1.4` ❌ (missing `v` prefix)
