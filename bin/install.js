#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const os = require('os');
const readline = require('readline');

const CLAUDE_DIR = path.join(os.homedir(), '.claude');
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
  console.log('\n🥋 kakaroto-config - Claude Code Configuration\n');
  console.log('This will install the following to ~/.claude/:');
  console.log('  - CLAUDE.md (global rules)');
  console.log('  - ARCHITECTURE.md (documentation)');
  console.log('  - commands/ (skills: /feature, /debug, /gate)');
  console.log('  - agents/ (7 specialized subagents)\n');

  const fileCount = countFiles(CONFIG_DIR);
  console.log(`Total: ${fileCount} files\n`);

  if (fs.existsSync(CLAUDE_DIR)) {
    const answer = await question('~/.claude/ already exists. Overwrite? (y/N): ');
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

  try {
    copyRecursive(CONFIG_DIR, CLAUDE_DIR);

    console.log('\n✅ Installation complete!\n');
    console.log('Next steps:');
    console.log('  1. Open any project with Claude Code');
    console.log('  2. Try /feature to create a new feature');
    console.log('  3. Try /debug to fix a bug');
    console.log('  4. Try /gate before creating a PR\n');
    console.log('Read ~/.claude/ARCHITECTURE.md for full documentation.\n');
  } catch (err) {
    console.error('Error during installation:', err.message);
    process.exit(1);
  }

  rl.close();
}

main();
