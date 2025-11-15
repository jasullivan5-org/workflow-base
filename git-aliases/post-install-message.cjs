// git-aliases/postinstall-message.cjs
console.log(`
[git run] setup hint
--------------------------------
To enable repo commands, run:

  pnpm git:setup

This configures: git run <cmd>
to execute scripts from ./git-aliases.
`);
