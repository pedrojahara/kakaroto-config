#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');
const { execFileSync } = require('child_process');

// Constants
const HOME_CLAUDE = path.join(os.homedir(), '.claude');
const PROJECT_ROOT = path.join(__dirname, '..');
const CONFIG_DIR = path.join(PROJECT_ROOT, 'config');
const PACKAGE_JSON = path.join(PROJECT_ROOT, 'package.json');

// Exclusions - personal files not to publish
const EXCLUDED_COMMANDS = ['audit-command', 'audit-command.md'];

// Semver validation regex
const SEMVER_REGEX = /^\d+\.\d+\.\d+$/;

// Readline interface
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

function cleanDir(dir) {
  if (fs.existsSync(dir)) {
    fs.rmSync(dir, { recursive: true, force: true });
  }
}

function copyRecursive(src, dest, excludes = []) {
  const stats = fs.statSync(src);

  if (stats.isDirectory()) {
    const baseName = path.basename(src);
    if (excludes.includes(baseName)) {
      return; // Skip excluded directories
    }

    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    const files = fs.readdirSync(src);
    for (const file of files) {
      if (excludes.includes(file)) {
        continue; // Skip excluded files
      }
      copyRecursive(path.join(src, file), path.join(dest, file), excludes);
    }
  } else {
    const baseName = path.basename(src);
    if (excludes.includes(baseName)) {
      return; // Skip excluded files
    }
    fs.copyFileSync(src, dest);
    console.log(`  + ${path.relative(CONFIG_DIR, dest)}`);
  }
}

function bumpVersion(version) {
  if (!SEMVER_REGEX.test(version)) {
    throw new Error(`Invalid semver format: ${version}. Expected X.Y.Z`);
  }
  const parts = version.split('.');
  parts[2] = String(parseInt(parts[2], 10) + 1);
  return parts.join('.');
}

function execCommandSafe(executable, args, description) {
  console.log(`\n${description}...`);
  try {
    execFileSync(executable, args, { cwd: PROJECT_ROOT, stdio: 'inherit' });
    return true;
  } catch (err) {
    console.error(`Error: ${err.message}`);
    return false;
  }
}

function countFiles(dir, excludes = []) {
  let count = 0;
  if (!fs.existsSync(dir)) return 0;

  const items = fs.readdirSync(dir);
  for (const item of items) {
    if (excludes.includes(item)) continue;

    const fullPath = path.join(dir, item);
    if (fs.statSync(fullPath).isDirectory()) {
      count += countFiles(fullPath, excludes);
    } else {
      count++;
    }
  }
  return count;
}

