# Template

This project was generated with
[Angular CLI](https://github.com/angular/angular-cli) version 18.0.1.

## Nix development shell

Run `nix develop`, then `npm ci` from the project root. The shell's `ng` and
`tsc` commands use the installed project binaries without implicit downloads.
The current dependencies require attention before installation: Angular 22.0.6
requires TypeScript `>=6.0 <6.1`, while this template pins TypeScript 7.0.2.
The dependency declarations are unchanged.

For a compatible installed project, configure an LSP-capable editor to run
`typescript-lsp --stdio` from the project root. This invokes TypeScript 7's
native language server, not the removed `tsserver` protocol. It is not a
replacement for the Angular template language service or a drop-in command for
editors configured to use `typescript-language-server`.

`eslint_d` and `prettierd` remain available. Add your project's ESLint
configuration before starting `eslint_d`; the shell does not start it
automatically.

## Development server

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The
application will automatically reload if you change any of the source files.

## Code scaffolding

Run `ng generate component component-name` to generate a new component. You can
also use `ng generate directive|pipe|service|class|guard|interface|enum|module`.

## Build

Run `ng build` to build the project. The build artifacts will be stored in the
`dist/` directory.

## Running unit tests

Run `ng test` to execute the unit tests via
[Karma](https://karma-runner.github.io).

## Running end-to-end tests

Run `ng e2e` to execute the end-to-end tests via a platform of your choice. To
use this command, you need to first add a package that implements end-to-end
testing capabilities.

## Further help

To get more help on the Angular CLI use `ng help` or go check out the
[Angular CLI Overview and Command Reference](https://angular.dev/tools/cli)
page.
