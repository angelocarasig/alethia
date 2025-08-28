import inquirer from 'inquirer';
import fs from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import chalk from 'chalk';
import { execSync } from 'child_process';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const rootDir = path.resolve(__dirname, '..');

function toKebabCase(str) {
  return str
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}

async function packageExists(name) {
  try {
    await fs.access(path.join(rootDir, 'packages', name));
    return true;
  } catch {
    return false;
  }
}

async function createPackage() {
  console.log(chalk.cyan.bold('\n📦 Create New Package\n'));

  const { rawName } = await inquirer.prompt([
    {
      type: 'input',
      name: 'rawName',
      message: chalk.yellow('Package name:'),
      validate: async (value) => {
        if (!value) return 'Package name is required';
        const kebabName = toKebabCase(value);
        if (await packageExists(kebabName)) {
          return chalk.red(`Package "${kebabName}" already exists`);
        }
        return true;
      },
      transformer: (value) => toKebabCase(value),
    },
  ]);

  const packageName = toKebabCase(rawName);

  const { packageType } = await inquirer.prompt([
    {
      type: 'list',
      name: 'packageType',
      message: chalk.yellow('Select package type:'),
      choices: [
        {
          name: chalk.green('Base') + chalk.gray(' - Standard TypeScript package'),
          value: 'base',
        },
        {
          name: chalk.blue('Next.js') + chalk.gray(' - Next.js application or library'),
          value: 'nextjs',
        },
        {
          name: chalk.magenta('React Internal') + chalk.gray(' - Internal React library'),
          value: 'react-internal',
        },
      ],
    },
  ]);

  const packageDir = path.join(rootDir, 'packages', packageName);

  if (packageType === 'nextjs') {
    console.log(chalk.cyan('\n🚀 Creating Next.js app...\n'));
    
    try {
      execSync(
        `npx create-next-app@latest ${packageDir} --typescript --tailwind --eslint --app --src-dir=false --import-alias="@/*" --no-install`,
        { 
          stdio: 'inherit',
          cwd: rootDir 
        }
      );
    } catch (error) {
      console.error(chalk.red('Failed to create Next.js app'));
      throw error;
    }

    const packageJsonPath = path.join(packageDir, 'package.json');
    const packageJsonContent = await fs.readFile(packageJsonPath, 'utf-8');
    const packageJson = JSON.parse(packageJsonContent);
    
    packageJson.name = `@repo/${packageName}`;
    packageJson.private = true;
    packageJson.version = '0.0.0';
    
    if (!packageJson.devDependencies) {
      packageJson.devDependencies = {};
    }
    packageJson.devDependencies['@repo/eslint-config'] = 'workspace:*';
    packageJson.devDependencies['@repo/typescript-config'] = 'workspace:*';
    
    await fs.writeFile(
      packageJsonPath,
      JSON.stringify(packageJson, null, 2)
    );

    const tsConfig = {
      extends: '@repo/typescript-config/nextjs.json',
      compilerOptions: {
        plugins: [
          {
            name: 'next',
          },
        ],
      },
      include: [
        '**/*.ts',
        '**/*.tsx',
        'next-env.d.ts',
        'next.config.js',
        '.next/types/**/*.ts',
      ],
      exclude: ['node_modules'],
    };

    await fs.writeFile(
      path.join(packageDir, 'tsconfig.json'),
      JSON.stringify(tsConfig, null, 2)
    );

    const eslintConfig = `import { nextJsConfig } from "@repo/eslint-config/next-js";

/** @type {import("eslint").Linter.Config} */
export default nextJsConfig;
`;
    await fs.writeFile(path.join(packageDir, 'eslint.config.mjs'), eslintConfig);
    
    try {
      await fs.unlink(path.join(packageDir, '.eslintrc.json'));
    } catch {}

  } else {
    await fs.mkdir(path.join(packageDir, 'src'), { recursive: true });

    const packageJson = {
      name: `@repo/${packageName}`,
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
        '@repo/typescript-config': 'workspace:*'
      },
    };

    await fs.writeFile(
      path.join(packageDir, 'package.json'),
      JSON.stringify(packageJson, null, 2)
    );

    let tsConfig;
    if (packageType === 'react-internal') {
      tsConfig = {
        extends: '@repo/typescript-config/react-library.json',
        include: ['src/**/*.ts', 'src/**/*.tsx'],
        exclude: ['node_modules', 'dist'],
      };
    } else {
      tsConfig = {
        extends: '@repo/typescript-config/base.json',
        include: ['src/**/*.ts'],
        exclude: ['node_modules', 'dist'],
      };
    }

    await fs.writeFile(
      path.join(packageDir, 'tsconfig.json'),
      JSON.stringify(tsConfig, null, 2)
    );

    let eslintConfig;
    if (packageType === 'react-internal') {
      eslintConfig = `import { config } from "@repo/eslint-config/react-internal";

/** @type {import("eslint").Linter.Config} */
export default config;
`;
    } else {
      eslintConfig = `import { config } from "@repo/eslint-config/base";

/** @type {import("eslint").Linter.Config} */
export default config;
`;
    }

    await fs.writeFile(path.join(packageDir, 'eslint.config.mjs'), eslintConfig);
    await fs.writeFile(path.join(packageDir, 'src', 'index.ts'), '');
  }

  console.log(chalk.green.bold(`\n✅ Package created successfully!\n`));
  console.log(chalk.white('📁 Location:'), chalk.cyan(packageDir));
  console.log(chalk.white('📦 Package:'), chalk.cyan(`@repo/${packageName}`));
  console.log(chalk.white('🎨 Type:'), chalk.cyan(packageType));
  console.log(chalk.yellow('\n📝 Next steps:'));
  console.log(chalk.gray('   1. Run'), chalk.white('pnpm install'), chalk.gray('to install dependencies'));
  console.log(chalk.gray('   2. Start developing in'), chalk.white(`packages/${packageName}`));
}

createPackage().catch((error) => {
  if (error.name === 'ExitPromptError') {
    console.log(chalk.yellow('\n👋 Package creation cancelled'));
  } else {
    console.error(chalk.red('\n❌ Error creating package:'), error);
  }
  process.exit(1);
});