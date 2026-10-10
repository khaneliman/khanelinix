# Angular scaffold provenance

The Angular source scaffold and favicon were introduced by khanelinix commit
`cfc5d76d4f07f84b5cee87992f8259c05bbf0310` (May 26, 2024), whose README names
Angular CLI 18.0.1.

The primary source is the published `@schematics/angular@18.0.1` package,
[also available in the Angular CLI 18.0.1 tag](https://github.com/angular/angular-cli/tree/9e9ca22874e09ff093979dc75f3895a5f5c2ae1f/packages/schematics/angular).
The adjacent LICENSE is copied unchanged from that package and is byte-identical
to [the tagged repository license](https://github.com/angular/angular-cli/blob/9e9ca22874e09ff093979dc75f3895a5f5c2ae1f/LICENSE).
It preserves the upstream Google, Inc. copyright and permission notice; it is
not a new license declaration for locally authored Nix configuration.

The `src/` files correspond to `application/files/common-files/` and
`application/files/standalone-files/`. At first import, they match the rendered
upstream templates exactly with project name `template`, selector `app-root`,
routing enabled, external HTML and SCSS styles. `app.component.scss` is empty.
The original scaffold remains locally modified and formatted; no source file
has been replaced with a fresh scaffold.

`public/favicon.ico` remains byte-identical to
`application/files/common-files/public/favicon.ico.template`, SHA256
`f9102be80297c0529207607be5277b4f90bca89d65988fa1771b91c7894e815f`.
README, editor configuration, Git ignore rules, VS Code configuration and
TypeScript configuration also derive from `workspace/files/` and
`application/files/common-files/`, with local changes retained.

This attribution does not claim that dependency lockfiles, every dependency,
embedded external artwork or locally authored files have been independently
licensed or traced to an exact original source.
