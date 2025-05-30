#!/usr/bin/env node

import inquirer from 'inquirer';
import fs from 'fs-extra';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function toPascalCase(str: string) {
    return str
        .replace(/[-_]+/g, ' ')
        .replace(/\b\w/g, (char) => char.toUpperCase())
        .replace(/\s+/g, '');
}

function capitalize(str: string) {
    return str.charAt(0).toUpperCase() + str.slice(1);
}

function pluralize(str: string) {
    // Basic pluralize; for more accuracy use "pluralize" package
    if (str.endsWith('s')) return str;
    return str + 's';
}

/**
 * Generates content for a in templates
 * @param templateContent The raw content of the template file.
 * @param moduleName The name of the module (e.g., 'User').
 * @returns The rendered routes file content.
 */
function renderTemplate(templateContent: string, moduleName: string, fields?: Record<string, string>): string {
    const Model = toPascalCase(moduleName);
    const model = moduleName.toLowerCase();
    const MODEL = moduleName.toUpperCase();
    const ModelPlural = pluralize(Model);
    const modelPlural = pluralize(model);
    const ModuleServicesPath = `${Model}Services`;
    const models = model + 's';

    let rendered = templateContent
        .replace(/{{MODEL}}/g, MODEL)
        .replace(/{{Model}}/g, Model)
        .replace(/{{model}}/g, model)
        .replace(/{{ModelPlural}}/g, ModelPlural)
        .replace(/{{modelPlural}}/g, modelPlural)
        .replace(/{{ModuleServicesPath}}/g, ModuleServicesPath)
        .replace(/{{models}}/g, models);

    if (fields) {
        let fieldsDeclaration = "";
        for (const field in fields) {
            const prismaType = fields[field];

            const prismaToTsMap: Record<string, string> = {
                Int: 'number',
                String: 'string',
                Boolean: 'boolean',
                DateTime: 'Date',
                Float: 'number',
                Json: 'any', 
            };

            const isOptional = prismaType.includes("?");
            const basePrismaType = prismaType.replace("?", "");

            const tsType = prismaToTsMap[basePrismaType] || basePrismaType;

            fieldsDeclaration += `\t${field}${isOptional ? "?" : ""}: ${tsType};\n`;
        }
        rendered = rendered.replace(/{{fields}}/g, fieldsDeclaration);
    } else {
        rendered = rendered.replace(/{{fields}}/g, "");
    }

    return rendered;
}

/**
 * parses prisma schema into json to be rendered into templates 
 * @param schemaPath path to prisma schema
 */
