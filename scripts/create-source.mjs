import inquirer from 'inquirer';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import chalk from 'chalk';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

function toKebabCase(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function sourceExists(name) {
  try {
    const sourcesDir = path.join(rootDir, 'sources');
    const entries = await fs.readdir(sourcesDir);

    // Check case-insensitive match
    const normalizedName = name.toLowerCase();
    return entries.some((entry) => entry.toLowerCase() === normalizedName);
  } catch {
    // Sources directory might not exist yet
    return false;
  }
}

async function createSource() {
  console.log(chalk.cyan.bold('\n📦 Create New Source\n'));

  const { rawName } = await inquirer.prompt([
    {
      type: 'input',
      name: 'rawName',
      message: chalk.yellow('Source name:'),
      validate: async (value) => {
        if (!value) return 'Source name is required';

        const kebabName = toKebabCase(value);

        if (await sourceExists(kebabName)) {
          return chalk.red(
            `Source "${kebabName}" already exists (case-insensitive check)`,
          );
        }

        return true;
      },
      transformer: (value) => toKebabCase(value),
    },
  ]);

  const sourceName = toKebabCase(rawName);
  const sourceDir = path.join(rootDir, 'sources', sourceName);

  // Create directory structure
  await fs.mkdir(path.join(sourceDir, 'src'), { recursive: true });

  // Create package.json
  const packageJson = {
    name: `@source/${sourceName}`,
    version: '0.0.0',
    private: true,
    main: './src/index.ts',
    types: './src/index.ts',
    scripts: {
      lint: 'eslint .',
      'type-check': 'tsc --noEmit',
    },
    devDependencies: {
      '@repo/eslint-config': 'workspace:*',
      '@repo/typescript-config': 'workspace:*',
    },
  };

  await fs.writeFile(
    path.join(sourceDir, 'package.json'),
    JSON.stringify(packageJson, null, 2),
  );

  // Create tsconfig.json
  const tsConfig = {
    extends: '@repo/typescript-config/base.json',
    include: ['src/**/*.ts'],
    exclude: ['node_modules', 'dist'],
  };

  await fs.writeFile(
    path.join(sourceDir, 'tsconfig.json'),
    JSON.stringify(tsConfig, null, 2),
  );

  // Create eslint.config.mjs
  const eslintConfig = `import { config } from "@repo/eslint-config/base";

/** @type {import("eslint").Linter.Config} */
export default config;
`;

  await fs.writeFile(path.join(sourceDir, 'eslint.config.mjs'), eslintConfig);

  // Create empty src/index.ts
  await fs.writeFile(path.join(sourceDir, 'src', 'index.ts'), '');

  console.log(chalk.green.bold(`\n✅ Source created successfully!\n`));
  console.log(chalk.white('📁 Location:'), chalk.cyan(sourceDir));
  console.log(chalk.white('📦 Source:'), chalk.cyan(`@source/${sourceName}`));
  console.log(chalk.yellow('\n📝 Next steps:'));
  console.log(
    chalk.gray('   1. Run'),
    chalk.white('pnpm install'),
    chalk.gray('to install dependencies'),
  );
  console.log(
    chalk.gray('   2. Start developing in'),
    chalk.white(`sources/${sourceName}`),
  );
}

createSource().catch((error) => {
  if (error.name === 'ExitPromptError') {
    console.log(chalk.yellow('\n👋 Source creation cancelled'));
  } else {
    console.error(chalk.red('\n❌ Error creating source:'), error);
  }
  process.exit(1);
});
