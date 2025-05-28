# Express Prisma Template Generator CLI

This CLI tool helps you quickly scaffold an Express.js server with Prisma integration and generate modules with services, controllers, and routes.

## Installation

1.  **Clone the repository:**

    ```bash
    git clone https://github.com/Anas-mo101/express-prisma-template-generator.git
    cd express-prisma-template-generator
    ```

2.  **Install dependencies:**

    ```bash
    npm install
    ```

3.  **Build the CLI:**

    ```bash
    npm run build
    ```

4.  **Link the CLI globally (for easy use):**

    ```bash
    npm link
    ```

    This will make the `epgen` command (as defined in your `package.json`) available in your terminal.

## Usage

Run the CLI using the linked command:

```bash
$ epgen

? What do you wanna do ? (Use arrow keys)
❯ init server
  add module
```

## Init server

```bash
? What do you wanna do ? (Use arrow keys)
❯ init server
  add module

? What do you wanna do ? init server
Creating project structure in current directory: /path/to/your/current/directory
```

## Add module

```bash
? What do you wanna do ? (Use arrow keys)
  init server
❯ add module

? What do you wanna do ? add module
? Enter the module name: user
Ensured target directory: src/services/UserServices
......
```