async function parsePrismaSchema(schemaPath: string): Promise<Record<string, Record<string, string>>> {
    try {
        const schemaContent = await fs.readFile(schemaPath, 'utf-8');
        const models: Record<string, Record<string, string>> = {};
        const modelRegex = /model\s+(\w+)\s+{\s*([\s\S]*?)\s*}/g;
        const fieldRegex = /(\w+)\s+([\w?]+)\s+(@.+)?/g;
        const enumRegex = /enum\s+(\w+)\s+{\s*([\s\S]*?)\s*}/g;
        const relationRegex = /@relation\(/;
        const enums: Record<string, string[]> = {};

        // Parse enums first
        let enumMatch;
        while ((enumMatch = enumRegex.exec(schemaContent)) !== null) {
            const enumName = enumMatch[1];
            const enumValues = enumMatch[2].trim().split(/\s+/).filter(Boolean);
            enums[enumName] = enumValues;
        }

        let modelMatch;
        while ((modelMatch = modelRegex.exec(schemaContent)) !== null) {
            const modelName = modelMatch[1];

            const fieldsText = modelMatch[2].trim();
            const allFields: Record<string, { type: string; attributes: string | undefined }> = {};
            let fieldMatch;
            while ((fieldMatch = fieldRegex.exec(fieldsText)) !== null) {
                const fieldName = fieldMatch[1];
                const fieldType = fieldMatch[2];
                const attributes = fieldMatch[3];
                allFields[fieldName] = { type: fieldType, attributes };
                console.log(`  Found field: ${fieldName} of type ${fieldType} with attributes: ${attributes}`); // <---- LOG
            }

            const filteredFields: Record<string, string> = {};
            for (const fieldName in allFields) {
                if (!allFields[fieldName].attributes?.match(relationRegex)) {
                    filteredFields[fieldName] = allFields[fieldName].type;
                }
            }
            models[modelName] = filteredFields;
        }

        // Replace enum types in the model schema
        for (const modelName in models) {
            for (const fieldName in models[modelName]) {
                let fieldType = models[modelName][fieldName];
                const isOptional = fieldType.endsWith('?');
                const baseType = isOptional ? fieldType.slice(0, -1) : fieldType;
                if (enums[baseType]) {
                    models[modelName][fieldName] = isOptional ? `${baseType}?` : baseType;
                }
            }
        }

        return models;
    } catch (error) {
        console.error("Error parsing Prisma schema:", error);
        return {};
    }
}

/**
 * Generates service, controller, and routes files for a given module.
 * It ensures target directories exist, then iterates through predefined templates
 * based on their categories (services, controllers, routes). For each template, it checks
 * if the corresponding output file already exists. If not, it reads the template,
 * renders it using the module name, and writes the new file to the target directory.
 * @param moduleName The name of the module for which to generate files (e.g., 'user').
 */
async function generateModule(moduleName: string) {
    // Convert module name to PascalCase for directory and class names

    // Define the base directory where templates are located
    const templateDir = path.resolve(__dirname, 'templates');
    console.log(`Template directory: ${templateDir}`);

    // Configuration for different types of templates (e.g., services, controllers, routes)
    const templatesConfig = [
        {
            category: 'services',
            templates: [
                'services/service.delete.ts.tpl',
                'services/service.list.ts.tpl',
                'services/service.show.ts.tpl',
                'services/service.store.ts.tpl',
                'services/service.update.ts.tpl',
            ],
            // Function to determine the target directory for this category
            getTargetDir: (modName: string) => path.resolve(`src/services/${toPascalCase(modName)}Services`),
            getOutputFileName: (modName: string, verb: string) => `${toPascalCase(verb)}${toPascalCase(modName)}Service.ts`,
            // Function to extract a 'verb' or type from the template path
            getVerb: (templatePath: string) => {
                const match = templatePath.match(/service\.([^.]+)\.ts\.tpl$/);
                return match ? match[1] : null;
            },
            // Function to get the appropriate renderer based on the verb
            getRenderer: (verb: string) => renderTemplate
        },
        {
            category: 'controllers',
            templates: [
                'controller.ts.tpl', // Assuming one controller template
            ],
            // Target directory for controllers
            getTargetDir: (modName: string) => path.resolve(`src/controllers`),
            getOutputFileName: (modName: string, verb: string) => `${toPascalCase(modName)}Controller.ts`,
            // For controllers, we can just use 'controller' as the verb/type
            getVerb: (templatePath: string) => {
                const match = templatePath.match(/controller\.ts\.tpl$/);
                return match ? 'controller' : null;
            },
            // Renderer for controllers
            getRenderer: (verb: string) => {
                if (verb === 'controller') return renderTemplate;
                return null;
            }
        },
        {
            category: 'routes',
            templates: [
                'route.ts.tpl', // New routes template
            ],
            // Routes are typically in a common 'src/routes' directory
            getTargetDir: (modName: string) => path.resolve(`src/routes`),
            getOutputFileName: (modName: string, verb: string) => `${modName.toLowerCase()}Routes.ts`,
            // For routes, we can use 'routes' as the verb/type
            getVerb: (templatePath: string) => {
                const match = templatePath.match(/route\.ts\.tpl$/);
                return match ? 'route' : null;
            },
            // Renderer for routes
            getRenderer: (verb: string) => {
                if (verb === 'route') return renderTemplate;
                return null;
            }
        }
    ];

    const prismaSchema = path.resolve(`src/database/schema.prisma`);
    const schemaExists = await fs.pathExists(prismaSchema)
    let modelSchema: Record<string, string> | undefined = undefined;
    if (schemaExists) {
        const jsonSchema = await parsePrismaSchema(prismaSchema);
        const key = toPascalCase(moduleName);
        if (jsonSchema[key]) {
            modelSchema = jsonSchema[key];
        }
    }

    // Loop through each template category configuration
    for (const config of templatesConfig) {
        // Determine the specific target directory for the current module and category
        const currentTargetDir = config.getTargetDir(moduleName);
        // Ensure the target directory exists, creating it if necessary
        await fs.ensureDir(currentTargetDir);
        console.log(`Ensured target directory for ${config.category}: ${currentTargetDir}`);

        // Loop through each template file within the current category
        for (const templatePath of config.templates) {
            console.log(`Processing template: ${templatePath}`);

            // Get the verb/type for the current template
            const verb = config.getVerb(templatePath);
            if (!verb) {
                console.error(`Error: Could not extract verb from template name: ${templatePath}. Skipping.`);
                continue; // Skip if the verb cannot be determined
            }

            const outFile = config.getOutputFileName(moduleName, verb);
            // Extract the base filename (e.g., 'service.show.ts' or 'controller.ts')
            if (!outFile) {
                console.error(`Error: Could not derive output filename for ${templatePath}. Skipping.`);
                continue; // Skip if filename cannot be determined
            }

            // Construct the full path for the output file
            const targetPath = path.join(currentTargetDir, outFile);

            // Check if the target file already exists to prevent overwriting
            const fileExists = await fs.pathExists(targetPath);
            if (fileExists) {
                console.log(`Skipping generation for ${outFile}: file already exists at ${targetPath}.`);
                continue; // Move to the next template if file exists
            }

            // If the file does not exist, proceed to generate it
            console.log(`Generating new file: ${targetPath}`);

            // Read the content of the template file
            const content = await fs.readFile(path.join(templateDir, templatePath), 'utf-8');


            // Get the appropriate rendering function
            const renderer = config.getRenderer(verb);
            let rendered: string | null = null;

            if (renderer) {
                // Call the renderer with the template content and module name
                rendered = renderer(content, moduleName, modelSchema);
            } else {
                console.warn(`Warning: No specific template generation function found for verb: '${verb}'. Falling back to raw content.`);
                rendered = content; // Fallback to raw content if no specific renderer
            }

            // Check if the rendering process resulted in valid content
            if (rendered === null) {
                console.error(`Error: Failed to render template content for ${templatePath}. Skipping.`);
                continue; // Skip if rendering failed
            }

            // Write the rendered content to the target file
            await fs.writeFile(targetPath, rendered);
            console.log(`Successfully generated: ${targetPath}`);
        }
    }
    console.log(`Module generation for '${moduleName}' completed.`);
}


async function initServer() {
    const templateDir = path.resolve(__dirname, 'templates');
    const projectDir = process.cwd(); // Use current working directory

    const init = {
        "config": [
            "/init/config/auth.ts.tpl"
        ],
        "database": [
            "/init/database/index.ts.tpl",
            "/init/database/schema.prisma.tpl",
            "/init/database/seed.ts.tpl",
        ],
        "error": [
            "/init/error/AppError.ts.tpl"
        ],
        "middleware": [
            "/init/middleware/auth.ts.tpl"
        ],
        "@types": [
            "/init/@types/express.d.ts.tpl"
        ],
        "utils": [
            "/init/utils/logger.ts.tpl",
            "/init/utils/refreshtoken.ts.tpl"
        ],
        "": [
            "/init/app.ts.tpl",
            "/init/server.ts.tpl",
        ]
    };

    console.log(`Creating project structure in current directory: ${projectDir}`);

    async function copyTemplate(templatePath: string, targetPath: string, replacements: Record<string, string> = {}) {
        const fullTemplatePath = path.join(templateDir, templatePath);
        try {
            let content = await fs.readFile(fullTemplatePath, 'utf-8');
            for (const key in replacements) {
                content = content.replace(new RegExp(`{{${key}}}`, 'g'), replacements[key]);
            }
            await fs.ensureDir(path.dirname(targetPath));
            await fs.writeFile(targetPath, content, 'utf-8');
            console.log(`Created: ${targetPath.replace(projectDir + '/', '')}`);
        } catch (error) {
            console.error(`Error copying template ${templatePath} to ${targetPath}:`, error);
        }
    }

    // Create 'src' directory and subdirectories in the current directory
    const srcDir = path.join(projectDir, 'src');
    await fs.ensureDir(srcDir);
    await fs.ensureDir(path.join(srcDir, 'config'));
    await fs.ensureDir(path.join(srcDir, 'database'));
    await fs.ensureDir(path.join(srcDir, 'error'));
    await fs.ensureDir(path.join(srcDir, 'middleware'));
    await fs.ensureDir(path.join(srcDir, 'types'));
    await fs.ensureDir(path.join(srcDir, 'utils'));
    // await fs.ensureDir(path.join(srcDir, 'app'));

    // Copy files based on the 'init' configuration to the 'src' directory
    for (const folder in init) {
        const files = init[folder as keyof typeof init];
        const targetSubDir = path.join(srcDir, folder);
        await fs.ensureDir(targetSubDir);
        for (const file of files) {
            const templateFile = path.join('init', folder, file.split('/').pop()!);
            const targetFile = path.join(targetSubDir, file.split('/').pop()!.replace('.tpl', ''));

            const exists = await fs.pathExists(targetFile);
            if (exists) {
                continue
            }

            await copyTemplate(templateFile, targetFile);
        }
    }

    console.log('Static boilerplate generation complete in the current directory.');
}


async function main() {
    let main = true
    while (main) {
        const { command } = await inquirer.prompt([
            {
                name: 'command',
                type: 'list',
                message: 'What do you wanna do ?',
                choices: [
                    "init server",
                    "add module",
                    "exit",
                ]
            },
        ]);

        switch (command) {
            case "add module":
                const { moduleName } = await inquirer.prompt([
                    {
                        name: 'moduleName',
                        type: 'input',
                        message: 'Enter the module name:',
                    },
                ]);
                await generateModule(moduleName);
                break;
            case "init server":
                await initServer();
                break;
            case "exit":
                main = false
                break;
            default:
                break;
        }
    }
}

main().catch((err) => {
    console.error("error: ", err);
});