async function main() {
  console.log('\n🥋 kakaroto-config - Release\n');

  // Check ~/.claude exists
  if (!fs.existsSync(HOME_CLAUDE)) {
    console.error(`Error: ${HOME_CLAUDE} does not exist`);
    rl.close();
    process.exit(1);
  }

  // Read current version
  let pkg;
  try {
    pkg = JSON.parse(fs.readFileSync(PACKAGE_JSON, 'utf8'));
  } catch (err) {
    console.error(`Error reading package.json: ${err.message}`);
    rl.close();
    process.exit(1);
  }

  const currentVersion = pkg.version;
  let newVersion;
  try {
    newVersion = bumpVersion(currentVersion);
  } catch (err) {
    console.error(`Error: ${err.message}`);
    rl.close();
    process.exit(1);
  }

  // Count files to sync
  const commandsCount = countFiles(path.join(HOME_CLAUDE, 'commands'), EXCLUDED_COMMANDS);
  const agentsCount = countFiles(path.join(HOME_CLAUDE, 'agents'));
  const templatesCount = countFiles(path.join(HOME_CLAUDE, 'templates'));
  const totalFiles = commandsCount + agentsCount + templatesCount + 2; // +2 for CLAUDE.md and ARCHITECTURE.md

  // Show preview
  console.log('This will:');
  console.log(`  1. Sync ${totalFiles} files from ~/.claude/ to config/`);
  console.log(`     - CLAUDE.md`);
  console.log(`     - ARCHITECTURE.md`);
  console.log(`     - commands/ (${commandsCount} files, excluding audit-command)`);
  console.log(`     - agents/ (${agentsCount} files)`);
  console.log(`     - templates/ (${templatesCount} files)`);
  console.log(`  2. Bump version: ${currentVersion} → ${newVersion}`);
  console.log(`  3. Git commit and push`);
  console.log(`  4. Publish to npm\n`);

  // Confirm
  const answer = await question('Proceed with release? (Y/n): ');
  if (answer.toLowerCase() === 'n') {
    console.log('\nAborted. No changes made.');
    rl.close();
    process.exit(0);
  }

  console.log('\n--- Syncing files ---\n');

  // Clean directories
  cleanDir(path.join(CONFIG_DIR, 'commands'));
  cleanDir(path.join(CONFIG_DIR, 'agents'));
  cleanDir(path.join(CONFIG_DIR, 'templates'));

  // Ensure config directory exists
  if (!fs.existsSync(CONFIG_DIR)) {
    fs.mkdirSync(CONFIG_DIR, { recursive: true });
  }

  // Copy files with existence check
  const claudeMdPath = path.join(HOME_CLAUDE, 'CLAUDE.md');
  if (fs.existsSync(claudeMdPath)) {
    console.log('Copying CLAUDE.md...');
    fs.copyFileSync(claudeMdPath, path.join(CONFIG_DIR, 'CLAUDE.md'));
    console.log('  + CLAUDE.md');
  } else {
    console.warn('Warning: CLAUDE.md not found, skipping');
  }

  const archMdPath = path.join(HOME_CLAUDE, 'ARCHITECTURE.md');
  if (fs.existsSync(archMdPath)) {
    console.log('Copying ARCHITECTURE.md...');
    fs.copyFileSync(archMdPath, path.join(CONFIG_DIR, 'ARCHITECTURE.md'));
    console.log('  + ARCHITECTURE.md');
  } else {
    console.warn('Warning: ARCHITECTURE.md not found, skipping');
  }

  console.log('Copying commands/...');
  copyRecursive(
    path.join(HOME_CLAUDE, 'commands'),
    path.join(CONFIG_DIR, 'commands'),
    EXCLUDED_COMMANDS
  );

  console.log('Copying agents/...');
  copyRecursive(
    path.join(HOME_CLAUDE, 'agents'),
    path.join(CONFIG_DIR, 'agents')
  );

  if (fs.existsSync(path.join(HOME_CLAUDE, 'templates'))) {
    console.log('Copying templates/...');
    copyRecursive(
      path.join(HOME_CLAUDE, 'templates'),
      path.join(CONFIG_DIR, 'templates')
    );
  }

  // Update package.json
  console.log('\n--- Updating version ---\n');
  pkg.version = newVersion;
  fs.writeFileSync(PACKAGE_JSON, JSON.stringify(pkg, null, 2) + '\n');
  console.log(`Updated package.json: ${currentVersion} → ${newVersion}`);

  // Git operations - use execCommandSafe for commands with user-derived values
  if (!execCommandSafe('git', ['add', '.'], 'Staging changes')) {
    rl.close();
    process.exit(1);
  }

  // Use execCommandSafe to prevent command injection via newVersion
  if (!execCommandSafe('git', ['commit', '-m', `release: v${newVersion}`], 'Creating commit')) {
    rl.close();
    process.exit(1);
  }

  if (!execCommandSafe('git', ['push'], 'Pushing to remote')) {
    rl.close();
    process.exit(1);
  }

  // npm publish
  if (!execCommandSafe('npm', ['publish'], 'Publishing to npm')) {
    rl.close();
    process.exit(1);
  }

  console.log(`\n✅ Release complete! Published v${newVersion}\n`);
  console.log('Users can update with:');
  console.log(`  npx kakaroto-config@${newVersion}\n`);

  rl.close();
}

main().catch((err) => {
  console.error(`Unexpected error: ${err.message}`);
  rl.close();
  process.exit(1);
});
