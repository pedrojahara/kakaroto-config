#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');

const args = process.argv.slice(2);
const isGlobal = args.includes('--global');
const showHelp = args.includes('--help') || args.includes('-h');

if (showHelp) {
  console.log(`
Usage: npx kakaroto-config [options]

Options:
  --global    Install to ~/.claude/ (global, all projects)
  --help, -h  Show this help message

Default: Install to ./.claude/ (local, current project)
`);
  process.exit(0);
}

const CLAUDE_DIR = isGlobal
  ? path.join(os.homedir(), '.claude')
  : path.join(process.cwd(), '.claude');
const CONFIG_DIR = path.join(__dirname, '..', 'config');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

function question(prompt) {
  return new Promise((resolve) => {
    rl.question(prompt, resolve);
  });
}

function copyRecursive(src, dest) {
  const stats = fs.statSync(src);

  if (stats.isDirectory()) {
    if (!fs.existsSync(dest)) {
      fs.mkdirSync(dest, { recursive: true });
    }

    const files = fs.readdirSync(src);
    for (const file of files) {
      copyRecursive(path.join(src, file), path.join(dest, file));
    }
  } else {
    fs.copyFileSync(src, dest);
    console.log(`  + ${path.relative(CLAUDE_DIR, dest)}`);
  }
}

function countFiles(dir) {
  let count = 0;
  const items = fs.readdirSync(dir);
  for (const item of items) {
    const fullPath = path.join(dir, item);
    if (fs.statSync(fullPath).isDirectory()) {
      count += countFiles(fullPath);
    } else {
      count++;
    }
  }
  return count;
}

async function main() {
  const targetPath = isGlobal ? '~/.claude/' : './.claude/ (local)';
  const targetDisplay = isGlobal ? '~/.claude/' : '.claude/';

  console.log('\n🥋 kakaroto-config - Claude Code Configuration\n');
  console.log(`This will install the following to ${targetPath}:`);
  console.log('  - CLAUDE.md (rules)');
  console.log('  - ARCHITECTURE.md (documentation)');
  console.log('  - skills/ (workflows: /build, /resolve, /deliberate)');
  console.log('  - commands/ (commands: /gate)');
  console.log('  - agents/ (8 specialized subagents)');
  console.log('  - hooks/ (agent stop hooks)\n');

  const fileCount = countFiles(CONFIG_DIR);
  console.log(`Total: ${fileCount} files\n`);

  if (fs.existsSync(CLAUDE_DIR)) {
    const answer = await question(`${targetDisplay} already exists. Overwrite? (y/N): `);
    if (answer.toLowerCase() !== 'y') {
      console.log('\nAborted. No changes made.');
      rl.close();
      process.exit(0);
    }
    console.log('\nOverwriting existing config...\n');
  } else {
    const answer = await question('Proceed with installation? (Y/n): ');
    if (answer.toLowerCase() === 'n') {
      console.log('\nAborted. No changes made.');
      rl.close();
      process.exit(0);
    }
    console.log('\nInstalling config...\n');
  }

  // Clean up deprecated paths from previous versions
  const DEPRECATED_DIRS = [
    'skills/build-plan',
    'skills/build-plan-spec',
    'skills/build-plan-implement',
    'skills/think',
  ];
  const DEPRECATED_FILES = [
    'agents/build-plan-implementer.md',
  ];

  for (const p of DEPRECATED_DIRS) {
    const full = path.join(CLAUDE_DIR, p);
    if (fs.existsSync(full)) {
      fs.rmSync(full, { recursive: true });
      console.log(`  - removed deprecated: ${p}/`);
    }
  }
  for (const f of DEPRECATED_FILES) {
    const full = path.join(CLAUDE_DIR, f);
    if (fs.existsSync(full)) {
      fs.unlinkSync(full);
      console.log(`  - removed deprecated: ${f}`);
    }
  }

  try {
    copyRecursive(CONFIG_DIR, CLAUDE_DIR);

    // Merge settings.json hooks (settings-template.json → settings.json)
    const settingsTemplatePath = path.join(CLAUDE_DIR, 'settings-template.json');
    const settingsPath = path.join(CLAUDE_DIR, 'settings.json');

    if (fs.existsSync(settingsTemplatePath)) {
      const template = JSON.parse(fs.readFileSync(settingsTemplatePath, 'utf8'));
      let settings = {};

      if (fs.existsSync(settingsPath)) {
        try {
          settings = JSON.parse(fs.readFileSync(settingsPath, 'utf8'));
        } catch (e) {
          console.warn('  Warning: existing settings.json is invalid JSON, creating new one');
          settings = {};
        }
      }

      // Remove existing hooks that reference our hook scripts
      if (settings.hooks) {
        for (const event of Object.keys(settings.hooks)) {
          if (Array.isArray(settings.hooks[event])) {
            settings.hooks[event] = settings.hooks[event].filter(entry => {
              const hookStr = JSON.stringify(entry);
              return !hookStr.includes('.claude/hooks/');
            });
            if (settings.hooks[event].length === 0) {
              delete settings.hooks[event];
            }
          }
        }
        if (Object.keys(settings.hooks).length === 0) {
          delete settings.hooks;
        }
      }

      // Merge template hooks
      if (!settings.hooks) {
        settings.hooks = {};
      }
      for (const [event, entries] of Object.entries(template.hooks)) {
        if (!settings.hooks[event]) {
          settings.hooks[event] = [];
        }
        settings.hooks[event].push(...entries);
      }

      fs.writeFileSync(settingsPath, JSON.stringify(settings, null, 2) + '\n');
      console.log('  + settings.json (hooks merged)');

      // Remove template file from target
      fs.unlinkSync(settingsTemplatePath);
    }

    console.log('\n✅ Installation complete!\n');
    console.log('Next steps:');
    console.log('  1. Open any project with Claude Code');
    console.log('  2. Try /build to create a new feature');
    console.log('  3. Try /resolve to fix a bug');
    console.log('  4. Try /gate before creating a PR\n');
    console.log(`Read ${targetDisplay}ARCHITECTURE.md for full documentation.\n`);
  } catch (err) {
    console.error('Error during installation:', err.message);
    process.exit(1);
  }

  rl.close();
}

main();
